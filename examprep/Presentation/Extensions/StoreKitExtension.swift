//
//  StoreKitExtension.swift
//  isaprep
//
//  Created by user on 23/03/2024.
//

import Foundation
import StoreKit

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            requestReview(in: scene)
        }
    }
}
