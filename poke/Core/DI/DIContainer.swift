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
        baseURL: URL(string: Constants.cardIdentifierBaseURL)!
    )
    lazy var analyticsService: AnalyticsServiceProtocol = PostHogAnalyticsService()
    lazy var crashReportingService: CrashReportingServiceProtocol = SentryCrashReportingService()
    lazy var gradingService: GradingServiceProtocol = GradingService(
        baseURL: URL(string: Constants.cardIdentifierBaseURL)!
    )

    private init() {}
}
