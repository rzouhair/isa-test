//
//  File.swift
//  
//
//  Created by user on 03/07/2023.
//

import Foundation

class OnboardingDependencies {

    let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
}
