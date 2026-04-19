import Foundation
import Observation

final class DIContainer {
    static let shared = DIContainer()

    // Datasources
    lazy var userDefaultsDatasource: UserDefaultsDataSource = UserDefaultsDataSource()

    // Repositories
    lazy var userRepository: UserRepositoryProtocol = UserRepository(
        userDefaultsDatasource: userDefaultsDatasource
    )

    // Services
    lazy var cardIdentifierService: CardIdentifierServiceProtocol = CardIdentifierService(
        baseURL: DIContainer.safeURL(
            Constants.cardIdentifierBaseURL,
            context: "cardIdentifierBaseURL"
        )
    )
    lazy var analyticsService: AnalyticsServiceProtocol = PostHogAnalyticsService()
    lazy var crashReportingService: CrashReportingServiceProtocol = SentryCrashReportingService()
    lazy var gradingService: GradingServiceProtocol = GradingService(
        baseURL: DIContainer.safeURL(
            Constants.cardIdentifierBaseURL,
            context: "gradingServiceBaseURL"
        )
    )

    private init() {}

    /// Parses a URL string or returns an invalid sentinel, reporting misconfigurations to Sentry.
    /// Network calls hitting the sentinel will fail loudly instead of crashing at startup.
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
