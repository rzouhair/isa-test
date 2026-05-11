import SwiftUI
import SwiftData
import Inject

/// Progress tab — exam countdown, big readiness donut with category legend,
/// per-category progress cards, focus (weak questions), activity totals.
struct StatsDashboardView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var passing: Double = 0
    @State private var categoryProgress: [CategoryProgress] = []
    @State private var examDate: Date?
    @State private var countdownSeconds: TimeInterval?
    @State private var weakCount: Int = 0
    @State private var streakDays: Int = 0
    @State private var totalMinutes: Int = 0
    @State private var totalQuestions: Int = 0

    private let legendLimit = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ExamCountdownPill(
                    examDate: examDate,
                    countdownSeconds: countdownSeconds,
                    onTap: { router.navigate(to: .examDatePicker) }
                )

                ReadinessDonutWithLegend(
                    passing: passing,
                    legend: legendItems
                )

                if !categoryProgress.isEmpty {
                    sectionHeader("Your categories")
                    VStack(spacing: 10) {
                        ForEach(Array(categoryProgress.enumerated()), id: \.element.code) { idx, cat in
                            CategoryProgressCard(
                                progress: cat,
                                accent: CategoryPalette.color(at: idx),
                                onTap: { router.navigate(to: .practiceTestList(categoryCode: cat.code)) }
                            )
                        }
                    }
                }

                sectionHeader("Focus")
                weakQuestionsRow

                sectionHeader("Activity")
                activityRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .task { refresh() }
        .refreshable { refresh() }
        .enableInjection()
    }

    // MARK: - Legend derivation

    /// Top-N categories by completion ratio, tiebreak by totalQuestions desc.
    private var legendItems: [ReadinessDonutWithLegend.LegendItem] {
        let sorted = categoryProgress
            .sorted { lhs, rhs in
                if lhs.completionRatio != rhs.completionRatio {
                    return lhs.completionRatio > rhs.completionRatio
                }
                return lhs.totalQuestions > rhs.totalQuestions
            }
            .prefix(legendLimit)
        return sorted.enumerated().map { idx, cat in
            ReadinessDonutWithLegend.LegendItem(
                id: cat.code,
                name: cat.name,
                ratio: cat.completionRatio,
                color: CategoryPalette.color(at: idx)
            )
        }
    }

    // MARK: - Focus (weak)

    private var weakQuestionsRow: some View {
        Button {
            router.navigate(to: .weakQuestions)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(weakCount == 0 ? Color.secondary : theme.celebration)
                VStack(alignment: .leading, spacing: 2) {
                    Text(weakCount == 0 ? "No weak questions yet" : "\(weakCount) weak question\(weakCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(weakCount == 0 ? "Questions you miss will appear here." : "Practice them to move off this list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Activity

    private var activityRow: some View {
        HStack(spacing: 1) {
            activityCell(value: "\(streakDays)", label: "day streak", icon: "flame.fill", tint: streakDays > 0 ? theme.celebration : Color.secondary)
            Divider().frame(height: 48)
            activityCell(value: "\(totalMinutes)", label: "min studied", icon: "clock.fill", tint: Color.secondary)
            Divider().frame(height: 48)
            activityCell(value: "\(totalQuestions)", label: "questions", icon: "questionmark.circle.fill", tint: Color.secondary)
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func activityCell(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.top, 4)
    }

    // MARK: - Load

    private func refresh() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let stats = DIContainer.shared.statsRepository(context: modelContext)
        let licenseCode = progress.profile()?.licenseCode ?? Constants.licenseCode
        let lang = progress.profile()?.preferredLang ?? "en"

        examDate = progress.profile()?.examDate
        countdownSeconds = stats.examCountdownSeconds()
        passing = stats.passingProbability(licenseCode: licenseCode)
        categoryProgress = stats.categoryProgress(licenseCode: licenseCode, lang: lang)
        weakCount = stats.weakQuestionIds(limit: 50).count
        streakDays = stats.currentStreakDays()

        let all = (try? modelContext.fetch(FetchDescriptor<StudyStreak>())) ?? []
        totalMinutes = all.map(\.minutesStudied).reduce(0, +)
        totalQuestions = all.map(\.questionsAnswered).reduce(0, +)
    }
}
