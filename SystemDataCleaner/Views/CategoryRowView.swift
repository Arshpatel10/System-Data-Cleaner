import SwiftUI

struct CategoryRowView: View {
    @Binding var category: StorageCategory
    @EnvironmentObject var storageManager: StorageManager
    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 0) {
            // Category header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    category.isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Selection checkbox
                    if category.type.isDeletable {
                        Button(action: {
                            storageManager.toggleCategorySelection(category.type)
                        }) {
                            Image(systemName: category.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(category.isSelected ? .blue : .secondary)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "eye")
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .help("View only - managed by macOS")
                    }

                    // Icon
                    Image(systemName: category.type.icon)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 32)

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(category.type.rawValue)
                                .font(.headline)
                            SafetyBadge(level: category.type.safetyLevel)

                            // Info button
                            Button(action: {
                                showingInfo.toggle()
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .help("Learn more about this category")
                        }
                        Text(category.type.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Size
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(category.formattedSize)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)

                        Text("\(category.items.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Expand indicator
                    Image(systemName: category.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Info panel (shown when ? is clicked)
            if showingInfo {
                CategoryInfoPanel(categoryType: category.type, onDismiss: { showingInfo = false })
            }

            // Expanded content
            if category.isExpanded {
                Divider()
                    .padding(.horizontal)

                if category.items.isEmpty {
                    Text("No items found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(category.items.prefix(20)) { item in
                            StorageItemRowView(
                                item: item,
                                isSelected: item.isSelected,
                                isDeletable: category.type.isDeletable,
                                categoryType: category.type,
                                onToggle: {
                                    storageManager.toggleItemSelection(categoryType: category.type, itemId: item.id)
                                }
                            )
                        }

                        if category.items.count > 20 {
                            Text("And \(category.items.count - 20) more items...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(category.isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

struct CategoryInfoPanel: View {
    let categoryType: StorageCategoryType
    let onDismiss: () -> Void

    var body: some View {
        let info = categoryType.detailedInfo

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("About \(categoryType.rawValue)")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // What it is
            VStack(alignment: .leading, spacing: 4) {
                Label("What is this?", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(info.whatItIs)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Examples
            VStack(alignment: .leading, spacing: 4) {
                Label("Examples", systemImage: "list.bullet")
                    .font(.subheadline)
                    .fontWeight(.medium)
                ForEach(info.examples, id: \.self) { example in
                    HStack(spacing: 6) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(example)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // If deleted
            VStack(alignment: .leading, spacing: 4) {
                Label("If deleted", systemImage: "trash")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(categoryType.safetyLevel == .danger ? .red : .primary)
                Text(info.ifDeleted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text(info.recommendation)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct StorageItemRowView: View {
    let item: StorageItem
    let isSelected: Bool
    var isDeletable: Bool = true
    let categoryType: StorageCategoryType
    let onToggle: () -> Void

    @EnvironmentObject var storageManager: StorageManager
    @State private var isHovered = false

    private var isSelectedForInfo: Bool {
        storageManager.selectedItem?.path == item.path
    }

    var body: some View {
        HStack(spacing: 12) {
            if isDeletable {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "eye")
                    .foregroundColor(.secondary)
            }

            // Clickable area for selecting item for Claude panel
            HStack(spacing: 8) {
                Image(systemName: item.isDirectory ? "folder.fill" : fileIcon)
                    .foregroundColor(item.isDirectory ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .lineLimit(1)
                    Text(item.path)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                storageManager.selectItemForInfo(item, categoryType: categoryType)
            }

            Spacer()

            Text(item.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(item.formattedSize)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)

            Button(action: {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            }) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelectedForInfo ? Color.purple.opacity(0.15) : (isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.3) : Color.clear))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelectedForInfo ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var fileIcon: String {
        switch item.fileExtension.lowercased() {
        case "log", "txt": return "doc.text"
        case "json", "plist", "xml": return "doc.badge.gearshape"
        case "zip", "gz", "tar": return "doc.zipper"
        case "dmg": return "externaldrive"
        default: return "doc"
        }
    }
}

struct SafetyBadge: View {
    let level: SafetyLevel

    var body: some View {
        Text(level.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch level {
        case .safe: return .green.opacity(0.2)
        case .moderate: return .yellow.opacity(0.2)
        case .caution: return .orange.opacity(0.2)
        case .danger: return .red.opacity(0.2)
        case .readOnly: return .gray.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch level {
        case .safe: return .green
        case .moderate: return .yellow
        case .caution: return .orange
        case .danger: return .red
        case .readOnly: return .gray
        }
    }
}

