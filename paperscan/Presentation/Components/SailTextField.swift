//
//  SailTextField.swift
//  paperscan
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct SailTextField: View {
    @ObserveInjection var inject

    let title: String
    let placeholder: String
    var leftIcon: String?
    var rightIcon: String?
    var error: String?

    @Binding var text: String
    @Binding var disabled: Bool
    @FocusState var isFocused: Bool

    public init(
        title: String,
        placeholder: String,
        leftIcon: String? = nil,
        rightIcon: String? = nil,
        error: String? = nil,
        disabled: Binding<Bool> = .constant(false),
        text: Binding<String>
    ) {
        self.title = title
        self.placeholder = placeholder
        self.leftIcon = leftIcon
        self.rightIcon = rightIcon
        self.error = error
        self._text = text
        self._disabled = disabled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.gray)
                .fixedSize()
            HStack(spacing: 16) {
                if let leftIcon {
                    Image(systemName: leftIcon)
                        .foregroundStyle(disabled ? .gray : Asset.Colors.appPrimary.swiftUIColor)
                }
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .disabled(disabled)
                if let rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundStyle(disabled ? .gray : Asset.Colors.appPrimary.swiftUIColor)
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Asset.Colors.cardBackground.swiftUIColor)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            )
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize()
            }
        }
        .enableInjection()
    }
}

#Preview {
    VStack(spacing: 32) {
        SailTextField(
            title: "Email address with right icon",
            placeholder: "email@address.com",
            rightIcon: "at.circle.fill",
            text: .constant("")
        )
        SailTextField(
            title: "Email address with left icon",
            placeholder: "email@address.com",
            leftIcon: "at.circle.fill",
            text: .constant("")
        )
        SailTextField(
            title: "Email address (disabled)",
            placeholder: "email@address.com",
            rightIcon: "at.circle.fill",
            disabled: .constant(true),
            text: .constant("")
        )
        SailTextField(
            title: "Email address (error)",
            placeholder: "email@address.com",
            rightIcon: "at.circle.fill",
            error: "Email must be in the correct format",
            disabled: .constant(false),
            text: .constant("email@example")
        )
    }
    .padding(16)
}
