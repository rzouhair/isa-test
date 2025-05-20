//
//  UserRepositoryProtocol.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import Foundation

protocol UserRepositoryProtocol {
    func isUserLoggedIn() -> Bool
    func onboardingIsFinished() -> Bool
    func setOnboardingIsFinished()
    func signIn(provider: SignInProvider) async throws -> Bool
    func signOut()
    func deleteAccount()
    func wasReviewPrompted() -> Bool
    func setReviewPrompted()
}
