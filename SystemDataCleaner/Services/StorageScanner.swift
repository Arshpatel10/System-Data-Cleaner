import Foundation

actor StorageScanner {
    private let fileManager = FileManager.default

    func scanDirectory(at path: String, maxDepth: Int = 2) async -> [StorageItem] {
        guard fileManager.fileExists(atPath: path) else { return [] }

        var items: [StorageItem] = []
        let url = URL(fileURLWithPath: path)

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .totalFileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
            )

            for itemURL in contents {
                if let item = await scanItem(at: itemURL, currentDepth: 0, maxDepth: maxDepth) {
                    items.append(item)
                }
            }
        } catch {
            print("Error scanning directory \(path): \(error.localizedDescription)")
        }

        return items.sorted { $0.size > $1.size }
    }

    private func scanItem(at url: URL, currentDepth: Int, maxDepth: Int) async -> StorageItem? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .fileSizeKey,
                .totalFileAllocatedSizeKey,
                .contentModificationDateKey,
                .isDirectoryKey
            ])

            let isDirectory = resourceValues.isDirectory ?? false
            var size: Int64 = 0
            var children: [StorageItem]? = nil

            if isDirectory {
                size = await calculateDirectorySize(at: url)
                if currentDepth < maxDepth {
                    children = await scanDirectoryChildren(at: url, currentDepth: currentDepth, maxDepth: maxDepth)
                }
            } else {
                size = Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
            }

            return StorageItem(
                name: url.lastPathComponent,
                path: url.path,
                size: size,
                modificationDate: resourceValues.contentModificationDate,
                isDirectory: isDirectory,
                children: children
            )
        } catch {
            return nil
        }
    }

    private func scanDirectoryChildren(at url: URL, currentDepth: Int, maxDepth: Int) async -> [StorageItem] {
        var children: [StorageItem] = []

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for itemURL in contents.prefix(50) { // Limit children for performance
                if let item = await scanItem(at: itemURL, currentDepth: currentDepth + 1, maxDepth: maxDepth) {
                    children.append(item)
                }
            }
        } catch {
            // Ignore permission errors
        }

        return children.sorted { $0.size > $1.size }
    }

    func calculateDirectorySize(at url: URL) async -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
                totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
            } catch {
                continue
            }
        }

        return totalSize
    }

    func getDirectorySize(at path: String) async -> Int64 {
        guard fileManager.fileExists(atPath: path) else { return 0 }
        return await calculateDirectorySize(at: URL(fileURLWithPath: path))
    }
}
