//
//  TrialScreen2View.swift
//  isaprep
//

import SwiftUI
import Inject
struct TrialScreen2View: View {
    @ObserveInjection var inject
    var legalText: String
    var trialDays: String
    var onBack: () -> Void
    var onOpenPaywall: () -> Void
    var onRestore: () -> Void

    @State private var bellRotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top bar - Back + Restore
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }

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

            // Bell with badge
            ZStack(alignment: .topTrailing) {
                Text("\u{1F514}")
                    .font(.system(size: 90))
                    .rotationEffect(.degrees(bellRotation), anchor: .top)

                // Notification badge
                Text("1")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(hex: "E84040"))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.onboardingBg, lineWidth: 2)
                    )
                    .shadow(color: Color(hex: "E84040").opacity(0.3), radius: 4, y: 0)
                    .offset(x: 4, y: -4)
            }
            .padding(.bottom, 32)
            .onAppear {
                startBellRing()
            }

            // Headline
            VStack(spacing: 4) {
                Text("We'll remind you")
                Text("before your free")
                Text("trial ends")
            }
            .font(.system(size: 34))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 36)
            .padding(.bottom, 14)

            // Body copy
            bodyText
                .padding(.horizontal, 36)

            Spacer()

            // Bottom strip
            TrialBottomStripView(
                ctaLabel: "Continue for free",
                legal: legalText,
                action: {
                    DIContainer.shared.analyticsService.capture(.trialCloseScreen2Tapped)
                    onOpenPaywall()
                }
            )
        }
        .background(theme.onboardingBg)
        .onAppear {
            DIContainer.shared.analyticsService.capture(.trialCloseScreen2Viewed)
        }
        .enableInjection()
    }

    private var reminderDay: String {
        guard let days = Int(trialDays), days > 1 else { return "Day 2" }
        return "Day \(days - 1)"
    }

    private var cancelDay: String {
        guard let days = Int(trialDays) else { return "Day 3" }
        return "Day \(days)"
    }

    private var bodyText: some View {
        let base = "You'll get a notification on \(reminderDay) so you're never surprised. Cancel anytime before \(cancelDay) — no charge, no questions."

        var attributed = AttributedString(base)
        if let range = attributed.range(of: reminderDay) {
            attributed[range].font = .system(size: 16, weight: .bold)
        }

        return Text(attributed)
            .font(.system(size: 16, weight: .light))
            .foregroundColor(Color.white.opacity(0.55))
            .lineSpacing(3)
            .multilineTextAlignment(.center)
    }

    private func startBellRing() {
        let angles: [Double] = [0, -10, 10, -8, 8, -5, 5, 0]
        var delay = 0.0
        for angle in angles {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.08)) {
                    bellRotation = angle
                }
            }
            delay += 0.09
        }
        // Repeat after pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            startBellRing()
        }
    }
}

#Preview {
    TrialScreen2View(legalText: "3-day free trial, then $4.99/week", trialDays: "3", onBack: {}, onOpenPaywall: {}, onRestore: {})
}
