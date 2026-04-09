import SwiftUI
import SwiftData
import Inject

struct WatchlistView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) var modelContext
    @Environment(Router.self) var router

    @Query(sort: \WatchlistItem.addedAt, order: .reverse) var items: [WatchlistItem]
    @State private var searchText = ""

    private var filtered: [WatchlistItem] {
        guard !searchText.isEmpty else { return items }
        let q = searchText.lowercased()
        return items.filter {
            $0.name.lowercased().contains(q) ||
            $0.setName.lowercased().contains(q) ||
            $0.game.lowercased().contains(q)
        }
    }

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
                    ForEach(filtered) { item in
                        watchlistRow(item)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search watchlist")
            }
        }
        .enableInjection()
    }

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
                Text(String(format: "$%.2f", item.lastKnownPrice))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.value)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filtered[index]
            modelContext.delete(item)
        }
    }
}
