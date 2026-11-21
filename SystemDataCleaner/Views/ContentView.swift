import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storageManager: StorageManager
    @State private var showingCleanupConfirmation = false
    @State private var cleanupResult: (success: Int, failed: Int, freedBytes: Int64)?
    @State private var showingResult = false
    @State private var showClaudePanel = true

    var body: some View {
        HSplitView {
            // Main content area
            VStack(spacing: 0) {
                // Header
                HeaderView(showClaudePanel: $showClaudePanel)

                Divider()

                // Main content
                if storageManager.isScanning {
                    ScanningView()
                } else if storageManager.lastScanDate == nil {
                    WelcomeView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Storage overview card
                            StorageOverviewCard()

                            // Time Machine Snapshots section
                            TimeMachineSection()

                            // Categories
                            ForEach($storageManager.categories) { $category in
                                CategoryRowView(category: $category)
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // Footer with actions
                FooterView(showingCleanupConfirmation: $showingCleanupConfirmation)
            }
            .frame(minWidth: 500)

            // Claude AI Panel (right side)
            if showClaudePanel {
                ClaudePanel()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingCleanupConfirmation) {
            CleanupConfirmationView(
                selectedSize: storageManager.formattedSelectedSize,
                itemCount: getSelectedItemCount(),
                selectedCategories: storageManager.getSelectedCategorySummary(),
                snapshotCount: storageManager.selectedSnapshotCount,
                onConfirm: performCleanup,
                onCancel: { showingCleanupConfirmation = false }
            )
        }
        .alert("Cleanup Complete", isPresented: $showingResult) {
            Button("OK") { showingResult = false }
        } message: {
            if let result = cleanupResult {
                Text("\(result.success) items cleaned.\n\(result.failed) items failed.\nFreed: \(ByteCountFormatter.string(fromByteCount: result.freedBytes, countStyle: .file))")
            }
        }
    }

    private func getSelectedItemCount() -> Int {
        let categoryItems = storageManager.categories.reduce(0) { $0 + $1.items.filter { $0.isSelected }.count }
        let snapshots = storageManager.timeMachineSnapshots.filter { $0.isSelected }.count
        return categoryItems + snapshots
    }

    private func performCleanup() {
        showingCleanupConfirmation = false
        Task {
            cleanupResult = await storageManager.deleteSelectedItems()
            showingResult = true
        }
    }
}

struct HeaderView: View {
    @EnvironmentObject var storageManager: StorageManager
    @Binding var showClaudePanel: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Data Cleaner")
                    .font(.title)
                    .fontWeight(.bold)

                if let lastScan = storageManager.lastScanDate {
                    Text("Last scan: \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Toggle Claude Panel
            Button(action: { showClaudePanel.toggle() }) {
                Image(systemName: showClaudePanel ? "sidebar.right" : "sparkles")
                    .foregroundColor(showClaudePanel ? .blue : .secondary)
            }
            .buttonStyle(.bordered)
            .help(showClaudePanel ? "Hide Claude Panel" : "Show Claude Panel")

            Button(action: {
                Task {
                    await storageManager.startFullScan()
                }
            }) {
                Label("Scan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .disabled(storageManager.isScanning)
        }
        .padding()
    }
}

struct WelcomeView: View {
    @EnvironmentObject var storageManager: StorageManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "externaldrive.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Analyze Your System Data")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Scan your Mac to find caches, logs, Time Machine snapshots,\nand other files that may be using significant storage.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await storageManager.startFullScan()
                }
            }) {
                Label("Start Scan", systemImage: "magnifyingglass")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 8) {
                Label("Full Disk Access may be required for complete results", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ScanningView: View {
    @EnvironmentObject var storageManager: StorageManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            VStack(spacing: 8) {
                Text("Scanning...")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(storageManager.currentScanningCategory)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: max(0.001, storageManager.scanProgress), total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 300, height: 8)

            Text("\(Int(storageManager.scanProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StorageOverviewCard: View {
    @EnvironmentObject var storageManager: StorageManager

    var body: some View {
        VStack(spacing: 16) {
            // Disk space info
            if let diskInfo = storageManager.diskSpaceInfo {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Disk Capacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(diskInfo.formattedTotal)
                            .font(.headline)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(diskInfo.formattedUsed)
                            .font(.headline)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(diskInfo.formattedAvailable)
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    if diskInfo.purgeableSpace > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Purgeable")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(diskInfo.formattedPurgeable)
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 8)
                Divider()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scannable System Data")
                        .font(.headline)
                    Text(storageManager.formattedTotalSize)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Files this app can identify and manage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if storageManager.selectedSize > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Selected for Cleanup")
                            .font(.headline)
                        Text(storageManager.formattedSelectedSize)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
            }

            // Category breakdown bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(storageManager.categories) { category in
                        if category.totalSize > 0 {
                            Rectangle()
                                .fill(colorForCategory(category.type))
                                .frame(width: max(2, geometry.size.width * CGFloat(category.totalSize) / CGFloat(max(1, storageManager.totalSystemDataSize))))
                                .help("\(category.type.rawValue): \(category.formattedSize)")
                        }
                    }
                }
                .cornerRadius(4)
            }
            .frame(height: 24)

            // Legend
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                ForEach(storageManager.categories.filter { $0.totalSize > 0 }) { category in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForCategory(category.type))
                            .frame(width: 10, height: 10)
                        Text(category.type.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(category.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Info note
            Divider()
                .padding(.top, 8)
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("macOS 'System Data' includes items this app cannot access: core OS files, Spotlight metadata, firmware, APFS metadata, and protected system caches. Grant Full Disk Access in System Settings for more complete results.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func colorForCategory(_ type: StorageCategoryType) -> Color {
        switch type {
        case .timeMachineSnapshots: return .purple
        case .userCaches: return .blue
        case .systemCaches: return .cyan
        case .logFiles: return .orange
        case .tempFiles: return .yellow
        case .developerData: return .red
        case .iosBackups: return .indigo
        case .applicationSupport: return .teal
        case .mailData: return .mint
        case .messagesData: return .green
        case .spotlightIndex: return .gray
        case .browserData: return .blue.opacity(0.7)
        case .downloads: return .green.opacity(0.7)
        case .appContainers: return .pink
        case .virtualMemory: return .gray.opacity(0.5)
        case .iCloudCache: return .blue.opacity(0.5)
        case .photosCache: return .purple.opacity(0.7)
        case .musicPodcastCache: return .red.opacity(0.6)
        case .savedAppState: return .orange.opacity(0.6)
        case .fontCaches: return .brown
        case .siriDictation: return .teal.opacity(0.7)
        case .languageResources: return .indigo.opacity(0.6)
        case .systemTempFolders: return .yellow.opacity(0.7)
        }
    }
}

struct FooterView: View {
    @EnvironmentObject var storageManager: StorageManager
    @Binding var showingCleanupConfirmation: Bool

    var body: some View {
        HStack {
            if storageManager.selectedSize > 0 {
                Text("\(storageManager.formattedSelectedSize) selected")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Clean Selected") {
                showingCleanupConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(storageManager.selectedSize == 0 || storageManager.isScanning)
        }
        .padding()
    }
}

