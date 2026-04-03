//
//  TrialBottomStripView.swift
//  paperscan
//

import SwiftUI
import Inject

struct TrialBottomStripView: View {
    @ObserveInjection var inject
    let ctaLabel: String
    let legal: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            VStack(spacing: 10) {
                // NO PAYMENT DUE NOW badge
                HStack(spacing: 6) {
                    Text("\u{1F6E1}")
                        .font(.system(size: 13))
                    Text("NO PAYMENT DUE NOW")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.22)
                        .foregroundColor(KashColors.green100)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                // CTA button
                Button(action: action) {
                    Text(ctaLabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(KashColors.green900)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(KashColors.green400)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())

                // Legal text
                Text(legal)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(KashColors.green900)
        .enableInjection()
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        Spacer()
        TrialBottomStripView(
            ctaLabel: "Try for $0.00",
            legal: "7 days free, then $19.99/year ($1.67/mo)",
            action: {}
        )
    }
    .background(KashColors.green900)
}
