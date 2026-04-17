import SwiftUI
import SwiftData
import Inject

struct SearchView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Query private var cards: [CardRecord]

    @State private var query = ""

    private var results: [CardRecord] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return cards.filter {
            $0.name.lowercased().contains(q) ||
            $0.setName.lowercased().contains(q) ||
            $0.rarity.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            if query.isEmpty {
                ContentUnavailableView(
                    "Search Your Collection",
                    systemImage: "magnifyingglass",
                    description: Text("Type a card name, set, or rarity.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(results) { card in
                    Button {
                        router.navigate(to: .cardDetail(card))
                    } label: {
                        CollectionCardRow(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Cards, sets, rarity…")
        .enableInjection()
    }
}
