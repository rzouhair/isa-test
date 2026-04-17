import SwiftUI
import SwiftData
import Inject

struct CollectionDetailView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Bindable var collection: CardCollection

    @State private var sortMode: CollectionSortMode = .valueDesc
    @State private var visibleCount: Int = 30
    @State private var searchText = ""

    private let pageSize = 30

    private var filtered: [CardRecord] {
        guard !searchText.isEmpty else { return collection.cards }
        let query = searchText.lowercased()
        return collection.cards.filter {
            $0.name.lowercased().contains(query) ||
            $0.setName.lowercased().contains(query) ||
            $0.rarity.lowercased().contains(query)
        }
    }

    private var sorted: [CardRecord] {
        switch sortMode {
        case .valueDesc: filtered.sorted { $0.tcgplayerPrice > $1.tcgplayerPrice }
        case .valueAsc:  filtered.sorted { $0.tcgplayerPrice < $1.tcgplayerPrice }
        case .newest:    filtered.sorted { $0.addedAt > $1.addedAt }
        case .nameAsc:   filtered.sorted { $0.name < $1.name }
        }
    }

    private var visibleCards: [CardRecord] {
        Array(sorted.prefix(visibleCount))
    }

    private var hasMore: Bool { visibleCount < sorted.count }

    var body: some View {
        List {
            Section {
                summaryBox
            }

            Section {
                if collection.cards.isEmpty {
                    ContentUnavailableView(
                        "No Cards Yet",
                        systemImage: "square.stack",
                        description: Text("Scan cards and add them to this collection.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(visibleCards) { card in
                        Button { router.navigate(to: .cardDetail(card)) } label: {
                            CollectionCardRow(card: card)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if card.id == visibleCards.last?.id, hasMore {
                                visibleCount += pageSize
                            }
                        }
                    }
                    if hasMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                HStack {
                    Text("Cards")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                    Spacer()
                    Menu {
                        ForEach(CollectionSortMode.allCases, id: \.self) { mode in
                            Button {
                                sortMode = mode
                                visibleCount = pageSize
                            } label: {
                                if sortMode == mode {
                                    Label(mode.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(mode.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.arrow.down").font(.caption2)
                            Text(sortMode.rawValue).font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search cards")
        .onChange(of: searchText) { visibleCount = pageSize }
        .enableInjection()
    }

    // MARK: - Summary Box

    private var summaryBox: some View {
        HStack(spacing: 0) {
            statColumn(
                icon: "creditcard",
                value: "\(collection.cardCount)",
                label: "Cards"
            )
            statDivider
            statColumn(
                icon: "globe",
                value: "\(collection.distinctSets)",
                label: "Sets"
            )
            statDivider
            statColumn(
                icon: "dollarsign.circle",
                value: String(format: "$%.0f", collection.totalValue),
                label: "Value"
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    theme.summaryGradient
                )
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.2))
            .frame(width: 1, height: 44)
    }

    private func statColumn(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sort Mode (shared)

enum CollectionSortMode: String, CaseIterable {
    case valueDesc = "Value ↓"
    case valueAsc  = "Value ↑"
    case newest    = "Recently added"
    case nameAsc   = "Name A→Z"
}
