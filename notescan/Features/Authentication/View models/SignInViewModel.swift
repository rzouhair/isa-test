//
//  SignInViewModel.swift
//  notescan
//
//  Created by user on 06/03/2024.
//

import Foundation
import AuthenticationServices
import SwiftUI

extension SignInView {
    class ViewModel {

        enum Event {
            case signInSuccessful
        }
        
        var userRepository: UserRepositoryProtocol {
            DIContainer.shared.userRepository
        }

        let onEvent: (Event) -> ()

        init(
            onEvent: @escaping (Event) -> ()
        ) {
            self.onEvent = onEvent
        }
        
        func onSignInWithGoogleButtonTap() async {
            let result = (try? await userRepository.signIn(provider: .google)) ?? false
            guard result else {
                // TODO: Show error alert
                return
            }
            await MainActor.run {
                onEvent(.signInSuccessful)
            }
        }

        func onSignInWithAppleButtonCompletion(result: Result<ASAuthorization, Error>) {
            switch result {
            case .success(let success):
                Task {
                    
                    let result = (try? await userRepository.signIn(provider: .apple(credential: success.credential))) ?? false
                    guard result else {
                        // TODO: Show error alert
                        return
                    }
                    await MainActor.run {
                        onEvent(.signInSuccessful)
                    }
                }
            case .failure(let failure):
                // TODO: Show error alert
                print("Something went wrong: \(failure.localizedDescription)")
            }
        }
}
}

