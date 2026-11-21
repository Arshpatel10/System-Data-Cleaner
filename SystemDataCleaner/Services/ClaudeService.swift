import Foundation

actor ClaudeService {
    private var apiKey: String?

    func setAPIKey(_ key: String) {
        self.apiKey = key
    }

    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    func askAboutItem(itemName: String, itemPath: String, itemSize: String, categoryName: String, userQuestion: String?) async -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return "Please set your Anthropic API key in Settings to use Claude AI."
        }

        let systemPrompt = """
        You are a helpful assistant integrated into a macOS storage cleaner app.
        The user has selected a file or folder and wants to understand what it is.
        Be concise but informative. Explain:
        1. What this file/folder likely contains
        2. Whether it's safe to delete
        3. What might happen if deleted
        Keep responses under 150 words unless the user asks for more detail.
        """

        let contextPrompt: String
        if let question = userQuestion, !question.isEmpty {
            contextPrompt = """
            The user selected this item:
            - Name: \(itemName)
            - Path: \(itemPath)
            - Size: \(itemSize)
            - Category: \(categoryName)

            User's question: \(question)
            """
        } else {
            contextPrompt = """
            The user selected this item and wants to know what it is:
            - Name: \(itemName)
            - Path: \(itemPath)
            - Size: \(itemSize)
            - Category: \(categoryName)

            Explain what this is and whether it's safe to delete.
            """
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return "Error: Invalid API URL"
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-opus-5-5",
            "max_tokens": 500,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": contextPrompt]
            ]
        ]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    return "Invalid API key. Please check your Anthropic API key in Settings."
                } else if httpResponse.statusCode != 200 {
                    if let errorBody = String(data: data, encoding: .utf8) {
                        return "API error (\(httpResponse.statusCode)): \(errorBody)"
                    }
                    return "API error (status \(httpResponse.statusCode)). Please try again."
                }
            }

            // Parse response - look for content with type "text"
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]] {
                // Find the text content (skip thinking blocks)
                for item in content {
                    if let type = item["type"] as? String, type == "text",
                       let text = item["text"] as? String {
                        return text
                    }
                }
            }

            return "No text response from Claude."
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
