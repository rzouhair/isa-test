import Foundation

enum CardIdentifierError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case noResult
    case jobFailed(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid API URL"
        case .invalidResponse(let code):
            "Server returned status \(code)"
        case .noResult:
            "Job completed with no result"
        case .jobFailed(let message):
            "Identification failed: \(message)"
        case .decodingFailed(let error):
            "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

final class CardIdentifierService: CardIdentifierServiceProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func submitJob(imageData: Data) async throws -> JobSubmitResponse {
        let url = baseURL.appendingPathComponent("identify/async")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "image_base64": imageData.base64EncodedString()
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)

        do {
            return try JSONDecoder().decode(JobSubmitResponse.self, from: data)
        } catch {
            throw CardIdentifierError.decodingFailed(error)
        }
    }

    func checkStatus(jobId: String) async throws -> JobStatusResponse {
        let url = baseURL.appendingPathComponent("status/\(jobId)")
        let (data, response) = try await session.data(from: url)
        try validateHTTPResponse(response)

        do {
            return try JSONDecoder().decode(JobStatusResponse.self, from: data)
        } catch {
            throw CardIdentifierError.decodingFailed(error)
        }
    }

    func fetchPriceHistory(productId: String) async throws -> PriceHistory {
        let url = baseURL.appendingPathComponent("price-history/\(productId)")
        let (data, response) = try await session.data(from: url)
        try validateHTTPResponse(response)

        do {
            return try JSONDecoder().decode(PriceHistory.self, from: data)
        } catch {
            throw CardIdentifierError.decodingFailed(error)
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw CardIdentifierError.invalidResponse(statusCode: http.statusCode)
        }
    }
}
