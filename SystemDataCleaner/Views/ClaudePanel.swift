import SwiftUI

struct ClaudePanel: View {
    @EnvironmentObject var storageManager: StorageManager
    @State private var userQuestion: String = ""
    @State private var showingAPIKeySheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Ask Claude")
                    .font(.headline)
                Spacer()
                Button(action: { showingAPIKeySheet = true }) {
                    Image(systemName: "key")
                        .foregroundColor(storageManager.claudeAPIKey.isEmpty ? .orange : .green)
                }
                .buttonStyle(.plain)
                .help(storageManager.claudeAPIKey.isEmpty ? "Set API Key" : "API Key configured")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            if let item = storageManager.selectedItem {
                // Selected item info
                SelectedItemCard(item: item)

                Divider()

                // Claude response area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if storageManager.isAskingClaude {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Claude is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        } else if !storageManager.claudeResponse.isEmpty {
                            Text(storageManager.claudeResponse)
                                .font(.system(.body, design: .rounded))
                                .textSelection(.enabled)
                                .padding()
                        } else {
                            VStack(spacing: 8) {
                                Text("Click \"What is this?\" or type a question below")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                Divider()

                // Question input
                VStack(spacing: 8) {
                    // Quick action buttons
                    HStack(spacing: 8) {
                        QuickActionButton(title: "What is this?", icon: "questionmark.circle") {
                            Task {
                                await storageManager.askClaudeAboutSelectedItem()
                            }
                        }
                        QuickActionButton(title: "Safe to delete?", icon: "trash") {
                            Task {
                                await storageManager.askClaudeAboutSelectedItem(question: "Is this safe to delete? What would happen if I delete it?")
                            }
                        }
                    }

                    // Custom question input
                    HStack(spacing: 8) {
                        TextField("Ask a question...", text: $userQuestion)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                sendQuestion()
                            }

                        Button(action: sendQuestion) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(userQuestion.isEmpty ? .secondary : .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(userQuestion.isEmpty || storageManager.isAskingClaude)
                    }
                }
                .padding()
            } else {
                // No item selected
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "hand.tap")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Select an item")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Click on any file or folder in the list to learn more about it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            }
        }
        .frame(minWidth: 280, maxWidth: 350)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAPIKeySheet) {
            APIKeySheet(isPresented: $showingAPIKeySheet)
        }
        .onAppear {
            storageManager.loadClaudeAPIKey()
        }
    }

    private func sendQuestion() {
        guard !userQuestion.isEmpty else { return }
        let question = userQuestion
        userQuestion = ""
        Task {
            await storageManager.askClaudeAboutSelectedItem(question: question)
        }
    }
}

struct SelectedItemCard: View {
    let item: SelectedItemInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(item.isDirectory ? .blue : .secondary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(item.categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Size:")
                        .foregroundColor(.secondary)
                    Text(item.size)
                        .fontWeight(.medium)
                }
                GridRow {
                    Text("Path:")
                        .foregroundColor(.secondary)
                    Text(item.path)
                        .font(.caption)
                        .lineLimit(2)
                }
                if !item.modificationDate.isEmpty {
                    GridRow {
                        Text("Modified:")
                            .foregroundColor(.secondary)
                        Text(item.modificationDate)
                    }
                }
            }
            .font(.caption)

            // Show in Finder button
            Button(action: {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            }) {
                Label("Show in Finder", systemImage: "folder")
                    .font(.caption)
            }
            .buttonStyle(.link)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct APIKeySheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var storageManager: StorageManager
    @State private var apiKey: String = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                Text("Claude API Key")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("Enter your Anthropic API key to enable Claude AI features. Your key is stored locally and never shared.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            SecureField("sk-ant-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            Link("Get an API key from Anthropic", destination: URL(string: "https://console.anthropic.com/")!)
                .font(.caption)

            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    storageManager.setClaudeAPIKey(apiKey)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            apiKey = storageManager.claudeAPIKey
        }
    }
}
