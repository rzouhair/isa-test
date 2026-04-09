import SwiftUI
import SwiftData
import Inject

struct CardDetailView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) var modelContext
    let card: CardRecord

    @Query var watchlistItems: [WatchlistItem]

    @State private var appeared = false
    @State private var dragOffset: CGSize = .zero
    @State private var shimmerPhase: CGFloat = -1
    @State private var showShareSheet = false
    @State private var isUpdatingPrice = false
    @State private var localPriceHistory: PriceHistory?
    @State private var priceInitialized = false
    @State private var watchlistAdded = false
    @State private var showAddToCollection = false

    private let service = DIContainer.shared.cardIdentifierService

    private var isInCollection: Bool {
        card.collection != nil
    }

    private var isOnWatchlist: Bool {
        watchlistItems.contains { $0.tcgplayerProductId == card.tcgplayerProductId && !card.tcgplayerProductId.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cardHero
                priceSection
                actionBar
                    .padding(.horizontal, 16)
                priceChartSection
                    .padding(.horizontal, 16)
                infoSection
                candidatesSection
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(card: card)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 2
            }
        }
        .enableInjection()
    }

    // MARK: - 3D Card Hero

    private var cardHero: some View {
        VStack(spacing: 12) {
            ZStack {
                AsyncImage(url: URL(string: card.scanImageUrl ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .aspectRatio(0.71, contentMode: .fit)
                        .overlay(
                            Image(systemName: "creditcard")
                                .font(.largeTitle)
                                .foregroundStyle(.quaternary)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.05),
                                    .white.opacity(0.15),
                                    .white.opacity(0.05),
                                    .clear
                                ],
                                startPoint: UnitPoint(x: shimmerPhase - 0.3, y: shimmerPhase - 0.3),
                                endPoint: UnitPoint(x: shimmerPhase, y: shimmerPhase)
                            )
                        )
                        .allowsHitTesting(false)
                )
                .rotation3DEffect(
                    .degrees(Double(dragOffset.width) / 8),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(Double(-dragOffset.height) / 8),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .shadow(
                    color: rarityColor.opacity(0.4),
                    radius: appeared ? 20 : 0,
                    y: 8
                )
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
            }
            .frame(height: 280)
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )

            if !card.rarity.isEmpty {
                Text(card.rarity.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(rarityColor)
                    .clipShape(Capsule())
            }

            Text(card.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text(card.setName + (card.number.isEmpty ? "" : " · #\(card.number)"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(spacing: 4) {
            if card.tcgplayerPrice > 0 {
                Text(String(format: "$%.2f", card.tcgplayerPrice))
                    .font(.system(size: 36, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.valueGradient)
                Text("Market Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Add to collection — large button
            Button {
                if !isInCollection { showAddToCollection = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isInCollection ? "checkmark.circle.fill" : "plus.rectangle.on.folder")
                        .font(.body.weight(.semibold))
                    Text(isInCollection ? "In Collection" : "Add to Collection")
                        .font(.body.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(isInCollection ? .white : theme.accent)
                .background(isInCollection ? theme.accent : theme.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isInCollection)

            // Watchlist — square button
            Button { toggleWatchlist() } label: {
                Image(systemName: isOnWatchlist ? "eye.fill" : "eye")
                    .font(.body.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .foregroundStyle(isOnWatchlist ? .white : theme.accent)
                    .background(isOnWatchlist ? theme.accent : theme.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Share — square button
            Button { showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .foregroundStyle(theme.accent)
                    .background(theme.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionSheet { collection in
                card.collection = collection
                collection.updatedAt = Date()
            }
        }
    }

    private func toggleWatchlist() {
        if let existing = watchlistItems.first(where: { $0.tcgplayerProductId == card.tcgplayerProductId }) {
            modelContext.delete(existing)
        } else {
            let item = WatchlistItem(from: card)
            modelContext.insert(item)
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Card Info")

            VStack(spacing: 0) {
                infoRow("Set", card.setName)
                Divider().padding(.leading, 16)
                infoRow("Number", card.number.isEmpty ? "—" : "#\(card.number)")
                Divider().padding(.leading, 16)
                infoRow("Rarity", card.rarity.isEmpty ? "—" : card.rarity)
                if !card.variant.isEmpty, card.variant.uppercased() != "STANDARD" {
                    Divider().padding(.leading, 16)
                    infoRow("Variant", card.variant)
                }
                Divider().padding(.leading, 16)
                infoRow("Game", card.game.isEmpty ? "—" : card.game)
                if card.isGraded, let co = card.gradeCompany, let gr = card.gradeValue {
                    Divider().padding(.leading, 16)
                    infoRow("Grade", "\(co) \(gr)")
                }
                Divider().padding(.leading, 16)
                infoRow("Added", card.addedAt.formatted(date: .abbreviated, time: .omitted))
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Candidates

    @ViewBuilder
    private var candidatesSection: some View {
        let items = card.candidates.filter { $0.productId != card.tcgplayerProductId }
        if !items.isEmpty {
            VStack(spacing: 0) {
                sectionHeader("Similar Cards")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(items.prefix(10).enumerated()), id: \.offset) { _, candidate in
                            candidateCard(candidate)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func candidateCard(_ candidate: Candidate) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: candidate.image ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(Image(systemName: "creditcard").font(.caption).foregroundStyle(.quaternary))
            }
            .frame(width: 70, height: 98)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(candidate.name ?? "—")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let price = candidate.marketPrice {
                Text(String(format: "$%.2f", price))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.value)
            }
        }
        .frame(width: 80)
    }

    // MARK: - Price Chart Section

    private var priceChartSection: some View {
        VStack(spacing: 0) {
            let history = localPriceHistory ?? card.priceHistory
            PriceChartView(history: history, trailingHeader: { updateButton })
        }
        .onAppear {
            if !priceInitialized {
                localPriceHistory = card.priceHistory
                priceInitialized = true
            }
        }
    }

    private var updateButton: some View {
        Button {
            Task { await updatePrice() }
        } label: {
            HStack(spacing: 4) {
                ZStack {
                    ProgressView()
                        .controlSize(.small)
                        .opacity(isUpdatingPrice ? 1 : 0)
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .opacity(isUpdatingPrice ? 0 : 1)
                }
                .frame(width: 14, height: 14)
                Text("Update")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.accentSubtle)
            .clipShape(Capsule())
        }
        .disabled(isUpdatingPrice || card.tcgplayerProductId.isEmpty)
    }

    private func updatePrice() async {
        guard !card.tcgplayerProductId.isEmpty else { return }
        isUpdatingPrice = true
        defer { isUpdatingPrice = false }

        do {
            let history = try await service.fetchPriceHistory(productId: card.tcgplayerProductId)

            // Update local state for immediate UI refresh
            localPriceHistory = history

            // Persist to card model
            card.storePriceHistory(history)

            // Update market price from latest data point or summary
            if let current = history.summary.currentMarketPrice, current > 0 {
                card.tcgplayerPrice = current
            } else if let latest = history.chart.first?.dataPoints.last?.marketPrice, latest > 0 {
                card.tcgplayerPrice = latest
            }

            card.priceUpdatedAt = Date()
        } catch {
            // Silent fail — chart stays as-is
            print("Price update failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text).font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var rarityColor: Color {
        let r = card.rarity.lowercased()
        if r.contains("secret") { return Color(.systemOrange) }
        if r.contains("ultra")  { return Color(.systemPink) }
        if r.contains("holo")   { return Color(.systemPurple) }
        if r.contains("rare")   { return Color(.systemBlue) }
        return Color(.systemGray)
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let card: CardRecord

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = []
        let text = "\(card.name) — \(String(format: "$%.2f", card.tcgplayerPrice))"
        items.append(text)
        if !card.tcgplayerProductId.isEmpty,
           let url = URL(string: "https://www.tcgplayer.com/product/\(card.tcgplayerProductId)") {
            items.append(url)
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
