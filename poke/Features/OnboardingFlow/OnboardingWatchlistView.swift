import SwiftUI
import Inject

struct OnboardingWatchlistView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var priceValue: Double = 0
    @State private var showChange = false
    @State private var notifScale: CGFloat = 0
    @State private var cardReveals: [Bool] = [false, false, false]
    @State private var pulseOpacity: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("PRICE TRACKING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Never miss a\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("price move.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Add cards to your watchlist and track market value changes over time.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Watchlist card animation
                watchlistDemo
                    .padding(.bottom, 20)

                // Notification card
                notificationCard
                    .padding(.bottom, 16)

                // Feature rows
                featureRow(
                    icon: "eye.fill",
                    iconColor: theme.accentBright,
                    title: "Watch any card",
                    subtitle: "One tap to add a card to your watchlist from any screen."
                )
                .padding(.bottom, 12)

                featureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: theme.accentWarm,
                    title: "Price history",
                    subtitle: "See how a card's value has changed over weeks and months."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }

            // Cards reveal
            for i in 0..<3 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.2)) {
                    cardReveals[i] = true
                }
            }

            // Price counter
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                priceValue = 328.50
            }

            // Price change badge
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(1.8)) {
                showChange = true
            }

            // Notification pop
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(2.2)) {
                notifScale = 1
            }

            // Pulse loop
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(2.5)) {
                pulseOpacity = 0.6
            }
        }
        .enableInjection()
    }

    // MARK: - Watchlist Demo

    private var watchlistDemo: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Watchlist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 11))
                        .foregroundColor(theme.accentBright)
                    Text("3 cards")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.accentBright)
                }
                .opacity(cardReveals.allSatisfy({ $0 }) ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: cardReveals)
            }

            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    watchlistRow(
                        name: ["Charizard EX", "Pikachu VMAX", "Mewtwo V"][i],
                        set: ["Scarlet & Violet", "Vivid Voltage", "Pokémon GO"][i],
                        price: ["$328.50", "$89.00", "$45.00"][i],
                        change: ["+12.4%", "+3.2%", "-1.8%"][i],
                        isUp: [true, true, false][i],
                        revealed: cardReveals[i]
                    )
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: isAnimating)
    }

    private func watchlistRow(name: String, set: String, price: String, change: String, isUp: Bool, revealed: Bool) -> some View {
        HStack(spacing: 10) {
            // Mini card placeholder
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(theme.onboardingCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(theme.accentBright.opacity(0.15), lineWidth: 1)
                )
                .frame(width: 32, height: 44)
                .overlay(
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(set)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accentWarm)

                if showChange {
                    Text(change)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(isUp ? theme.accentBright : Color(.systemRed).opacity(0.8))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    revealed ? theme.accentBright.opacity(0.15) : Color.white.opacity(0.04),
                    lineWidth: 1
                )
        )
        .opacity(revealed ? 1 : 0.3)
        .offset(x: revealed ? 0 : 30)
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accentBright.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.accentBright)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(theme.accentBright, Color(.systemRed))
            }
            .scaleEffect(notifScale)

            VStack(alignment: .leading, spacing: 2) {
                Text("Charizard EX price is up!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("Now $328.50 (+12.4% this week)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .opacity(notifScale > 0 ? 1 : 0)

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    notifScale > 0 ? theme.accentBright.opacity(0.2) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            // Pulse ring
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.accentBright.opacity(pulseOpacity), lineWidth: 1.5)
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingWatchlistView()
    }
}
