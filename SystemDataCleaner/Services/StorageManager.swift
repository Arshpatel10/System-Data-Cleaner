import Foundation
import SwiftUI

struct DiskSpaceInfo {
    let totalCapacity: Int64
    let availableSpace: Int64
    let usedSpace: Int64
    let purgeableSpace: Int64

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalCapacity, countStyle: .file)
    }
    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }
    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    var formattedPurgeable: String {
        ByteCountFormatter.string(fromByteCount: purgeableSpace, countStyle: .file)
    }
}

struct SelectedItemInfo: Equatable {
    let name: String
    let path: String
    let size: String
    let categoryName: String
    let categoryType: StorageCategoryType
    let isDirectory: Bool
    let modificationDate: String

    static func == (lhs: SelectedItemInfo, rhs: SelectedItemInfo) -> Bool {
        lhs.path == rhs.path
    }
}

@MainActor
class StorageManager: ObservableObject {
    @Published var categories: [StorageCategory] = []
    @Published var timeMachineSnapshots: [TimeMachineManager.Snapshot] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0
    @Published var currentScanningCategory: String = ""
    @Published var lastScanDate: Date?
    @Published var errorMessage: String?
    @Published var diskSpaceInfo: DiskSpaceInfo?

    // Selected item for right panel
    @Published var selectedItem: SelectedItemInfo?
    @Published var claudeResponse: String = ""
    @Published var isAskingClaude: Bool = false
    @Published var claudeAPIKey: String = ""

    private let scanner = StorageScanner()
    private let timeMachineManager = TimeMachineManager()
    private let cleanupService = CleanupService()
    private let claudeService = ClaudeService()

