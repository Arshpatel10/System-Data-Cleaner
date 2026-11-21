import SwiftUI

struct TimeMachineSection: View {
    @EnvironmentObject var storageManager: StorageManager
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Selection checkbox (select all)
                    Button(action: {
                        if allSelected {
                            storageManager.deselectAllSnapshots()
                        } else {
                            storageManager.selectAllSnapshots()
                        }
                    }) {
                        Image(systemName: allSelected ? "checkmark.circle.fill" : (someSelected ? "minus.circle.fill" : "circle"))
                            .foregroundColor(allSelected || someSelected ? .purple : .secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    // Icon
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .frame(width: 32)

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Time Machine Snapshots")
                                .font(.headline)
                            SafetyBadge(level: .safe)
                        }
                        Text("Local APFS snapshots. Often the largest contributor to System Data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Size/Count
                    VStack(alignment: .trailing, spacing: 2) {
                        if storageManager.estimatedSnapshotSize > 0 {
                            Text("~\(ByteCountFormatter.string(fromByteCount: storageManager.estimatedSnapshotSize, countStyle: .file))")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                        } else {
                            Text("Size varies")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("\(storageManager.timeMachineSnapshots.count) snapshots")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                if storageManager.timeMachineSnapshots.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("No local snapshots found")
                            .foregroundColor(.secondary)
                        Text("Time Machine may be disabled or all snapshots have been purged.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Actions bar
                        HStack {
                            Button("Select All") {
                                storageManager.selectAllSnapshots()
                            }
                            .buttonStyle(.link)

                            Button("Deselect All") {
                                storageManager.deselectAllSnapshots()
                            }
                            .buttonStyle(.link)

                            Spacer()

                            Text("Deleting snapshots requires admin privileges")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        Divider()

                        ForEach(storageManager.timeMachineSnapshots) { snapshot in
                            SnapshotRowView(snapshot: snapshot) {
                                storageManager.toggleSnapshotSelection(snapshot.id)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(someSelected ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    private var allSelected: Bool {
        !storageManager.timeMachineSnapshots.isEmpty &&
        storageManager.timeMachineSnapshots.allSatisfy { $0.isSelected }
    }

    private var someSelected: Bool {
        storageManager.timeMachineSnapshots.contains { $0.isSelected }
    }
}

struct SnapshotRowView: View {
    let snapshot: TimeMachineManager.Snapshot
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: snapshot.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(snapshot.isSelected ? .purple : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "camera.fill")
                .foregroundColor(.purple.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.formattedDate)
                    .font(.body)
                Text(snapshot.dateString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(relativeTime(from: snapshot.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.3) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

