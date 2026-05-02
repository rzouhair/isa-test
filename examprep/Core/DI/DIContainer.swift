import Foundation
import Observation
import SwiftData

final class DIContainer {
    static let shared = DIContainer()

    // Datasources
    lazy var userDefaultsDatasource: UserDefaultsDataSource = UserDefaultsDataSource()

    // Repositories (stateless / singleton-safe)
    lazy var userRepository: UserRepositoryProtocol = UserRepository(
        userDefaultsDatasource: userDefaultsDatasource
    )
    lazy var contentRepository: ContentRepositoryProtocol = GRDBContentRepository()

    // Services
    lazy var analyticsService: AnalyticsServiceProtocol = PostHogAnalyticsService()
    lazy var crashReportingService: CrashReportingServiceProtocol = SentryCrashReportingService()

    private init() {}

    // MARK: Factory helpers (SwiftData-bound, created at use-site)

    @MainActor
    func userProgressRepository(context: ModelContext) -> UserProgressRepositoryProtocol {
        SwiftDataUserProgressRepository(context: context)
    }

    @MainActor
    func statsRepository(context: ModelContext) -> StatsRepositoryProtocol {
        DefaultStatsRepository(
            content: contentRepository,
            progress: userProgressRepository(context: context)
        )
    }

    // MARK: URL helper

    /// Parses a URL string or returns an invalid sentinel. Network calls against
    /// the sentinel fail loudly rather than crashing at startup.
    static func safeURL(_ string: String, context: String) -> URL {
        if let url = URL(string: string), !string.isEmpty {
            return url
        }
        SentryCrashReportingService().captureMessage(
            "DIContainer.safeURL failed for \(context): '\(string)'"
        )
        return URL(string: "https://invalid.local")!
    }
}
