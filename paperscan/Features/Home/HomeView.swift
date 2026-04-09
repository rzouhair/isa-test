import SwiftUI
import SwiftData
import Inject

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Query(sort: \CardRecord.addedAt, order: .reverse) private var allCards: [CardRecord]

    private var recentCards: [CardRecord] { Array(allCards.prefix(10)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroBanner
                recentSection
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .enableInjection()
    }

    // MARK: - Hero

    private var heroBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.8))

            Text("Identify Your\nCards Instantly")
                .font(.title2.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)

            Button {
                if appState.isProUser {
                    router.presentFullscreenCover(.scanner)
                } else {
                    appState.showPaywall()
                }
            } label: {
                Text("Scan Now")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.summaryGradientDiagonal)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Cards")
                    .font(.headline)
                Spacer()
                if !allCards.isEmpty {
                    Button {
                        router.navigate(to: .collection)
                    } label: {
                        Text("See All")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if recentCards.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.stack")
                        .font(.system(.title))
                        .foregroundStyle(.tertiary)
                    Text("No cards yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Scan your first card to get started")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(recentCards) { card in
                        Button { router.navigate(to: .cardDetail(card)) } label: {
                            CollectionCardRow(card: card)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        if card.id != recentCards.last?.id {
                            Divider().padding(.leading, 78)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                if !allCards.isEmpty {
                    Button {
                        router.navigate(to: .collection)
                    } label: {
                        Text("View All \(allCards.count) Cards")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
    }
}
