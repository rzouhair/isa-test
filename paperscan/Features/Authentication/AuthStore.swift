import Foundation

@Observable final class AuthStore {
    private let authService: AuthServiceProtocol
    
    var isAuthenticated = false
    var isLoading = false
    var error: Error?
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
            error = nil
        } catch {
            self.error = error
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // Add other auth methods...
} 