//
//  OnboardingSocialProofView.swift
//  poke
//
//  Screen 2: Social Proof — reviews, ratings, and trust signals
//  to prime the user before camera permission + trial close.
//

import SwiftUI
import Inject

struct OnboardingSocialProofView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false

    private let miniReviews: [(quote: String, name: String)] = [
        ("Found three rare cards worth over $100 each in my old collection!", "Sarah K."),
        ("Best card scanner out there. Instant ID, real market prices.", "Mike R."),
        ("Finally know what my childhood Pokémon cards are actually worth.", "Alex T."),
        ("The rarity ratings are spot on. Use it before every purchase.", "Chris L."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("TRUSTED WORLDWIDE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Trusted by Collectors\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("Worldwide")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 12)

                Text("Join thousands who rely on Poke to identify and value their cards.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(3)
                    .padding(.bottom, 28)

                // Featured review card
                featuredReview
                    .padding(.bottom, 16)

                // Mini reviews scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(miniReviews, id: \.name) { review in
                            miniReviewCard(quote: review.quote, name: review.name)
                        }
                    }
                }
                .padding(.bottom, 24)

                // Stats bar
                statsBar
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .enableInjection()
    }

    // MARK: - Featured Review

    private var featuredReview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accentWarm)
                }
            }

            Text("\"Been collecting cards for 15 years. This app identified a rare holo I had sitting in a binder — turns out it was worth over $300. Incredible tool.\"")
                .font(.system(size: 14))
                .italic()
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(3)

            HStack(spacing: 8) {
                Text("— James M.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Text("Verified Collector")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: isAnimating)
    }

    // MARK: - Mini Review Card

    private func miniReviewCard(quote: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(theme.accentWarm)
                }
            }

            Text("\"\(quote)\"")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
                .lineLimit(3)

            Spacer()

            Text("— \(name)")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .frame(width: 240, alignment: .leading)
        .frame(minHeight: 130)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statItem(icon: "star.fill", value: "4.8", label: "Rating")
            Spacer()
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 3, height: 3)
            Spacer()
            statItem(icon: "viewfinder", value: "50K+", label: "Scans")
            Spacer()
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 3, height: 3)
            Spacer()
            statItem(icon: "globe", value: "150+", label: "Countries")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.accentBright)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingSocialProofView()
    }
}
