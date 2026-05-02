import SwiftUI
import SwiftData
import Inject

/// Grouped list. Core skills and Endorsements are visually separated because
/// the free/pro split is the single most important piece of info on this
/// screen. Rows are rich enough to stand alone (no identical card grid).
struct CategoryListView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var coreRows: [Row] = []
    @State private var endorsementRows: [Row] = []
    @State private var error: String?

    struct Row: Identifiable {
        let category: CategoryDTO
        let stats: CategoryStats?
        let questionCount: Int
        var id: Int { category.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error {
                    Text(error).font(.callout).foregroundStyle(.secondary)
                }

                if !coreRows.isEmpty {
                    sectionHeader(
                        title: "Core skills",
                        caption: "Required for everyone"
                    )
                    groupedList(rows: coreRows, isEndorsement: false)
                }

                if !endorsementRows.isEmpty {
                    sectionHeader(
                        title: "Endorsements",
                        caption: appState.isProUser
                            ? "Unlock as needed for your route"
                            : "Unlock with Pro"
                    )
                    groupedList(rows: endorsementRows, isEndorsement: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    // MARK: - Section header

    private func sectionHeader(title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Grouped list

    private func groupedList(rows: [Row], isEndorsement: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                categoryRow(row: row, isEndorsement: isEndorsement)
                if idx < rows.count - 1 {
                    Divider().padding(.leading, 14)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Row

    private func categoryRow(row: Row, isEndorsement: Bool) -> some View {
        let locked = isEndorsement && !appState.isProUser
        let attempts = row.stats?.attempts ?? 0
        let avg = row.stats?.avgScore ?? 0

        return Button {
            if locked {
                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "category"])
                appState.showPaywall()
            } else {
                router.navigate(to: .practiceTestList(categoryCode: row.category.code))
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.category.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(locked ? .secondary : .primary)

                    HStack(spacing: 6) {
                        Text("\(row.questionCount) question\(row.questionCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if attempts > 0 {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(attempts) attempt\(attempts == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 8)

                trailing(locked: locked, attempts: attempts, avg: avg)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func trailing(locked: Bool, attempts: Int, avg: Double) -> some View {
        if locked {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text("Pro")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.accent.opacity(0.12))
            .clipShape(Capsule())
        } else if attempts == 0 {
            Text("Start")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)
        } else {
            Text("\(Int(avg * 100))%")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(scoreTint(avg: avg))
        }
    }

    private func scoreTint(avg: Double) -> Color {
        switch avg {
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }

    // MARK: - Load

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        guard let profile = progress.profile() else {
            error = "Pick a license and state first."
            return
        }
        do {
            let cats = try DIContainer.shared.contentRepository.categories(licenseCode: profile.licenseCode)
            let counts = (try? DIContainer.shared.contentRepository.questionCounts(
                licenseCode: profile.licenseCode,
                stateCode: profile.stateCode,
                lang: profile.preferredLang
            )) ?? [:]
            let stats = DIContainer.shared.statsRepository(context: modelContext)
                .categoryStats(licenseCode: profile.licenseCode, stateCode: profile.stateCode)
            let statsByCode = Dictionary(uniqueKeysWithValues: stats.map { ($0.code, $0) })

            let all = cats.map { cat in
                Row(
                    category: cat,
                    stats: statsByCode[cat.code],
                    questionCount: counts[cat.code] ?? 0
                )
            }

            coreRows = all.filter { $0.category.kind == "core" }
            endorsementRows = all.filter { $0.category.kind == "endorsement" }
        } catch {
            self.error = "Couldn't load categories: \(error.localizedDescription)"
        }
    }
}
