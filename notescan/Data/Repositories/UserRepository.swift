//
//  UserRepository.swift
//  notescan
//
//  Created by user on 06/03/2024.
//

import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

class UserRepository: UserRepositoryProtocol {

    let userDefaultsDatasource: UserDefaultsDataSource

    public init(
        userDefaultsDatasource: UserDefaultsDataSource
    ) {
        self.userDefaultsDatasource = userDefaultsDatasource
    }

    func isUserLoggedIn() -> Bool {
        Auth.auth().currentUser != nil
    }
    
    func onboardingIsFinished() -> Bool {
        userDefaultsDatasource.get(.onboardingFinished) ?? false
    }
    
    func setOnboardingIsFinished() {
        userDefaultsDatasource.set(.onboardingFinished, value: true)
    }

    func signIn(provider: SignInProvider) async throws -> Bool {
        switch provider {
        case .apple(let credential):
            return await signInWithApple(credential: credential)
        case .google:
            return await signInWithGoogle()
        }
    }

    func deleteAccount() {
        Auth.auth().currentUser?.delete()
    }

    private func signInWithApple(credential: ASAuthorizationCredential) async -> Bool {
        guard let credential = credential as? ASAuthorizationAppleIDCredential,
              let appleIdToken = credential.identityToken
        else { return false }
        guard let idTokenString = String(data: appleIdToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIdToken.debugDescription)")
            return false
        }
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nil,
            fullName: credential.fullName
        )
        do {
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            print("User signed in: \(result.user.email ?? "")")
            return true
        } catch let error {
            print(error)
            return false
        }
    }

    private func signInWithGoogle() async -> Bool {
        guard let clientId = FirebaseApp.app()?.options.clientID,
              let topViewController = await UIApplication.topViewController()
        else { return false }
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)
            guard let idToken = result.user.idToken?.tokenString else { return false }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            print("User signed in: \(authResult.user.email ?? "")")
            return true
        } catch let error {
            print(error)
            return false
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
