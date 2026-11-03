import AppKit
import Foundation
import SwiftUI

public enum SortOption: String, CaseIterable, Identifiable {
    case sizeDescending
    case sizeAscending
    case nameAscending
    case nameDescending
    case dateDescending

    public var id: String { rawValue }

    @MainActor
    public func title(using l10n: LocalizationManager) -> String {
        switch self {
        case .sizeDescending: return l10n.sortSizeDesc
        case .sizeAscending: return l10n.sortSizeAsc
        case .nameAscending: return l10n.sortNameAsc
        case .nameDescending: return l10n.sortNameDesc
        case .dateDescending: return l10n.sortDateDesc
        }
    }
}

@MainActor
public final class FolderTreeViewModel: ObservableObject {
    public var l10n = LocalizationManager.shared

    @Published public var currentRootURL: URL?
    @Published public var rootNodes: [FileNode] = []
    @Published public var selectedNode: FileNode?
    @Published public var sortOption: SortOption = .sizeDescending
    @Published public var searchQuery: String = ""
    @Published public var isScanningRoot: Bool = false
    @Published public var activeCalculationCount: Int = 0
    @Published public var statusMessage: String = ""
    @Published public var cachedItemsCount: Int = 0
    @Published public var showCacheSheet: Bool = false
    @Published public var showFiles: Bool = UserDefaults.standard.object(forKey: "FolderViewer.ShowFiles") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(showFiles, forKey: "FolderViewer.ShowFiles")
        }
    }

    // MARK: - Navigation History
    @Published public var backStack: [URL] = []
    @Published public var forwardStack: [URL] = []
    @Published public var recentPaths: [URL] = []

    public var canGoBack: Bool { !backStack.isEmpty }
    public var canGoForward: Bool { !forwardStack.isEmpty }

    private let recentPathsKey = "FolderViewer.RecentPaths"

    private let cacheManager = SizeCacheManager.shared
    private let calculator = FolderSizeCalculator.shared
    private var calculationTasks: [String: Task<Void, Never>] = [:]

    public init() {
        self.statusMessage = LocalizationManager.shared.selectFolder

        if let saved = UserDefaults.standard.stringArray(forKey: recentPathsKey) {
            self.recentPaths = saved.compactMap { path in
                let url = URL(fileURLWithPath: path)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                    return url
                }
                return nil
            }
        }

        Task { @MainActor in
            await refreshCacheStats()
        }
    }

    public func refreshCacheStats() async {
        let count = await cacheManager.count()
        self.cachedItemsCount = count
    }

    public func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Выбрать папку"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            loadFolder(url: selectedURL)
        }
    }

    public func goBack() {
        guard let prev = backStack.popLast() else { return }
        if let current = currentRootURL {
            forwardStack.append(current)
        }
        loadFolder(url: prev, addToHistory: false)
    }

    public func goForward() {
        guard let next = forwardStack.popLast() else { return }
        if let current = currentRootURL {
            backStack.append(current)
        }
        loadFolder(url: next, addToHistory: false)
    }

    private func addToRecentPaths(url: URL) {
        var paths = recentPaths.map { $0.path }
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > 30 {
            paths = Array(paths.prefix(30))
        }
        UserDefaults.standard.set(paths, forKey: recentPathsKey)
        self.recentPaths = paths.map { URL(fileURLWithPath: $0) }
    }

    public func clearHistory() {
        recentPaths.removeAll()
        backStack.removeAll()
        forwardStack.removeAll()
        UserDefaults.standard.removeObject(forKey: recentPathsKey)
    }

    public func removeFromRecent(url: URL) {
        var paths = recentPaths.map { $0.path }
        paths.removeAll { $0 == url.path }
        UserDefaults.standard.set(paths, forKey: recentPathsKey)
        self.recentPaths = paths.map { URL(fileURLWithPath: $0) }
    }

    public func loadFolder(url: URL, addToHistory: Bool = true) {
        if addToHistory, let current = currentRootURL, current != url {
            backStack.append(current)
            forwardStack.removeAll()
        }

        addToRecentPaths(url: url)

        // Cancel ongoing tasks
        for (_, task) in calculationTasks {
            task.cancel()
        }
        calculationTasks.removeAll()

        self.currentRootURL = url
        self.statusMessage = l10n.loadingFolder(url.lastPathComponent)
        self.isScanningRoot = true

        Task { @MainActor in
            let nodes = await fetchContents(of: url)
            self.rootNodes = nodes
            self.isScanningRoot = false
            self.sortNodes()
            self.statusMessage = l10n.loadedObjects(nodes.count)
            await refreshCacheStats()

            // Trigger background calculation for non-cached directories
            for node in nodes where node.isDirectory && !node.isCached {
                calculateFolderSize(node: node, forceRecalculate: false)
            }
        }
    }

    public func fetchContents(of folderURL: URL) async -> [FileNode] {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isPackageKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isSymbolicLinkKey
        ]

        guard let contents = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var nodes: [FileNode] = []

        for itemURL in contents {
            guard let vals = try? itemURL.resourceValues(forKeys: keys) else { continue }
            if vals.isSymbolicLink == true { continue }

            let isDir = vals.isDirectory ?? false
            let isPkg = vals.isPackage ?? false
            let modDate = vals.contentModificationDate

            if isDir {
                // Check cache first
                let cached = await cacheManager.get(for: itemURL.path)
                let node = FileNode(
                    url: itemURL,
                    isDirectory: true,
                    isPackage: isPkg,
                    size: cached?.size,
                    itemCount: cached?.itemCount,
                    modifiedDate: modDate,
                    isCached: cached != nil,
                    cachedAt: cached?.calculatedAt
                )
                nodes.append(node)
            } else {
                let fileSize = Int64(vals.fileSize ?? 0)
                let node = FileNode(
                    url: itemURL,
                    isDirectory: false,
                    isPackage: false,
                    size: fileSize,
                    itemCount: 1,
                    modifiedDate: modDate,
                    isCached: false,
                    cachedAt: nil
                )
                nodes.append(node)
            }
        }

        return nodes
    }

    public func toggleExpand(node: FileNode) {
        guard node.isDirectory else { return }

        if node.isExpanded {
            node.isExpanded = false
            return
        }

        if node.isChildrenLoaded {
            node.isExpanded = true
            return
        }

        Task { @MainActor in
            node.isChildrenLoaded = true
            let children = await fetchContents(of: node.url)
            node.children = children
            node.isExpanded = true
            self.sortChildren(for: node)

            // Trigger background calculation for uncalculated child directories
            for child in children where child.isDirectory && !child.isCached {
                calculateFolderSize(node: child, forceRecalculate: false)
            }
        }
    }

    public func calculateFolderSize(node: FileNode, forceRecalculate: Bool = false) {
        guard node.isDirectory else { return }

        // If forceRecalculate is false and it's already cached, no need to recalculate
        if !forceRecalculate && node.isCached && node.size != nil {
            return
        }

        calculationTasks[node.id]?.cancel()

        node.isCalculating = true
        activeCalculationCount += 1

        let task = Task { @MainActor in
            let result = await calculator.calculateSize(for: node.url)

            guard !Task.isCancelled else {
                node.isCalculating = false
                activeCalculationCount = max(0, activeCalculationCount - 1)
                return
            }

            if let result = result {
                node.size = result.totalSize
                node.itemCount = result.itemCount
                node.isCached = true
                node.cachedAt = Date()

                await cacheManager.set(
                    path: node.url.path,
                    size: result.totalSize,
                    itemCount: result.itemCount,
                    modifiedDate: result.modifiedDate
                )
                await refreshCacheStats()
            }

            node.isCalculating = false
            activeCalculationCount = max(0, activeCalculationCount - 1)
            self.sortNodes()
        }

        calculationTasks[node.id] = task
    }

    public func recalculateSelectedOrCurrent() {
        if let selected = selectedNode, selected.isDirectory {
            calculateFolderSize(node: selected, forceRecalculate: true)
        } else {
            recalculateAllVisibleCached()
        }
    }

    public func recalculateAllVisibleCached() {
        func collectFolders(from nodes: [FileNode]) -> [FileNode] {
            var result: [FileNode] = []
            for node in nodes where node.isDirectory {
                result.append(node)
                if let children = node.children, node.isExpanded {
                    result.append(contentsOf: collectFolders(from: children))
                }
            }
            return result
        }

        let folders = collectFolders(from: rootNodes)
        for folder in folders {
            calculateFolderSize(node: folder, forceRecalculate: true)
        }
    }

    public func recalculateEntireCache() {
        Task { @MainActor in
            let all = await cacheManager.allRecords()
            for (path, _) in all {
                let url = URL(fileURLWithPath: path)
                if let result = await calculator.calculateSize(for: url) {
                    await cacheManager.set(
                        path: path,
                        size: result.totalSize,
                        itemCount: result.itemCount,
                        modifiedDate: result.modifiedDate
                    )
                }
            }
            await refreshCacheStats()
            // Also refresh visible nodes
            if let root = currentRootURL {
                loadFolder(url: root)
            }
        }
    }

    public func clearAllCache() {
        Task { @MainActor in
            await cacheManager.invalidateAll()
            await refreshCacheStats()
            // Mark all currently visible folders as not cached
            self.uncache(nodes: self.rootNodes)
        }
    }

    private func uncache(nodes: [FileNode]) {
        for node in nodes {
            if node.isDirectory {
                node.isCached = false
                node.cachedAt = nil
                node.size = nil
            }
            if let children = node.children {
                uncache(nodes: children)
            }
        }
    }

    public func revealInFinder(node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    public func openInTerminal(node: FileNode) {
        let folderPath = node.isDirectory ? node.url.path : node.url.deletingLastPathComponent().path
        if let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([URL(fileURLWithPath: folderPath)], withApplicationAt: terminalURL, configuration: config)
        }
    }

    public func sortNodes() {
        rootNodes = sortList(rootNodes)
        for node in rootNodes {
            sortChildrenRecursively(for: node)
        }
    }

    private func sortChildren(for node: FileNode) {
        if let children = node.children {
            node.children = sortList(children)
        }
    }

    private func sortChildrenRecursively(for node: FileNode) {
        if let children = node.children {
            node.children = sortList(children)
            for child in children {
                sortChildrenRecursively(for: child)
            }
        }
    }

    private func sortList(_ list: [FileNode]) -> [FileNode] {
        return list.sorted { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }

            switch sortOption {
            case .sizeDescending:
                let sA = a.size ?? (a.isCalculating ? 0 : -1)
                let sB = b.size ?? (b.isCalculating ? 0 : -1)
                if sA != sB { return sA > sB }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending

            case .sizeAscending:
                let sA = a.size ?? (a.isCalculating ? 0 : Int64.max)
                let sB = b.size ?? (b.isCalculating ? 0 : Int64.max)
                if sA != sB { return sA < sB }
                return a.name.localizedStandardCompare(b.name) == .orderedAscending

            case .nameAscending:
                return a.name.localizedStandardCompare(b.name) == .orderedAscending

            case .nameDescending:
                return a.name.localizedStandardCompare(b.name) == .orderedDescending

            case .dateDescending:
                let dA = a.modifiedDate ?? Date.distantPast
                let dB = b.modifiedDate ?? Date.distantPast
                return dA > dB
            }
        }
    }

    public var filteredRootNodes: [FileNode] {
        let base = showFiles ? rootNodes : rootNodes.filter { $0.isDirectory }
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return base
        }
        let query = searchQuery.lowercased()
        return base.filter { filterMatches(node: $0, query: query) }
    }

    private func filterMatches(node: FileNode, query: String) -> Bool {
        if !showFiles && !node.isDirectory {
            return false
        }
        if node.name.lowercased().contains(query) {
            return true
        }
        if let children = node.children {
            let visibleChildren = showFiles ? children : children.filter { $0.isDirectory }
            return visibleChildren.contains { filterMatches(node: $0, query: query) }
        }
        return false
    }
}
