import Foundation
import Observation

final class DIContainer {
    static let shared = DIContainer()
    
    // Datasources
    lazy var userDefaultsDatasource: UserDefaultsDataSource = UserDefaultsDataSource()
    
    // Services
    lazy var authService: AuthServiceProtocol = AuthService()
    
    // Repositories
    lazy var userRepository: UserRepositoryProtocol = UserRepository(
        userDefaultsDatasource: userDefaultsDatasource
    )

    // Stores
    lazy var authStore: AuthStore = AuthStore(authService: authService)
    // lazy var paymentStore: PaymentStore = PaymentStore(paymentService: paymentService)
    
    private init() {}
} 
