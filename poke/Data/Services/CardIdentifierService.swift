import Foundation
import OSLog

private let log = Logger(subsystem: "com.poke.app", category: "CardIdentifierService")

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
        #if DEBUG
        log.debug("submitJob POST \(url.absoluteString, privacy: .public) imageBytes=\(imageData.count)")
        #endif
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "image_base64": imageData.base64EncodedString()
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        #if DEBUG
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
        log.debug("submitJob response status=\(statusCode) body=\(rawBody, privacy: .public)")
        #endif
        try validateHTTPResponse(response)

        do {
            let decoded = try JSONDecoder().decode(JobSubmitResponse.self, from: data)
            #if DEBUG
            log.info("submitJob decoded jobId=\(decoded.jobId, privacy: .public) status=\(decoded.status, privacy: .public)")
            #endif
            return decoded
        } catch {
            #if DEBUG
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            log.error("submitJob decode failed: \(error.localizedDescription, privacy: .public) body=\(body, privacy: .public)")
            #endif
            throw CardIdentifierError.decodingFailed(error)
        }
    }

    func checkStatus(jobId: String) async throws -> JobStatusResponse {
        let url = baseURL.appendingPathComponent("status/\(jobId)")
        #if DEBUG
        log.debug("checkStatus GET \(url.absoluteString, privacy: .public) jobId=\(jobId, privacy: .public)")
        #endif
        let (data, response) = try await session.data(from: url)
        #if DEBUG
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
        log.info("checkStatus response status=\(statusCode) jobId=\(jobId, privacy: .public) body=\(rawBody, privacy: .public)")
        #endif
        try validateHTTPResponse(response)

        do {
            let decoded = try JSONDecoder().decode(JobStatusResponse.self, from: data)
            #if DEBUG
            log.info("checkStatus decoded jobId=\(decoded.jobId, privacy: .public) status=\(decoded.status, privacy: .public) hasResult=\(decoded.result != nil) error=\(decoded.error ?? "nil", privacy: .public)")
            #endif
            return decoded
        } catch {
            #if DEBUG
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            log.error("checkStatus decode failed jobId=\(jobId, privacy: .public): \(error.localizedDescription, privacy: .public) body=\(body, privacy: .public)")
            #endif
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
