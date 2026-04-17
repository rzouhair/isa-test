//
//  UserRepositoryProtocol.swift
//  poke
//
//  Created by user on 06/03/2024.
//

import Foundation

protocol UserRepositoryProtocol {
    func onboardingIsFinished() -> Bool
    func setOnboardingIsFinished()
    func wasReviewPrompted() -> Bool
    func setReviewPrompted()
}
