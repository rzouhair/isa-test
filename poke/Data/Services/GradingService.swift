import Foundation

enum GradingError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid grading API URL"
        case .invalidResponse(let code):
            "Server returned status \(code)"
        case .decodingFailed(let error):
            "Failed to decode grade response: \(error.localizedDescription)"
        case .serverError(let message):
            "Grading failed: \(message)"
        }
    }
}

final class GradingService: GradingServiceProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func submitGrade(request: GradeRequest) async throws -> GradeResponse {
        let url = baseURL.appendingPathComponent("grade")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw GradingError.invalidResponse(statusCode: -1)
        }
        guard (200...299).contains(http.statusCode) else {
            // Try to extract error message from response body
            if let body = String(data: data, encoding: .utf8) {
                throw GradingError.serverError(body)
            }
            throw GradingError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(GradeResponse.self, from: data)
        } catch {
            throw GradingError.decodingFailed(error)
        }
    }
}
