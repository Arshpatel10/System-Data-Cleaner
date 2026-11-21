import SwiftUI

struct CleanupConfirmationView: View {
    let selectedSize: String
    let itemCount: Int
    let selectedCategories: [(name: String, count: Int, size: String, risk: SafetyLevel)]
    let snapshotCount: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Review Cleanup")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Items will be moved to Trash (recoverable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // What's being deleted
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if snapshotCount > 0 {
                        CategorySummaryRow(
                            icon: "clock.arrow.circlepath",
                            name: "Time Machine Snapshots",
                            detail: "\(snapshotCount) snapshot\(snapshotCount == 1 ? "" : "s")",
                            risk: .safe,
                            explanation: "Frees space immediately. New snapshots will be created automatically."
                        )
                    }

                    ForEach(selectedCategories, id: \.name) { category in
                        CategorySummaryRow(
                            icon: iconFor(category.name),
                            name: category.name,
                            detail: "\(category.count) items • \(category.size)",
                            risk: category.risk,
                            explanation: explanationFor(category.name)
                        )
                    }
                }
            }
            .frame(maxHeight: 300)

            Divider()

            // Total summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(itemCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Space to free")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedSize)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Actions
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Button("Move to Trash") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 500, height: 550)
    }

    private func iconFor(_ categoryName: String) -> String {
        switch categoryName {
        case "User Caches": return "archivebox"
        case "System Caches": return "gearshape.2"
        case "Log Files": return "doc.text"
        case "Temporary Files": return "trash"
        case "Developer Data": return "hammer"
        case "iOS/Device Backups": return "iphone"
        case "Application Support": return "app.badge"
        case "Mail Data": return "envelope"
        case "Messages & Attachments": return "message"
        case "Browser Data": return "safari"
        case "Downloads": return "arrow.down.circle"
        case "App Containers": return "shippingbox"
        default: return "folder"
        }
    }

    private func explanationFor(_ categoryName: String) -> String {
        switch categoryName {
        case "User Caches":
            return "Apps will rebuild caches as needed. No data lost."
        case "System Caches":
            return "System will rebuild. May need admin password."
        case "Log Files":
            return "Old logs removed. New logs will be created."
        case "Temporary Files":
            return "Safe to remove. Usually cleared on reboot anyway."
        case "Developer Data":
            return "Build cache cleared. Projects rebuild on next compile."
        case "iOS/Device Backups":
            return "⚠️ Cannot restore device from deleted backups!"
        case "Application Support":
            return "⚠️ Apps may lose settings or data!"
        case "Mail Data":
            return "Attachments re-download from server if needed."
        case "Messages & Attachments":
            return "⚠️ Photos/videos may not be recoverable!"
        case "Browser Data":
            return "You'll be logged out of websites."
        case "Downloads":
            return "Review these - they're your downloaded files."
        case "App Containers":
            return "⚠️ App resets to fresh install state!"
        default:
            return ""
        }
    }
}

struct CategorySummaryRow: View {
    let icon: String
    let name: String
    let detail: String
    let risk: SafetyLevel
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.secondary)

                Text(name)
                    .fontWeight(.medium)

                SafetyBadge(level: risk)

                Spacer()

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !explanation.isEmpty {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(explanation.contains("⚠️") ? .orange : .secondary)
                    .padding(.leading, 34)
            }
        }
        .padding(.vertical, 6)
    }
}
