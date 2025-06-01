//
//  UserRepository.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import AuthenticationServices

class UserRepository: UserRepositoryProtocol {

  let userDefaultsDatasource: UserDefaultsDataSource

  public init(
    userDefaultsDatasource: UserDefaultsDataSource
  ) {
    self.userDefaultsDatasource = userDefaultsDatasource
  }

  func onboardingIsFinished() -> Bool {
    userDefaultsDatasource.get(.onboardingFinished) ?? false
  }

  func setOnboardingIsFinished() {
    userDefaultsDatasource.set(.onboardingFinished, value: true)
  }

  func wasReviewPrompted() -> Bool {
    userDefaultsDatasource.get(.reviewPrompted) ?? false
  }

  func setReviewPrompted() {
    userDefaultsDatasource.set(.reviewPrompted, value: true)
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

}
