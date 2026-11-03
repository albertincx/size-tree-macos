import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @StateObject private var viewModel = FolderTreeViewModel()
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var isDropTargeted: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Path breadcrumb / header
            headerView

            Divider()

            // Tree column headers
            columnHeaders

            Divider()

            // Content
            if viewModel.isScanningRoot {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(viewModel.statusMessage)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rootNodes.isEmpty {
                emptyStateView
            } else {
                treeListView
            }

            Divider()

            // Bottom status bar
            bottomBar
        }
        .navigationTitle(l10n.appTitle)
        .frame(minWidth: 720, minHeight: 480)
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $viewModel.showCacheSheet) {
            CacheStatsSheet(viewModel: viewModel)
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        DispatchQueue.main.async {
                            viewModel.loadFolder(url: url)
                        }
                    }
                }
            }
            return true
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 8) {
            // Navigation Back/Forward
            HStack(spacing: 2) {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!viewModel.canGoBack)
                .help(l10n.goBack)
                .keyboardShortcut("[", modifiers: .command)

                Button {
                    viewModel.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!viewModel.canGoForward)
                .help(l10n.goForward)
                .keyboardShortcut("]", modifiers: .command)
            }

            // History dropdown menu
            Menu {
                if viewModel.recentPaths.isEmpty {
                    Text(l10n.historyEmpty)
                } else {
                    Section(l10n.historyTitle) {
                        ForEach(viewModel.recentPaths, id: \.path) { url in
                            Button {
                                viewModel.loadFolder(url: url)
                            } label: {
                                HStack {
                                    if url == viewModel.currentRootURL {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                                }
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.clearHistory()
                    } label: {
                        Label(l10n.clearHistory, systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(l10n.historyTitle)

            Divider()
                .frame(height: 16)

            if let root = viewModel.currentRootURL {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text(root.path)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Spacer()

                Button {
                    let parent = root.deletingLastPathComponent()
                    if FileManager.default.fileExists(atPath: parent.path) {
                        viewModel.loadFolder(url: parent)
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(l10n.goUp)
            } else {
                Text(l10n.noFolderSelected)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var columnHeaders: some View {
        HStack(spacing: 8) {
            Text(l10n.colName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            Spacer()

            Text(l10n.colStatus)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)

            Text(l10n.colItems)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .trailing)

            Text(l10n.colSize)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 85, alignment: .trailing)

            Text(l10n.colAction)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05))
    }

    private var treeListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.filteredRootNodes) { node in
                    FileRowView(node: node, level: 0, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "folder.badge.gearshape")
                    .font(.system(size: 48))
                    .foregroundColor(isDropTargeted ? .accentColor : .secondary)

                Text(isDropTargeted ? l10n.dropFolderRelease : l10n.dropFolderHint)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Button {
                    viewModel.openFolderPicker()
                } label: {
                    Label(l10n.selectFolderPrompt, systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.top, viewModel.recentPaths.isEmpty ? 0 : 20)

            if !viewModel.recentPaths.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(l10n.recentFolders, systemImage: "clock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(l10n.clearHistory) {
                            viewModel.clearHistory()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(viewModel.recentPaths, id: \.path) { url in
                                HStack(spacing: 10) {
                                    Button {
                                        viewModel.loadFolder(url: url)
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(.accentColor)
                                                .font(.system(size: 15))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.primary)

                                                Text(url.path)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }

                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        viewModel.removeFromRecent(url: url)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .help(l10n.removeFromHistory)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.secondary.opacity(0.06))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDropTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    private var bottomBar: some View {
        HStack {
            if viewModel.activeCalculationCount > 0 {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
                Text(l10n.backgroundCalculation(viewModel.activeCalculationCount))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text(viewModel.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Language switcher pill
            Menu {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        l10n.language = lang
                    } label: {
                        HStack {
                            if l10n.language == lang {
                                Image(systemName: "checkmark")
                            }
                            Text(lang.displayName)
                        }
                    }
                }
            } label: {
                Text(l10n.language.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
            }
            .menuStyle(.borderlessButton)
            .help(l10n.languageLabel)

            Button {
                viewModel.showCacheSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                    Text(l10n.cacheStatsBottom(viewModel.cachedItemsCount))
                }
                .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help(l10n.cacheSheetTitle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 4) {
                Button {
                    viewModel.openFolderPicker()
                } label: {
                    Label(l10n.openFolder, systemImage: "folder")
                }
                .help(l10n.selectFolder)

                Menu {
                    if viewModel.recentPaths.isEmpty {
                        Text(l10n.historyEmpty)
                    } else {
                        Section(l10n.recentFolders) {
                            ForEach(viewModel.recentPaths, id: \.path) { url in
                                Button {
                                    viewModel.loadFolder(url: url)
                                } label: {
                                    HStack {
                                        if url == viewModel.currentRootURL {
                                            Image(systemName: "checkmark")
                                        }
                                        Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearHistory()
                        } label: {
                            Label(l10n.clearHistory, systemImage: "trash")
                        }
                    }
                } label: {
                    Label(l10n.history, systemImage: "clock.arrow.circlepath")
                }
                .help(l10n.historyTitle)
            }
        }

        // Show/Hide Files Toggle Checkbox
        ToolbarItem(placement: .automatic) {
            Toggle(isOn: $viewModel.showFiles) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.showFiles ? "doc.fill" : "doc")
                        .font(.system(size: 11))
                    Text(l10n.showFiles)
                        .font(.system(size: 12))
                }
            }
            .toggleStyle(.checkbox)
            .help(l10n.showFiles)
        }

        // Recalculate button & menu
        ToolbarItem(placement: .automatic) {
            Menu {
                Button {
                    viewModel.recalculateSelectedOrCurrent()
                } label: {
                    Label(l10n.recalculateSelected, systemImage: "arrow.clockwise")
                }

                Button {
                    viewModel.recalculateAllVisibleCached()
                } label: {
                    Label(l10n.recalculateVisible, systemImage: "arrow.triangle.2.circlepath")
                }

                Divider()

                Button {
                    viewModel.recalculateEntireCache()
                } label: {
                    Label(l10n.recalculateEntireCache, systemImage: "arrow.triangle.2.circlepath.circle")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text(l10n.recalculateSize)
                }
            } primaryAction: {
                // Click on the main button recalculates visible cached items
                viewModel.recalculateAllVisibleCached()
            }
            .help(l10n.recalculateSize)
        }

        // Sorting
        ToolbarItem(placement: .automatic) {
            Picker(l10n.sorting, selection: $viewModel.sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title(using: l10n)).tag(option)
                }
            }
            .onChange(of: viewModel.sortOption) {
                viewModel.sortNodes()
            }
            .frame(width: 190)
        }

        // Search Filter
        ToolbarItem(placement: .automatic) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(l10n.filterPlaceholder, text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .frame(width: 110)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
    }
}
