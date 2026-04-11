import SwiftUI
import SwiftData
import Inject

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Query(sort: \CardRecord.addedAt, order: .reverse) private var allCards: [CardRecord]
    @Query(
        filter: #Predicate<ScanRecord> { $0.status == "complete" },
        sort: \ScanRecord.createdAt,
        order: .reverse
    ) private var completedScans: [ScanRecord]

    private var recentScans: [ScanRecord] {
        Array(completedScans.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroBanner
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
                        Button {
                            if let card = cardFor(scan) {
                                router.navigate(to: .cardDetail(card))
                            }
                        } label: {
                            scanRow(scan)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
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
                Text(scan.productName ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text([scan.setName ?? "", scan.rarity ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
            if !scan.capturedImagePath.isEmpty,
               let data = try? Data(contentsOf: URL(fileURLWithPath: scan.capturedImagePath)),
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
}
