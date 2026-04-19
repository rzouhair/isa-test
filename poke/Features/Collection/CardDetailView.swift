import SwiftUI
import SwiftData
import Inject

struct CardDetailView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) var modelContext
    @Environment(Router.self) var router
    let card: CardRecord

    @Query(sort: \WatchlistItem.addedAt, order: .reverse) var watchlistItems: [WatchlistItem]

    @State private var appeared = false
    @State private var dragOffset: CGSize = .zero
    @State private var shimmerPhase: CGFloat = -1
    @State private var showShareSheet = false
    @State private var isUpdatingPrice = false
    @State private var localPriceHistory: PriceHistory?
    @State private var priceInitialized = false
    @State private var watchlistAdded = false
    @State private var showAddToCollection = false
    @State private var showCorrectionSheet = false
    @State private var previewCandidate: CandidatePreview?
    @State private var hasScanRecord = false

    private let service = DIContainer.shared.cardIdentifierService
    private let scanStore = ScanStore.shared

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
                unconfirmedBanner
                actionBar
                    .padding(.horizontal, 16)
                priceChartSection
                    .padding(.horizontal, 16)
                infoSection
                marketplaceLinks
                    .padding(.horizontal, 16)
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
        .sheet(isPresented: $showCorrectionSheet) {
            if let record = fetchScanRecord() {
                ScanCorrectionSheet(record: record, scanStore: scanStore)
            } else {
                correctionUnavailableView
            }
        }
        .sheet(item: $previewCandidate) { preview in
            CandidatePreviewSheet(
                candidate: preview.candidate,
                canApply: !card.isUserConfirmed && hasScanRecord,
                onUse: { applyCandidate(preview.candidate) }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 2
            }
            hasScanRecord = fetchScanRecord() != nil
        }
        .enableInjection()
    }

    // MARK: - Card Image (remote → captured fallback → placeholder)

    @ViewBuilder
    private var cardImageView: some View {
        if let urlString = card.scanImageUrl, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .failure:
                    capturedOrPlaceholder
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
            Image(uiImage: uiImage).resizable()
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemFill))
                .aspectRatio(0.71, contentMode: .fit)
                .overlay(
                    Image(systemName: "creditcard")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                )
        }
    }

    // MARK: - 3D Card Hero

    private var cardHero: some View {
        VStack(spacing: 14) {
            cardImageView
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.05), .white.opacity(0.15), .white.opacity(0.05), .clear],
                                startPoint: UnitPoint(x: shimmerPhase - 0.3, y: shimmerPhase - 0.3),
                                endPoint: UnitPoint(x: shimmerPhase, y: shimmerPhase)
                            )
                        )
                        .allowsHitTesting(false)
                )
                .rotation3DEffect(.degrees(Double(dragOffset.width) / 8), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .rotation3DEffect(.degrees(Double(-dragOffset.height) / 8), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                .shadow(color: rarityColor.opacity(0.35), radius: appeared ? 18 : 0, y: 6)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
                .frame(height: 260)
                .gesture(
                    DragGesture()
                        .onChanged { value in dragOffset = value.translation }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { dragOffset = .zero }
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

    // MARK: - Unconfirmed Banner

    @ViewBuilder
    private var unconfirmedBanner: some View {
        if !card.isUserConfirmed && hasScanRecord {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Auto-matched")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Confirm or correct")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button { showCorrectionSheet = true } label: {
                    Text("Correct")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(theme.accentSubtle)
                        .clipShape(Capsule())
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scanStore.confirmCard(card)
                    }
                } label: {
                    Text("Confirm")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(theme.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.accent.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private var correctionUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Scan unavailable")
                .font(.headline)
            Text("The original scan is no longer on this device, so the candidate list can't be loaded. Re-scan the card to identify it again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .presentationDetents([.medium])
    }

    private func applyCandidate(_ candidate: Candidate) {
        guard let record = fetchScanRecord() else {
            scanStore.confirmCard(card)
            return
        }
        scanStore.applyCandidate(candidate, to: record)
    }

    private func fetchScanRecord() -> ScanRecord? {
        let cardId = card.id
        var descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.cardRecordId == cardId }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
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
        HStack(spacing: 10) {
            Button {
                if let collection = card.collection {
                    router.navigate(to: .collectionDetail(collection))
                } else {
                    showAddToCollection = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isInCollection ? "folder.fill" : "plus")
                        .font(.subheadline.weight(.semibold))
                    Text(isInCollection ? (card.collection?.name ?? "Collection") : "Add to Collection")
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(.white)
                .background(theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button { toggleWatchlist() } label: {
                Image(systemName: isOnWatchlist ? "eye.fill" : "eye")
                    .font(.body.weight(.semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(isOnWatchlist ? .white : theme.accent)
                    .background(isOnWatchlist ? theme.accent : theme.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button { showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(theme.accent)
                    .background(theme.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        guard !card.tcgplayerProductId.isEmpty else { return }
        let productId = card.tcgplayerProductId
        var descriptor = FetchDescriptor<WatchlistItem>(
            predicate: #Predicate { $0.tcgplayerProductId == productId }
        )
        descriptor.fetchLimit = 1
        let existing = (try? modelContext.fetch(descriptor).first)

        if let existing {
            modelContext.delete(existing)
        } else {
            let item = WatchlistItem(from: card)
            modelContext.insert(item)
            WatchlistPriceService.scheduleRecurringReminder()
        }

        do {
            try modelContext.save()
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "watchlist_toggle", "product_id": productId]
            )
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
                            Button {
                                previewCandidate = CandidatePreview(candidate: candidate)
                            } label: {
                                candidateCard(candidate)
                            }
                            .buttonStyle(.plain)
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
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: [
                    "action": "card_detail_price_refresh",
                    "product_id": card.tcgplayerProductId
                ]
            )
        }
    }

    // MARK: - Marketplace Links

    private var marketplaceLinks: some View {
        HStack(spacing: 10) {
            Button {
                let query = card.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://www.tcgplayer.com/search/all/product?q=\(query)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                    Text("TCGPlayer")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(theme.accent)
                .background(theme.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                let query = card.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://www.ebay.com/sch/i.html?_nkw=\(query)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                    Text("eBay")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(theme.accent)
                .background(theme.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
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

// MARK: - Candidate Preview

struct CandidatePreview: Identifiable {
    let id = UUID()
    let candidate: Candidate
}

private struct CandidatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let candidate: Candidate
    let canApply: Bool
    let onUse: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsyncImage(url: URL(string: candidate.image ?? "")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                            .aspectRatio(0.71, contentMode: .fit)
                            .overlay(Image(systemName: "creditcard").font(.largeTitle).foregroundStyle(.quaternary))
                    }
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)

                    VStack(spacing: 6) {
                        Text(candidate.name ?? "Unknown")
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text([candidate.setName, candidate.cardNumber.map { "#\($0)" }].compactMap { $0 }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let price = candidate.marketPrice ?? candidate.medianPrice ?? candidate.lowestPrice {
                            Text(String(format: "$%.2f", price))
                                .font(.title2.weight(.heavy).monospacedDigit())
                                .foregroundStyle(theme.value)
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 0) {
                        infoRow("Rarity", candidate.rarity)
                        Divider().padding(.leading, 16)
                        infoRow("Variant", candidate.variant?.uppercased() == "STANDARD" ? nil : candidate.variant)
                        Divider().padding(.leading, 16)
                        infoRow("Year", candidate.year)
                        Divider().padding(.leading, 16)
                        infoRow("Game", candidate.game)
                        if let confidence = candidate.confidence {
                            Divider().padding(.leading, 16)
                            infoRow("Confidence", "\(Int(confidence * 100))%")
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)

                    if let urlString = candidate.url, let url = URL(string: urlString) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "safari")
                                Text("View on TCGPlayer")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(theme.accent)
                            .background(theme.accentSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Candidate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if canApply {
                    VStack(spacing: 0) {
                        Divider()
                        Button {
                            onUse()
                            dismiss()
                        } label: {
                            Text("Use This Card")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
    }

    private func infoRow(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value?.isEmpty == false ? value! : "—")
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
