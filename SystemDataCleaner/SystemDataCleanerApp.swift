import SwiftUI

@main
struct SystemDataCleanerApp: App {
    @StateObject private var storageManager = StorageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
