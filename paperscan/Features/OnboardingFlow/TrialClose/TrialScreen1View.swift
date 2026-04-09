//
//  TrialScreen1View.swift
//  paperscan
//

import SwiftUI
import Inject
struct TrialScreen1View: View {
    @ObserveInjection var inject
    var legalText: String
    var onContinue: () -> Void
    var onRestore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top bar - Restore only
            HStack {
                Spacer()
                Button(action: onRestore) {
                    Text("Restore")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)

            Spacer()

            // Content
            VStack(spacing: 0) {
                // Eyebrow
                Text("THE #1 CARD VALUE APP")
                    .font(.system(size: 12, weight: .bold))
                    .kerning(1.8)
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.bottom, 14)

                // Headline
                VStack(spacing: 4) {
                    Text("We want you to")
                        .font(.system(size: 34))
                        .foregroundColor(.white)

                    Text("try PaperScan for free")
                        .font(.system(size: 34, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(theme.accentBright)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

                // App preview cards
                AppPreviewCardsView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
            }
            .padding(.horizontal, 28)

            Spacer()

            // Bottom strip
            TrialBottomStripView(
                ctaLabel: "Try for $0.00",
                legal: legalText,
                action: onContinue
            )
        }
        .background(theme.onboardingBg)
        .onAppear {
            // Analytics: trial_close_screen_1_viewed
        }
        .enableInjection()
    }
}

#Preview {
    TrialScreen1View(legalText: "3-day free trial, then $4.99/week", onContinue: {}, onRestore: {})
}
