import Foundation

protocol CardIdentifierServiceProtocol: Sendable {
    func submitJob(imageData: Data) async throws -> JobSubmitResponse
    func checkStatus(jobId: String) async throws -> JobStatusResponse
    func fetchPriceHistory(productId: String) async throws -> PriceHistory
}
