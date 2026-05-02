//
//  UserRepository.swift
//  examprep
//
//  Created by user on 06/03/2024.
//

import Foundation

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

}
