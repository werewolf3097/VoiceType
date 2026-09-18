import Foundation

struct ClaudeError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct ClaudeClient {
    let apiKey: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-5"

    private struct RequestBody: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct ResponseBody: Decodable {
        let content: [ContentBlock]

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    func cleanup(text: String, style: CleanupStyle) async throws -> String {
        guard let systemPrompt = style.systemPrompt else { return text }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(
            model: model,
            max_tokens: 1024,
            system: systemPrompt,
            messages: [.init(role: "user", content: text)]
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Claude API вернул ошибку"
            throw ClaudeError(message: message)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        let resultText = decoded.content.compactMap(\.text).joined()
        return resultText.isEmpty ? text : resultText
    }
}
