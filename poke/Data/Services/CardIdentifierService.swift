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
        let body: [String: String] = [
            "image_base64": imageData.base64EncodedString()
        ]
        var mutableRequest = URLRequest(url: url, timeoutInterval: 120)
        mutableRequest.httpMethod = "POST"
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableRequest.httpBody = try JSONEncoder().encode(body)
        let request = mutableRequest

        let (data, response) = try await performWithRetry { try await self.session.data(for: request) }
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
        var mutableRequest = URLRequest(url: url, timeoutInterval: 30)
        mutableRequest.httpMethod = "GET"
        let request = mutableRequest
        let (data, response) = try await performWithRetry { try await self.session.data(for: request) }
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
        var mutableRequest = URLRequest(url: url, timeoutInterval: 30)
        mutableRequest.httpMethod = "GET"
        let request = mutableRequest
        let (data, response) = try await performWithRetry { try await self.session.data(for: request) }
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

    /// Retries on transient failures (429, 5xx, URLError timeouts/network loss).
    /// Exponential backoff: 0.5s → 1s → 2s. Does NOT retry 4xx (except 429).
    private func performWithRetry(
        attempts: Int = 3,
        _ block: @Sendable () async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0..<attempts {
            do {
                let (data, response) = try await block()
                if let http = response as? HTTPURLResponse,
                   http.statusCode == 429 || (500...599).contains(http.statusCode),
                   attempt < attempts - 1 {
                    try await Task.sleep(for: .milliseconds(500 * Int(pow(2.0, Double(attempt)))))
                    continue
                }
                return (data, response)
            } catch let error as URLError where isTransient(error) && attempt < attempts - 1 {
                lastError = error
                try await Task.sleep(for: .milliseconds(500 * Int(pow(2.0, Double(attempt)))))
            } catch {
                throw error
            }
        }
        throw lastError ?? CardIdentifierError.invalidResponse(statusCode: -1)
    }

    private func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed, .cannotFindHost:
            return true
        default:
            return false
        }
    }
}
