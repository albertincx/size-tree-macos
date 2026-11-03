import Foundation

public struct CacheRecord: Codable, Sendable {
    public let path: String
    public let size: Int64
    public let itemCount: Int
    public let modifiedDate: Date?
    public let calculatedAt: Date

    public init(path: String, size: Int64, itemCount: Int, modifiedDate: Date?, calculatedAt: Date = Date()) {
        self.path = path
        self.size = size
        self.itemCount = itemCount
        self.modifiedDate = modifiedDate
        self.calculatedAt = calculatedAt
    }
}

public actor SizeCacheManager {
    public static let shared = SizeCacheManager()

    private var memoryCache: [String: CacheRecord]
    private let fileURL: URL
    private var isDirty: Bool = false
    private var saveTask: Task<Void, Never>? = nil

    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("FolderViewer", isDirectory: true)

        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }

        let cacheURL = appDir.appendingPathComponent("folder_size_cache.json")
        self.fileURL = cacheURL

        if let data = try? Data(contentsOf: cacheURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.memoryCache = (try? decoder.decode([String: CacheRecord].self, from: data)) ?? [:]
        } else {
            self.memoryCache = [:]
        }
    }

    private func scheduleSave() {
        isDirty = true
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce
            guard !Task.isCancelled else { return }
            await self?.saveToDiskNow()
        }
    }

    public func saveToDiskNow() {
        guard isDirty else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(memoryCache) {
            try? data.write(to: fileURL, options: .atomic)
            isDirty = false
        }
    }

    public func get(for path: String) -> CacheRecord? {
        return memoryCache[path]
    }

    public func set(path: String, size: Int64, itemCount: Int, modifiedDate: Date?) {
        let record = CacheRecord(
            path: path,
            size: size,
            itemCount: itemCount,
            modifiedDate: modifiedDate,
            calculatedAt: Date()
        )
        memoryCache[path] = record
        scheduleSave()
    }

    public func invalidate(path: String) {
        memoryCache.removeValue(forKey: path)
        scheduleSave()
    }

    public func invalidateAll() {
        memoryCache.removeAll()
        scheduleSave()
    }

    public func allRecords() -> [String: CacheRecord] {
        return memoryCache
    }

    public func count() -> Int {
        return memoryCache.count
    }

    public func cacheFileSizeBytes() -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }
}
