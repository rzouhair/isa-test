import SwiftUI
import SwiftData
import Inject

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Query(sort: \CardRecord.addedAt, order: .reverse) private var allCards: [CardRecord]
    @Query(
        sort: \ScanRecord.createdAt,
        order: .reverse
    ) private var allScans: [ScanRecord]
    @Query(sort: \GradeRecord.createdAt, order: .reverse) private var gradeRecords: [GradeRecord]

    /// In-progress scans first, then completed — so user always sees pending identifications
    private var recentScans: [ScanRecord] {
        let inProgress = allScans.filter { $0.scanStatus == .pending || $0.scanStatus == .processing }
        let completed = allScans.filter { $0.scanStatus == .complete }
        return Array((inProgress + completed).prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroBanner
                recentGradesSection
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

            HStack(spacing: 12) {
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

                Button {
                    if appState.isProUser {
                        router.presentFullscreenCover(.grading)
                    } else {
                        appState.showPaywall()
                    }
                } label: {
                    Label("Grade", systemImage: "star.circle")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            ZStack {
                Image("hero_bg")
                    .resizable()
                    .scaledToFill()
                theme.summaryGradientDiagonal.opacity(0.75)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                if !allCards.isEmpty {
                    Button {
                        router.navigate(to: .collection)
                    } label: {
                        Text("Show All")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if recentScans.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.stack")
                        .font(.system(.title))
                        .foregroundStyle(.tertiary)
                    Text("No scans yet")
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
                    ForEach(recentScans) { scan in
                        Group {
                            if scan.scanStatus == .complete, let card = cardFor(scan) {
                                Button {
                                    router.navigate(to: .cardDetail(card))
                                } label: {
                                    scanRow(scan)
                                }
                                .buttonStyle(.plain)
                            } else if scan.scanStatus == .pending || scan.scanStatus == .processing {
                                Button {
                                    // Re-open scanner to see progress
                                    router.presentFullscreenCover(.scanner)
                                } label: {
                                    scanRow(scan)
                                }
                                .buttonStyle(.plain)
                            } else {
                                scanRow(scan)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        if scan.id != recentScans.last?.id {
                            Divider().padding(.leading, 78)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                if allCards.count > 5 {
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

    private func scanRow(_ scan: ScanRecord) -> some View {
        HStack(spacing: 12) {
            Group {
                if let urlString = scan.imageSmall ?? scan.imageMedium,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        capturedThumbnail(for: scan)
                    }
                } else {
                    capturedThumbnail(for: scan)
                }
            }
            .frame(width: 46, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                if scan.scanStatus == .pending || scan.scanStatus == .processing {
                    Text("Identifying...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("Tap to open scanner")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else {
                    Text(scan.productName ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text([scan.setName ?? "", scan.rarity ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ScanCollectionLabel(cardRecordId: scan.cardRecordId)
                }
            }

            Spacer(minLength: 8)

            if let price = scan.marketPrice, price > 0 {
                Text(String(format: "$%.2f", price))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.valueGradient)
            }

            if scan.scanStatus == .failed {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color(.systemOrange))
            } else if scan.scanStatus == .pending || scan.scanStatus == .processing {
                ProgressView().controlSize(.small)
            }
        }
    }

    private func capturedThumbnail(for scan: ScanRecord) -> some View {
        Group {
            if let url = ScanStore.resolveImageURL(scan.capturedImagePath),
               let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(Image(systemName: "creditcard").foregroundStyle(.quaternary))
            }
        }
    }

    private func cardFor(_ scan: ScanRecord) -> CardRecord? {
        guard let cardId = scan.cardRecordId else { return nil }
        return allCards.first { $0.id == cardId }
    }

    // MARK: - Last Grade

    private var recentGradesSection: some View {
        Group {
            if let record = gradeRecords.first {
                VStack(spacing: 0) {
                    HStack {
                        Text("Last Grade")
                            .font(.headline)
                        Spacer()
                        if gradeRecords.count > 1 {
                            Button {
                                router.navigate(to: .gradingHistory)
                            } label: {
                                Text("History")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(theme.accent.opacity(0.8))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    Button {
                        router.navigate(to: .gradeDetail(record))
                    } label: {
                        lastGradeCard(record)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func lastGradeCard(_ record: GradeRecord) -> some View {
        VStack(spacing: 14) {
            // Header: PSA range + confidence
            HStack(alignment: .firstTextBaseline) {
                if let psa = record.psaRange {
                    Text("PSA \(psa)")
                        .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                if let bgs = record.bgsRange {
                    Text("· BGS \(bgs)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(record.confidence.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(confidenceTint(record.confidence))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(confidenceTint(record.confidence).opacity(0.08))
                    .clipShape(Capsule())
            }

            // Sub-scores grid
            HStack(spacing: 0) {
                gradeScoreItem("Centering", record.centeringScore)
                gradeScoreItem("Corners", record.cornersScore)
                gradeScoreItem("Edges", record.edgesScore)
                gradeScoreItem("Surface", record.surfaceScore)
            }

            // Date
            HStack {
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func gradeScoreItem(_ label: String, _ score: Double) -> some View {
        VStack(spacing: 5) {
            Text(String(format: "%.1f", score))
                .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(scoreTint(score))

            // Thin bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(scoreTint(score).opacity(0.25))
                .frame(height: 3)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(scoreTint(score))
                            .frame(width: geo.size.width * CGFloat(score / 10.0))
                    }
                }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreTint(_ score: Double) -> Color {
        if score >= 8.5 { return .green.opacity(0.75) }
        if score >= 6.5 { return .orange.opacity(0.7) }
        return .red.opacity(0.65)
    }

    private func confidenceTint(_ confidence: String) -> Color {
        switch confidence {
        case "high": .green.opacity(0.75)
        case "medium": .orange.opacity(0.7)
        default: .red.opacity(0.65)
        }
    }
}
