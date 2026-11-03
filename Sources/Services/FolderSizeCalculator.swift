import Foundation

public struct FolderCalculationResult: Sendable {
    public let totalSize: Int64
    public let itemCount: Int
    public let modifiedDate: Date?

    public init(totalSize: Int64, itemCount: Int, modifiedDate: Date?) {
        self.totalSize = totalSize
        self.itemCount = itemCount
        self.modifiedDate = modifiedDate
    }
}

public actor FolderSizeCalculator {
    public static let shared = FolderSizeCalculator()

    /// Calculates the size and item count of a directory.
    public func calculateSize(for folderURL: URL) async -> FolderCalculationResult? {
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .contentModificationDateKey
        ]

        let fileManager = FileManager.default

        // Get root modification date
        let rootVals = try? folderURL.resourceValues(forKeys: [.contentModificationDateKey])
        let rootModDate = rootVals?.contentModificationDate

        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return nil
        }

        var totalSize: Int64 = 0
        var itemCount: Int = 0
        var loopCounter: Int = 0

        while let fileURL = enumerator.nextObject() as? URL {
            // Check cancellation periodically
            loopCounter &+= 1
            if loopCounter % 200 == 0 {
                if Task.isCancelled {
                    return nil
                }
                await Task.yield()
            }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: keys) else {
                continue
            }

            // Do not follow symlinks
            if resourceValues.isSymbolicLink == true {
                continue
            }

            itemCount += 1

            if resourceValues.isDirectory != true {
                let size = resourceValues.fileAllocatedSize ?? resourceValues.fileSize ?? 0
                totalSize += Int64(size)
            }
        }

        return FolderCalculationResult(
            totalSize: totalSize,
            itemCount: itemCount,
            modifiedDate: rootModDate
        )
    }
}
