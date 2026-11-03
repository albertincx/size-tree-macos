import AppKit
import Foundation
import SwiftUI

@MainActor
public final class FileNode: Identifiable, ObservableObject {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isPackage: Bool
    public let modifiedDate: Date?

    @Published public var size: Int64?
    @Published public var itemCount: Int?
    @Published public var isExpanded: Bool = false
    @Published public var isCalculating: Bool = false
    @Published public var isCached: Bool = false
    @Published public var cachedAt: Date?
    @Published public var children: [FileNode]? = nil
    @Published public var isChildrenLoaded: Bool = false

    private var _icon: NSImage?

    public init(
        url: URL,
        isDirectory: Bool,
        isPackage: Bool = false,
        size: Int64? = nil,
        itemCount: Int? = nil,
        modifiedDate: Date? = nil,
        isCached: Bool = false,
        cachedAt: Date? = nil
    ) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        self.size = size
        self.itemCount = itemCount
        self.modifiedDate = modifiedDate
        self.isCached = isCached
        self.cachedAt = cachedAt
    }

    public var icon: NSImage {
        if let icon = _icon {
            return icon
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 18, height: 18)
        self._icon = icon
        return icon
    }

    public var formattedSize: String {
        guard let size = size else {
            return isCalculating ? "Считается..." : "—"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    public var formattedModifiedDate: String {
        guard let date = modifiedDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public var formattedCachedTime: String? {
        guard let cachedAt = cachedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: cachedAt, relativeTo: Date())
    }
}

