import Foundation

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() throws
}

final class AuthService: AuthServiceProtocol {
    func signIn(email: String, password: String) async throws {
        // let result = try await Auth.auth().signIn(withEmail: email, password: password)
        // Handle user data
    }
    
    func signUp(email: String, password: String) async throws {
        // let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Handle user data
    }
    
    func signOut() throws {
        // try Auth.auth().signOut()
    }
} 