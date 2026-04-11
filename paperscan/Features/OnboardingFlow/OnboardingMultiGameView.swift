import SwiftUI
import Inject

struct OnboardingMultiGameView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var gameReveals: [Bool] = Array(repeating: false, count: 4)
    @State private var activeGame: Int = 0
    @State private var cardFlip: Bool = false

    private let games: [(icon: String, name: String, example: String, price: String)] = [
        ("flame.fill", "Pokemon", "Charizard EX", "$328.50"),
        ("wand.and.stars", "Magic: The Gathering", "Black Lotus", "$520,000"),
        ("bolt.fill", "Yu-Gi-Oh!", "Blue-Eyes White Dragon", "$425.00"),
        ("trophy.fill", "Sports Cards", "Shohei Ohtani RC", "$1,200"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("EVERY GAME")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("One app for\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("every card.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Pokemon, Magic, Yu-Gi-Oh!, sports cards — all identified and valued instantly.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Active card showcase
                cardShowcase
                    .padding(.bottom, 20)

                // Game selector grid
                gameGrid
                    .padding(.bottom, 20)

                // Feature row
                featureRow(
                    icon: "viewfinder",
                    iconColor: theme.accentBright,
                    title: "Universal scanner",
                    subtitle: "Point at any card — our AI detects the game automatically."
                )
                .padding(.bottom, 12)

                featureRow(
                    icon: "dollarsign.arrow.circlepath",
                    iconColor: theme.accentWarm,
                    title: "Real market prices",
                    subtitle: "Accurate pricing from TCGPlayer across all supported games."
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

            // Games reveal sequentially
            for i in 0..<4 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.3 + Double(i) * 0.15)) {
                    gameReveals[i] = true
                }
            }

            // Cycle through games
            startGameCycle()
        }
        .enableInjection()
    }

    private func startGameCycle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            cycleThroughGames()
        }
    }

    private func cycleThroughGames() {
        let nextGame = (activeGame + 1) % games.count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cardFlip = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            activeGame = nextGame
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardFlip = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            cycleThroughGames()
        }
    }

    // MARK: - Card Showcase

    private var cardShowcase: some View {
        let game = games[activeGame]

        return VStack(spacing: 14) {
            // Card visual
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.onboardingCardBg)
                    .frame(width: 140, height: 196)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(theme.accentBright.opacity(0.25), lineWidth: 1.5)
                    )

                VStack(spacing: 8) {
                    Image(systemName: game.icon)
                        .font(.system(size: 28))
                        .foregroundColor(theme.accentBright)

                    Text(game.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)

                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 60, height: 1)

                    Text(game.example)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    Text(game.price)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(theme.accentWarm)
                }
            }
            .rotation3DEffect(.degrees(cardFlip ? 90 : 0), axis: (x: 0, y: 1, z: 0))
            .shadow(color: theme.accentBright.opacity(0.15), radius: 16, y: 6)

            // Game name label
            Text(game.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .opacity(cardFlip ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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

    // MARK: - Game Grid

    private let gameColors: [Color] = [
        Color(.systemRed),
        Color(.systemBlue),
        Color(.systemPurple),
        Color(.systemOrange),
    ]

    private var gameGrid: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Supported Games")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    gameCell(
                        icon: games[i].icon,
                        name: games[i].name,
                        color: gameColors[i],
                        isActive: activeGame == i,
                        revealed: gameReveals[i]
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    private func gameCell(icon: String, name: String, color: Color, isActive: Bool, revealed: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            if isActive {
                Circle()
                    .fill(theme.accentBright)
                    .frame(width: 6, height: 6)
                    .transition(.scale)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isActive ? theme.accentBright.opacity(0.3) : Color.white.opacity(0.06),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .opacity(revealed ? 1 : 0.3)
        .scaleEffect(revealed ? 1 : 0.9)
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
        OnboardingMultiGameView()
    }
}
