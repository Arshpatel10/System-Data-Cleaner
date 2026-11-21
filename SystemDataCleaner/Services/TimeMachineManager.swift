import Foundation

actor TimeMachineManager {

    struct Snapshot: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let dateString: String
        let date: Date
        var isSelected: Bool = false

        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    func listLocalSnapshots() async -> [Snapshot] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        process.arguments = ["listlocalsnapshots", "/"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }

            return parseSnapshots(from: output)
        } catch {
            print("Error listing snapshots: \(error.localizedDescription)")
            return []
        }
    }

    private func parseSnapshots(from output: String) -> [Snapshot] {
        var snapshots: [Snapshot] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            // Format: com.apple.TimeMachine.2024-01-15-093012
            // or just the date portion
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            var dateString: String

            if trimmed.contains("com.apple.TimeMachine.") {
                dateString = trimmed.replacingOccurrences(of: "com.apple.TimeMachine.", with: "")
            } else if trimmed.hasPrefix("Snapshots for disk") || trimmed.hasPrefix("---") {
                continue
            } else {
                // Try to extract date pattern
                let pattern = #"(\d{4}-\d{2}-\d{2}-\d{6})"#
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
                      let range = Range(match.range(at: 1), in: trimmed) else {
                    continue
                }
                dateString = String(trimmed[range])
            }

            if let date = dateFormatter.date(from: dateString) {
                snapshots.append(Snapshot(
                    name: trimmed,
                    dateString: dateString,
                    date: date
                ))
            }
        }

        return snapshots.sorted { $0.date > $1.date }
    }

    func deleteSnapshot(dateString: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        process.arguments = ["deletelocalsnapshots", dateString]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Error deleting snapshot: \(error.localizedDescription)")
            return false
        }
    }

    func deleteAllSnapshots() async -> Int {
        let snapshots = await listLocalSnapshots()
        var deletedCount = 0

        for snapshot in snapshots {
            if await deleteSnapshot(dateString: snapshot.dateString) {
                deletedCount += 1
            }
        }

        return deletedCount
    }

    func estimateSnapshotSize() async -> Int64 {
        // APFS snapshots don't have a simple size calculation
        // We estimate based on disk usage delta
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
        process.arguments = ["localsnapshot"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            // Alternative: use diskutil to get purgeable space
            return await getPurgeableSpace()
        } catch {
            return 0
        }
    }

    private func getPurgeableSpace() async -> Int64 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["apfs", "list", "-plist"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            // Parse plist to get purgeable space
            if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
               let containers = plist["Containers"] as? [[String: Any]] {
                for container in containers {
                    if let volumes = container["Volumes"] as? [[String: Any]] {
                        for volume in volumes {
                            if let role = volume["Roles"] as? [String],
                               role.contains("System"),
                               let purgeable = volume["CapacityInUseBySnapshots"] as? Int64 {
                                return purgeable
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error getting purgeable space: \(error)")
        }

        return 0
    }
}
