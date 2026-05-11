//
//  Card.swift
//  isaprep
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct Card<Content: View>: View {
    @ObserveInjection var inject

    let title: String
    var icon: String?
    var description: String?
    var spacing: CGFloat?
    var cardContent: Content?

    init(
        title: String = "Card Title",
        icon: String? = nil,
        description: String? = nil,
        spacing: CGFloat? = nil,
        @ViewBuilder cardContent: (() -> Content)
    ) {
        self.title = title
        self.icon = icon
        self.description = description
        self.spacing = spacing
        self.cardContent = cardContent()
    }

    init(
        title: String = "Card Title",
         icon: String? = nil,
         description: String? = nil,
         spacing: CGFloat? = nil
    ) where Content == EmptyView {
        self.init(title: title, icon: icon, description: description, spacing: spacing) {
            EmptyView()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(theme.accent)
                    }
                    Text(title)
                    Spacer()
                }
                if let description {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
            }
            if !(cardContent is EmptyView) {
                VStack(alignment: .leading, spacing: spacing) {
                    cardContent
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.cardBackground.swiftUIColor)
                .shadow(color: .black.opacity(0.1), radius: 8)
        )
        .enableInjection()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            Card(
                title: "Create account",
                description: "Fill out this form to create account",
                spacing: 16
            ) {
                SailTextField(
                    title: "Email address",
                    placeholder: "email@example.com",
                    rightIcon: "at.circle.fill",
                    text: .constant("")
                )
                SailTextField(
                    title: "Password",
                    placeholder: "Create password...",
                    rightIcon: "lock.circle.fill",
                    text: .constant("")
                )
                SailTextField(
                    title: "Confirm password",
                    placeholder: "Confirm password...",
                    rightIcon: "checkmark.circle.fill",
                    text: .constant("")
                )
                SailButton(
                    action: {
                        // Action...
                    },
                    icon: Image(systemName: "checkmark.circle.fill"),
                    title: "Create account"
                )
            }
            Card(
                title: "Notifications",
                description: "You have 3 unread messages.",
                spacing: 16
            ) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading) {
                        Text("Your payment was successfull!")
                        Text("32 minutes ago")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading) {
                        Text("You have received a new message.")
                        Text("1 hour ago")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading) {
                        Text("Your account was created!")
                        Text("2 days ago")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                }
            }
            Card(
                title: "Notifications",
                icon: "checkmark.circle.fill",
                description: "No new notifications..."
            )
        }
        .padding(16)
    }
}
