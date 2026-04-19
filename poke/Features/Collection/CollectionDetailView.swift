import SwiftUI
import SwiftData
import Inject

struct CollectionDetailView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Bindable var collection: CardCollection

    @SceneStorage("collectionDetail.sortMode") private var sortModeRaw: String = CollectionSortMode.valueDesc.rawValue
    @SceneStorage("collectionDetail.searchText") private var searchText: String = ""
    @State private var visibleCount: Int = 30
    @State private var isSelecting: Bool = false
    @State private var selection: Set<UUID> = []
    @State private var showMoveSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false

    private var sortMode: CollectionSortMode {
        get { CollectionSortMode(rawValue: sortModeRaw) ?? .valueDesc }
    }

    private func setSortMode(_ mode: CollectionSortMode) {
        sortModeRaw = mode.rawValue
    }

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
                        Button {
                            if isSelecting {
                                toggleSelection(card.id)
                            } else {
                                router.navigate(to: .cardDetail(card))
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isSelecting {
                                    Image(systemName: selection.contains(card.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selection.contains(card.id) ? theme.accent : Color(.tertiaryLabel))
                                        .transition(.opacity.combined(with: .scale))
                                }
                                CollectionCardRow(card: card)
                            }
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
                                setSortMode(mode)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !collection.cards.isEmpty {
                    Button(isSelecting ? "Done" : "Select") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelecting.toggle()
                            if !isSelecting { selection.removeAll() }
                        }
                    }
                    .tint(theme.accent)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting { selectionActionBar }
        }
        .sheet(isPresented: $showMoveSheet) {
            AddToCollectionSheet { destination in
                moveSelected(to: destination)
            }
        }
        .confirmationDialog(
            "Delete \(selection.count) card\(selection.count == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the cards from your library.")
        }
        .enableInjection()
    }

    // MARK: - Selection Actions

    private func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    private var selectionActionBar: some View {
        HStack(spacing: 10) {
            Button {
                showMoveSheet = true
            } label: {
                Label("Move", systemImage: "folder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(theme.accent)
                    .background(theme.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(selection.isEmpty)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Text(selection.isEmpty ? "Tap cards to select" : "\(selection.count) selected")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, -22)
                .frame(maxWidth: .infinity)
        }
    }

    private func moveSelected(to destination: CardCollection) {
        guard !selection.isEmpty else { return }
        let targets = collection.cards.filter { selection.contains($0.id) }
        for card in targets {
            card.collection = destination
        }
        destination.updatedAt = Date()
        collection.updatedAt = Date()
        trySave()
        selection.removeAll()
        isSelecting = false
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        let targets = collection.cards.filter { selection.contains($0.id) }
        for card in targets {
            ScanStore.shared.purgeScans(
                forCardId: card.id,
                productId: card.tcgplayerProductId,
                in: modelContext
            )
            modelContext.delete(card)
        }
        collection.updatedAt = Date()
        trySave()
        selection.removeAll()
        isSelecting = false
    }

    private func trySave() {
        do {
            try modelContext.save()
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "collection_bulk_action", "collection_id": collection.id.uuidString]
            )
        }
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
