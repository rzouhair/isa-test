import SwiftUI
import SwiftData
import Inject

struct WatchlistView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) var modelContext
    @Environment(Router.self) var router

    @Query(sort: \WatchlistItem.addedAt, order: .reverse) var items: [WatchlistItem]
    @Query var allCards: [CardRecord]

    @State private var searchText = ""
    @State private var sortMode: WatchlistSortMode = .newest
    @State private var gameFilter: String?
    @State private var isUpdating = false

    // MARK: - Filtering & Sorting

    private var availableGames: [String] {
        Array(Set(items.map(\.game)).filter { !$0.isEmpty }).sorted()
    }

    private var filtered: [WatchlistItem] {
        var result = Array(items)

        if let game = gameFilter {
            result = result.filter { $0.game == game }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.setName.lowercased().contains(q) ||
                $0.game.lowercased().contains(q)
            }
        }

        return result
    }

    private var sorted: [WatchlistItem] {
        switch sortMode {
        case .newest:    filtered.sorted { $0.addedAt > $1.addedAt }
        case .valueDesc: filtered.sorted { $0.lastKnownPrice > $1.lastKnownPrice }
        case .valueAsc:  filtered.sorted { $0.lastKnownPrice < $1.lastKnownPrice }
        case .nameAsc:   filtered.sorted { $0.name < $1.name }
        case .changeDesc:
            filtered.sorted {
                abs(cardFor($0)?.priceChangePct ?? 0) > abs(cardFor($1)?.priceChangePct ?? 0)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Watchlist Items",
                    systemImage: "eye",
                    description: Text("Cards you're watching will appear here.\nAdd cards from the scanner or collection.")
                )
            } else {
                List {
                    // Progress banner
                    if isUpdating {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Updating prices...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(sorted) { item in
                            Button {
                                if let card = cardFor(item) {
                                    router.navigate(to: .cardDetail(card))
                                }
                            } label: {
                                watchlistRow(item)
                            }
                            .tint(.primary)
                        }
                        .onDelete(perform: deleteItems)
                    } header: {
                        HStack {
                            Text("Cards")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .textCase(nil)

                            // Refresh button
                            Button {
                                Task { await manualRefresh() }
                            } label: {
                                if isUpdating {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(WatchlistPriceService.canRefresh ? theme.accent : .secondary)
                                }
                            }
                            .disabled(isUpdating || items.isEmpty || !WatchlistPriceService.canRefresh)

                            Spacer()

                            // Game filter
                            if availableGames.count > 1 {
                                Menu {
                                    Button {
                                        gameFilter = nil
                                    } label: {
                                        if gameFilter == nil {
                                            Label("All Games", systemImage: "checkmark")
                                        } else {
                                            Text("All Games")
                                        }
                                    }
                                    ForEach(availableGames, id: \.self) { game in
                                        Button {
                                            gameFilter = game
                                        } label: {
                                            if gameFilter == game {
                                                Label(game, systemImage: "checkmark")
                                            } else {
                                                Text(game)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "line.3.horizontal.decrease").font(.caption2)
                                        Text(gameFilter ?? "All").font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }

                            // Sort menu
                            Menu {
                                ForEach(WatchlistSortMode.allCases, id: \.self) { mode in
                                    Button {
                                        sortMode = mode
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
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search watchlist")
            }
        }
        .enableInjection()
    }

    // MARK: - Manual Refresh

    private func manualRefresh() async {
        isUpdating = true
        let result = await WatchlistPriceService.shared.refreshAllPrices()
        WatchlistPriceService.shared.sendCompletionNotification(
            success: result.success, failed: result.failed
        )
        if result.success > 0 {
            WatchlistPriceService.recordRefreshTimestamp()
            WatchlistPriceService.scheduleRecurringReminder()
        }
        isUpdating = false
    }

    // MARK: - Row

    private func watchlistRow(_ item: WatchlistItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "creditcard")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                    )
            }
            .frame(width: 44, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(item.setName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !item.game.isEmpty {
                    Text(item.game)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if item.lastKnownPrice > 0 {
                let card = cardFor(item)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "$%.2f", item.lastKnownPrice))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(theme.value)

                    if let pct = card?.priceChangePct, pct != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: pct > 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 8, weight: .bold))
                            Text(String(format: "%+.1f%%", pct))
                                .font(.caption2.weight(.semibold).monospacedDigit())
                        }
                        .foregroundStyle(pct > 0 ? Color(.systemGreen) : Color(.systemRed))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func cardFor(_ item: WatchlistItem) -> CardRecord? {
        allCards.first { $0.tcgplayerProductId == item.tcgplayerProductId }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = sorted[index]
            modelContext.delete(item)
        }
    }
}

// MARK: - Sort Mode

enum WatchlistSortMode: String, CaseIterable {
    case newest    = "Recently added"
    case valueDesc = "Value ↓"
    case valueAsc  = "Value ↑"
    case nameAsc   = "Name A→Z"
    case changeDesc = "Biggest movers"
}
