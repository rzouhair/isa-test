//
//  OnboardingPageConfig.swift
//  
//
//  Created by user on 30/06/2023.
//

import SwiftUI

struct OnboardingPageConfig {

    let index: Int
    let title: String
    let description: String
    let image: Image
}

extension OnboardingPageConfig: Identifiable {

    var id: Int { index + 1 }
}

extension OnboardingPageConfig {

    static var page1: Self {
        .init(
            index: 0,
            title: "Perfect Paywall",
            description: "Avoid creating a wheel. Use proven strategies and techniques. This paywall just works. It contains everything you need to optimize for higer revenue. It's also compliant with Apple Review Guidelines.",
            image: Asset.Images.onboarding1.swiftUIImage
        )
    }

    static var page2: Self {
        .init(
            index: 1,
            title: "UI Components",
            description: "Use predefined UI components to keep your UI consistent with the rest of the app. Customize the existing components and add new ones.",
            image: Asset.Images.onboarding2.swiftUIImage
        )
    }

    static var page3: Self {
        .init(
            index: 2,
            title: "Clean architecture",
            description: "notescan is built on top of the clean architecture principles. It follows the best practices of software engineering and it's easily testable and scalable.",
            image: Asset.Images.onboarding3.swiftUIImage
        )
    }

    static var allPages: [OnboardingPageConfig] = [
        .page1,
        .page2,
        .page3
    ]
}