    var totalSystemDataSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize } + estimatedSnapshotSize
    }

    var selectedSize: Int64 {
        let categorySize = categories.reduce(0) { $0 + $1.selectedSize }
        let snapshotSize = timeMachineSnapshots.filter { $0.isSelected }.count > 0 ? estimatedSnapshotSize / Int64(max(1, timeMachineSnapshots.count)) * Int64(timeMachineSnapshots.filter { $0.isSelected }.count) : 0
        return categorySize + snapshotSize
    }

    var estimatedSnapshotSize: Int64 = 0

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSystemDataSize, countStyle: .file)
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    init() {
        initializeCategories()
    }

    private func initializeCategories() {
        categories = StorageCategoryType.allCases.compactMap { type in
            if type == .timeMachineSnapshots { return nil }
            return StorageCategory(type: type, items: [])
        }
    }

    func startFullScan() async {
        isScanning = true
        scanProgress = 0
        errorMessage = nil

        // Get disk space info first
        updateDiskSpaceInfo()

        let totalSteps = Double(categories.count + 1) // +1 for Time Machine

        // Scan Time Machine snapshots first
        currentScanningCategory = "Time Machine Snapshots"
        timeMachineSnapshots = await timeMachineManager.listLocalSnapshots()
        estimatedSnapshotSize = await timeMachineManager.estimateSnapshotSize()
        scanProgress = 1 / totalSteps

        // Scan each category
        for (index, category) in categories.enumerated() {
            currentScanningCategory = category.type.rawValue

            if let categoryIndex = categories.firstIndex(where: { $0.id == category.id }) {
                categories[categoryIndex].isScanning = true

                var allItems: [StorageItem] = []
                for path in category.type.basePaths {
                    let items = await scanner.scanDirectory(at: path, maxDepth: 2)
                    allItems.append(contentsOf: items)
                }

                categories[categoryIndex].items = allItems.sorted { $0.size > $1.size }
                categories[categoryIndex].isScanning = false
            }

            scanProgress = Double(index + 2) / totalSteps
        }

        isScanning = false
        currentScanningCategory = ""
        lastScanDate = Date()
    }

    func scanCategory(_ type: StorageCategoryType) async {
        guard let index = categories.firstIndex(where: { $0.type == type }) else { return }

        categories[index].isScanning = true

        var allItems: [StorageItem] = []
        for path in type.basePaths {
            let items = await scanner.scanDirectory(at: path, maxDepth: 2)
            allItems.append(contentsOf: items)
        }

        categories[index].items = allItems.sorted { $0.size > $1.size }
        categories[index].isScanning = false
    }

    func refreshTimeMachineSnapshots() async {
        timeMachineSnapshots = await timeMachineManager.listLocalSnapshots()
        estimatedSnapshotSize = await timeMachineManager.estimateSnapshotSize()
    }

    func toggleCategorySelection(_ type: StorageCategoryType) {
        guard type.isDeletable else { return }
        guard let index = categories.firstIndex(where: { $0.type == type }) else { return }
        let newValue = !categories[index].isSelected
        categories[index].isSelected = newValue

        for itemIndex in categories[index].items.indices {
            categories[index].items[itemIndex].isSelected = newValue
        }
    }

    func toggleItemSelection(categoryType: StorageCategoryType, itemId: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.type == categoryType }),
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) else { return }

        categories[categoryIndex].items[itemIndex].isSelected.toggle()
    }

    func toggleSnapshotSelection(_ snapshotId: UUID) {
        guard let index = timeMachineSnapshots.firstIndex(where: { $0.id == snapshotId }) else { return }
        timeMachineSnapshots[index].isSelected.toggle()
    }

    func selectAllSnapshots() {
        for index in timeMachineSnapshots.indices {
            timeMachineSnapshots[index].isSelected = true
        }
    }

    func deselectAllSnapshots() {
        for index in timeMachineSnapshots.indices {
            timeMachineSnapshots[index].isSelected = false
        }
    }

    func deleteSelectedItems() async -> (success: Int, failed: Int, freedBytes: Int64) {
        var successCount = 0
        var failedCount = 0
        var totalFreed: Int64 = 0
        var deletedSnapshotIds: Set<UUID> = []
        var deletedItemIds: [StorageCategoryType: Set<UUID>] = [:]

        // Delete selected Time Machine snapshots
        for snapshot in timeMachineSnapshots.filter({ $0.isSelected }) {
            let success = await timeMachineManager.deleteSnapshot(dateString: snapshot.dateString)
            if success {
                successCount += 1
                deletedSnapshotIds.insert(snapshot.id)
            } else {
                failedCount += 1
            }
        }

        // Delete selected items from categories
        for category in categories {
            let selectedItems = category.items.filter { $0.isSelected }
            for item in selectedItems {
                let result = await cleanupService.moveToTrash(at: item.path)
                if result.success {
                    successCount += 1
                    totalFreed += result.freedBytes
                    if deletedItemIds[category.type] == nil {
                        deletedItemIds[category.type] = []
                    }
                    deletedItemIds[category.type]?.insert(item.id)
                } else {
                    failedCount += 1
                }
            }
        }

        // Update lists without rescanning - just remove deleted items
        timeMachineSnapshots.removeAll { deletedSnapshotIds.contains($0.id) }

        for categoryIndex in categories.indices {
            let categoryType = categories[categoryIndex].type
            if let deletedIds = deletedItemIds[categoryType] {
                categories[categoryIndex].items.removeAll { deletedIds.contains($0.id) }
            }
            // Reset selection state
            categories[categoryIndex].isSelected = false
        }

        // Update disk space info
        updateDiskSpaceInfo()

        return (successCount, failedCount, totalFreed)
    }

    func getSelectedItemPaths() -> [String] {
        var paths: [String] = []

        for category in categories {
            for item in category.items where item.isSelected {
                paths.append(item.path)
            }
        }

        return paths
    }

    func getSelectedSnapshotDates() -> [String] {
        timeMachineSnapshots.filter { $0.isSelected }.map { $0.dateString }
    }

    func getSelectedCategorySummary() -> [(name: String, count: Int, size: String, risk: SafetyLevel)] {
        categories.compactMap { category in
            let selectedItems = category.items.filter { $0.isSelected }
            guard !selectedItems.isEmpty else { return nil }
            let size = selectedItems.reduce(0) { $0 + $1.size }
            return (
                name: category.type.rawValue,
                count: selectedItems.count,
                size: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                risk: category.type.safetyLevel
            )
        }
    }

    var selectedSnapshotCount: Int {
        timeMachineSnapshots.filter { $0.isSelected }.count
    }

    // MARK: - Item Selection for Claude Panel

    func selectItemForInfo(_ item: StorageItem, categoryType: StorageCategoryType) {
        selectedItem = SelectedItemInfo(
            name: item.name,
            path: item.path,
            size: item.formattedSize,
            categoryName: categoryType.rawValue,
            categoryType: categoryType,
            isDirectory: item.isDirectory,
            modificationDate: item.formattedDate
        )
        claudeResponse = ""
    }

    func selectCategoryForInfo(_ categoryType: StorageCategoryType, totalSize: String, itemCount: Int) {
        selectedItem = SelectedItemInfo(
            name: categoryType.rawValue,
            path: categoryType.basePaths.first ?? "Various locations",
            size: totalSize,
            categoryName: categoryType.rawValue,
            categoryType: categoryType,
            isDirectory: true,
            modificationDate: ""
        )
        claudeResponse = ""
    }

    func clearSelection() {
        selectedItem = nil
        claudeResponse = ""
    }

    func setClaudeAPIKey(_ key: String) {
        claudeAPIKey = key
        Task {
            await claudeService.setAPIKey(key)
        }
        // Save to UserDefaults
        UserDefaults.standard.set(key, forKey: "ClaudeAPIKey")
    }

    func loadClaudeAPIKey() {
        if let key = UserDefaults.standard.string(forKey: "ClaudeAPIKey") {
            claudeAPIKey = key
            Task {
                await claudeService.setAPIKey(key)
            }
        }
    }

    func askClaudeAboutSelectedItem(question: String? = nil) async {
        guard let item = selectedItem else { return }

        isAskingClaude = true
        claudeResponse = ""

        let response = await claudeService.askAboutItem(
            itemName: item.name,
            itemPath: item.path,
            itemSize: item.size,
            categoryName: item.categoryName,
            userQuestion: question
        )

        claudeResponse = response
        isAskingClaude = false
    }

    func updateDiskSpaceInfo() {
        let fileManager = FileManager.default
        guard let homeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        do {
            let values = try homeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityForOpportunisticUsageKey
            ])

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let importantCapacity = values.volumeAvailableCapacityForImportantUsage
            let regularCapacity = values.volumeAvailableCapacity.map { Int64($0) }
            let available = importantCapacity ?? regularCapacity ?? 0
            let opportunistic = values.volumeAvailableCapacityForOpportunisticUsage ?? 0
            let purgeable = opportunistic - available

            diskSpaceInfo = DiskSpaceInfo(
                totalCapacity: total,
                availableSpace: available,
                usedSpace: total - available,
                purgeableSpace: max(0, purgeable)
            )
        } catch {
            print("Error getting disk space: \(error)")
        }
    }
}
