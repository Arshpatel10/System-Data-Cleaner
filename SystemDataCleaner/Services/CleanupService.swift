import Foundation

actor CleanupService {
    private let fileManager = FileManager.default

    struct CleanupResult: Sendable {
        let path: String
        let success: Bool
        let freedBytes: Int64
        let error: String?
    }

    func deleteItem(at path: String) async -> CleanupResult {
        let url = URL(fileURLWithPath: path)

        // Calculate size before deletion
        var size: Int64 = 0
        if let attributes = try? fileManager.attributesOfItem(atPath: path) {
            if let fileSize = attributes[.size] as? Int64 {
                size = fileSize
            }
        }

        // For directories, calculate total size
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            size = await calculateDirectorySize(at: url)
        }

        do {
            try fileManager.removeItem(at: url)
            return CleanupResult(path: path, success: true, freedBytes: size, error: nil)
        } catch {
            return CleanupResult(path: path, success: false, freedBytes: 0, error: error.localizedDescription)
        }
    }

    func deleteItems(at paths: [String]) async -> [CleanupResult] {
        var results: [CleanupResult] = []

        for path in paths {
            let result = await deleteItem(at: path)
            results.append(result)
        }

        return results
    }

    func clearDirectory(at path: String, keepDirectory: Bool = true) async -> CleanupResult {
        let url = URL(fileURLWithPath: path)
        var totalFreed: Int64 = 0
        var errors: [String] = []

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                options: []
            )

            for itemURL in contents {
                do {
                    let size = await calculateItemSize(at: itemURL)
                    try fileManager.removeItem(at: itemURL)
                    totalFreed += size
                } catch {
                    errors.append("\(itemURL.lastPathComponent): \(error.localizedDescription)")
                }
            }

            if errors.isEmpty {
                return CleanupResult(path: path, success: true, freedBytes: totalFreed, error: nil)
            } else {
                return CleanupResult(
                    path: path,
                    success: true,
                    freedBytes: totalFreed,
                    error: "Some items failed: \(errors.joined(separator: ", "))"
                )
            }
        } catch {
            return CleanupResult(path: path, success: false, freedBytes: 0, error: error.localizedDescription)
        }
    }

    func moveToTrash(at path: String) async -> CleanupResult {
        let url = URL(fileURLWithPath: path)
        let size = await calculateItemSize(at: url)

        do {
            var trashedURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)
            return CleanupResult(path: path, success: true, freedBytes: size, error: nil)
        } catch {
            return CleanupResult(path: path, success: false, freedBytes: 0, error: error.localizedDescription)
        }
    }

    private func calculateDirectorySize(at url: URL) async -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [],
            errorHandler: nil
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
               let size = resourceValues.totalFileAllocatedSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }

    private func calculateItemSize(at url: URL) async -> Int64 {
        let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])

        if resourceValues?.isDirectory == true {
            return await calculateDirectorySize(at: url)
        } else {
            if let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
               let size = values.totalFileAllocatedSize {
                return Int64(size)
            }
            return 0
        }
    }

    func emptyTrash() async -> Bool {
        let script = """
        tell application "Finder"
            empty trash
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
