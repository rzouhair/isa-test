import SwiftUI
import SwiftData
import Inject

struct CollectionView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [CardRecord]

    @State private var sortMode: CollectionSortMode = .valueDesc
    @State private var searchText = ""
    @State private var visibleCount: Int = 40
    @State private var isSelecting: Bool = false
    @State private var selection: Set<UUID> = []
    @State private var showMoveSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    private let pageSize = 40

    private var filtered: [CardRecord] {
        guard !searchText.isEmpty else { return Array(cards) }
        let query = searchText.lowercased()
        return cards.filter {
            $0.name.lowercased().contains(query) ||
            $0.setName.lowercased().contains(query) ||
            $0.rarity.lowercased().contains(query)
        }
    }

    private var sorted: [CardRecord] {
        switch sortMode {
        case .valueDesc: return filtered.sorted { $0.tcgplayerPrice > $1.tcgplayerPrice }
        case .valueAsc:  return filtered.sorted { $0.tcgplayerPrice < $1.tcgplayerPrice }
        case .newest:    return filtered.sorted { $0.addedAt > $1.addedAt }
        case .nameAsc:   return filtered.sorted { $0.name < $1.name }
        }
    }

    private var visibleCards: [CardRecord] { Array(sorted.prefix(visibleCount)) }
    private var hasMore: Bool { visibleCount < sorted.count }

    private var totalValue: Double { cards.reduce(0) { $0 + $1.tcgplayerPrice } }
    private var distinctSets: Int { Set(cards.map(\.setName)).count }

    var body: some View {
        List {
            Section {
                summaryRow
            }

            Section {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No Cards Yet",
                        systemImage: "square.stack",
                        description: Text("Tap Scan to add your first card.")
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
        .navigationTitle("All Cards")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search cards")
        .onChange(of: searchText) { visibleCount = pageSize }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !cards.isEmpty {
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
                Label("Assign Collection", systemImage: "folder.badge.plus")
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
        let targets = cards.filter { selection.contains($0.id) }
        for card in targets {
            card.collection = destination
        }
        destination.updatedAt = Date()
        trySave()
        selection.removeAll()
        isSelecting = false
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        let targets = cards.filter { selection.contains($0.id) }
        for card in targets {
            ScanStore.shared.purgeScans(
                forCardId: card.id,
                productId: card.tcgplayerProductId,
                in: modelContext
            )
            modelContext.delete(card)
        }
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
                context: ["action": "all_cards_bulk_action"]
            )
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        VStack(spacing: 0) {
            // Value row — full width, prominent
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Portfolio Value")
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

            // Stats row — cards + sets
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(cards.count)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Cards")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 28)

                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(distinctSets)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Sets")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.summaryGradient)
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

// MARK: - Card Row

struct CollectionCardRow: View {
    let card: CardRecord

    var body: some View {
        HStack(spacing: 12) {
            cardThumbnail
                .frame(width: 46, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(card.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text([card.setName, card.rarity].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(card.collection?.name ?? "Unassigned")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "$%.2f", card.tcgplayerPrice))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.valueGradient)
                if card.isGraded, let co = card.gradeCompany, let gr = card.gradeValue {
                    Text("\(co) \(gr)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color(.systemOrange))
                } else {
                    Text("Raw").font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var cardThumbnail: some View {
        if let urlString = card.scanImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    capturedOrPlaceholder
                }
            }
        } else {
            capturedOrPlaceholder
        }
    }

    @ViewBuilder
    private var capturedOrPlaceholder: some View {
        if let path = card.capturedImagePath,
           let url = ScanStore.resolveImageURL(path),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(.tertiarySystemFill))
                .overlay(Image(systemName: "creditcard").foregroundStyle(.quaternary))
        }
    }
}
