//
//  SignInProviders.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import Foundation
import AuthenticationServices

enum SignInProvider {
    case apple(credential: ASAuthorizationCredential)
    case google
}
