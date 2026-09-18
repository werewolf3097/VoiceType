import Foundation

struct GapiError: Error, LocalizedError {
    let code: String
    let hint: String?

    var errorDescription: String? {
        hint ?? code
    }
}

struct GapiClient {
    let token: String
    private let baseURL = URL(string: "https://console.gapi.uz")!

    private struct TranscribeResult: Decodable {
        let text: String?
    }

    private struct JobAccepted: Decodable {
        let id: String
        let state: String
    }

    private struct JobStatus: Decodable {
        let id: String
        let state: String
    }

    private struct VocabularyResponse: Decodable {
        let terms: [String]
    }

    func transcribe(fileURL: URL) async throws -> String {
        let boundary = "voicetype-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/transcribe"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try multipartBody(fileURL: fileURL, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GapiError(code: "no_response", hint: nil)
        }

        if http.statusCode == 200 {
            let result = try JSONDecoder().decode(TranscribeResult.self, from: data)
            return result.text ?? ""
        }

        if http.statusCode == 202 {
            let accepted = try JSONDecoder().decode(JobAccepted.self, from: data)
            return try await pollForResult(jobId: accepted.id)
        }

        throw try decodeError(data)
    }

    func getVocabulary() async throws -> [String] {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/vocabulary"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw try decodeError(data)
        }
        return try JSONDecoder().decode(VocabularyResponse.self, from: data).terms
    }

    func setVocabulary(_ terms: [String]) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/vocabulary"))
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["terms": terms])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw try decodeError(data)
        }
    }

    private func pollForResult(jobId: String) async throws -> String {
        let statusURL = baseURL.appendingPathComponent("v1/jobs/\(jobId)")
        let resultURL = baseURL.appendingPathComponent("v1/jobs/\(jobId)/result")

        for _ in 0..<60 {
            try await Task.sleep(nanoseconds: 2_000_000_000)

            var statusRequest = URLRequest(url: statusURL)
            statusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (statusData, _) = try await URLSession.shared.data(for: statusRequest)
            let status = try JSONDecoder().decode(JobStatus.self, from: statusData)

            switch status.state {
            case "done":
                var resultRequest = URLRequest(url: resultURL)
                resultRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let (resultData, _) = try await URLSession.shared.data(for: resultRequest)
                let result = try JSONDecoder().decode(TranscribeResult.self, from: resultData)
                return result.text ?? ""
            case "failed", "cancelled":
                throw GapiError(code: "job_\(status.state)", hint: "Задача распознавания завершилась со статусом \(status.state)")
            default:
                continue
            }
        }
        throw GapiError(code: "timeout", hint: "Распознавание заняло слишком много времени")
    }

    private func decodeError(_ data: Data) throws -> GapiError {
        struct Body: Decodable { let error: String; let hint: String? }
        if let body = try? JSONDecoder().decode(Body.self, from: data) {
            return GapiError(code: body.error, hint: body.hint)
        }
        return GapiError(code: "unknown_error", hint: String(data: data, encoding: .utf8))
    }

    private func multipartBody(fileURL: URL, boundary: String) throws -> Data {
        var body = Data()
        let audioData = try Data(contentsOf: fileURL)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"settings\"\r\n\r\n".data(using: .utf8)!)
        body.append("{\"diarization\":false}".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
