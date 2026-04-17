import SwiftUI
import Inject

struct OnboardingPortfolioView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var portfolioValue: Double = 0
    @State private var cardCount: Int = 0
    @State private var gridReveals: [Bool] = Array(repeating: false, count: 6)
    @State private var showTotal = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("YOUR COLLECTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Your binder, but\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("smarter.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Organize cards into collections and always know what your portfolio is worth.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Portfolio value card
                portfolioCard
                    .padding(.bottom, 20)

                // Mini card grid
                cardGrid
                    .padding(.bottom, 20)

                // Feature rows
                featureRow(
                    icon: "folder.fill",
                    iconColor: theme.accentBright,
                    title: "Multiple collections",
                    subtitle: "Group cards by set, game, or however you like."
                )
                .padding(.bottom, 12)

                featureRow(
                    icon: "chart.pie.fill",
                    iconColor: theme.accentWarm,
                    title: "Portfolio insights",
                    subtitle: "See total value, card count, and how many sets you own."
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

            // Grid cards reveal
            for i in 0..<6 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.12)) {
                    gridReveals[i] = true
                }
            }

            // Portfolio value counter
            withAnimation(.easeOut(duration: 1.8).delay(0.6)) {
                portfolioValue = 1842
            }

            // Card count
            withAnimation(.easeOut(duration: 1.2).delay(0.8)) {
                cardCount = 47
            }

            // Ring progress
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                ringProgress = 0.72
            }

            // Show total label
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(2.0)) {
                showTotal = true
            }
        }
        .enableInjection()
    }

    // MARK: - Portfolio Value Card

    private var portfolioCard: some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [theme.ctaFill, theme.accentBright],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(cardCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("cards")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio Value")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))

                Text(String(format: "$%.0f", portfolioValue))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())

                if showTotal {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("Growing as you scan")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(theme.accentBright)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            Spacer()
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

    // MARK: - Card Grid

    private let gridCardNames = [
        ("Charizard EX", "$328"),
        ("Pikachu V", "$45"),
        ("Mewtwo GX", "$62"),
        ("Lugia V", "$38"),
        ("Umbreon V", "$95"),
        ("Rayquaza V", "$72"),
    ]

    private var cardGrid: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Collection")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if gridReveals.allSatisfy({ $0 }) {
                    Text("\(gridReveals.count) cards")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.accentBright)
                        .transition(.opacity)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    gridCard(name: gridCardNames[i].0, price: gridCardNames[i].1, revealed: gridReveals[i])
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: isAnimating)
    }

    private func gridCard(name: String, price: String, revealed: Bool) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(theme.onboardingCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(
                            revealed ? theme.accentBright.opacity(0.2) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
                .frame(height: 62)
                .overlay(
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.15))
                )

            Text(name)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(price)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(theme.accentWarm)
        }
        .opacity(revealed ? 1 : 0.2)
        .scaleEffect(revealed ? 1 : 0.8)
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
        OnboardingPortfolioView()
    }
}
