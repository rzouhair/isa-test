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

    private init() {}
}
