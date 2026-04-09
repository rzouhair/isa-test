import Foundation

@MainActor @Observable
final class ScanCorrectionViewModel {
    enum LoadState {
        case loading
        case loaded([Candidate])
        case expired   // job TTL elapsed, no candidates
        case failed(String)
    }

    var loadState: LoadState = .loading
    var selectedProductId: String?

    private let service: CardIdentifierServiceProtocol = DIContainer.shared.cardIdentifierService

    func load(jobId: String) async {
        loadState = .loading
        do {
            let status = try await service.checkStatus(jobId: jobId)
            let candidates = status.result?.metadata?.candidates ?? []
            if candidates.isEmpty {
                loadState = .expired
            } else {
                selectedProductId = candidates.first?.productId
                loadState = .loaded(candidates)
            }
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
