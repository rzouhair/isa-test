import SwiftUI
import SwiftData
import Inject

struct CollectionsGridView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Query(sort: \CardCollection.updatedAt, order: .reverse) private var collections: [CardCollection]
    @Query private var allCards: [CardRecord]

    @State private var showCreate = false
    @State private var searchText = ""
    @State private var cachedTotalValue: Double = 0
    @State private var cachedDistinctSets: Int = 0
    @State private var cachedCardCount: Int = 0

    private var totalValue: Double { cachedTotalValue }

    private var filteredCollections: [CardCollection] {
        guard !searchText.isEmpty else { return collections }
        let query = searchText.lowercased()
        return collections.filter { $0.name.lowercased().contains(query) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                allCardsSummary
                collectionsGrid
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search collections")
        .task(id: allCards.count) {
            let cards = allCards
            let (value, sets, count) = await Task.detached(priority: .userInitiated) {
                let v = cards.reduce(0.0) { $0 + $1.tcgplayerPrice }
                let s = Set(cards.map(\.setName)).subtracting([""]).count
                return (v, s, cards.count)
            }.value
            cachedTotalValue = value
            cachedDistinctSets = sets
            cachedCardCount = count
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                CreateCollectionView { collection in
                    router.navigate(to: .collectionDetail(collection))
                }
            }
        }
        .enableInjection()
    }

    // MARK: - All Cards Summary

    private var distinctSets: Int { cachedDistinctSets }

    private var allCardsSummary: some View {
        VStack(spacing: 0) {
            // Row 1: Portfolio value
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EST Portfolio Value")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(String(format: "$%.2f", totalValue))
                        .font(.system(size: 34, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Row 2: Collections, Cards, Sets
            HStack(spacing: 0) {
                summaryStatItem(icon: "square.stack", value: "\(collections.count)", label: "Collections")
                Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 36)
                summaryStatItem(icon: "creditcard", value: "\(cachedCardCount)", label: "Cards")
                Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 36)
                summaryStatItem(icon: "globe", value: "\(distinctSets)", label: "Sets")
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.summaryGradient)
        )
    }

    private func summaryStatItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Grid

    private var collectionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredCollections) { collection in
                Button {
                    router.navigate(to: .collectionDetail(collection))
                } label: {
                    CollectionTileView(collection: collection)
                }
                .buttonStyle(.plain)
            }

            Button { showCreate = true } label: {
                createTile
            }
            .buttonStyle(.plain)
        }
    }

    private var createTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(theme.accent.opacity(0.6))
            Text("New Collection")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(theme.accent.opacity(0.2), lineWidth: 1.5)
        )
    }
}
