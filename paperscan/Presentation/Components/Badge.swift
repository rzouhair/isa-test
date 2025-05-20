//
//  Badge.swift
//  paperscan
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct Badge: View {
    @ObserveInjection var inject

    enum BadgeStyle {
        case primary
        case secondary
        case outline
        case destructive
    }

    var style: BadgeStyle = .primary
    let text: String

    var body: some View {
        Text(text)
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .font(.defaultText.regular)
            .foregroundStyle(textColor)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .background(
                        Capsule()
                            .stroke(style == .outline ? Asset.Colors.appPrimary.swiftUIColor : .clear, style: .init())
                    )
            )
        .enableInjection()
    }

    var backgroundColor: Color {
        switch style {
        case .primary: return Asset.Colors.appPrimary.swiftUIColor
        case .secondary: return .secondary
        case .outline: return .clear
        case .destructive: return .red
        }
    }

    var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .white
        case .outline: return Asset.Colors.appPrimary.swiftUIColor
        case .destructive: return .white
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Badge(style: .primary, text: "Primary")
        Badge(style: .secondary, text: "Secondary")
        Badge(style: .outline, text: "Outline")
        Badge(style: .destructive, text: "Destructive")
    }
}
