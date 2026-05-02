import SwiftUI
import SwiftData
import Inject

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var vm: HomeViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let vm {
                    if !vm.hasProfile {
                        setupCard
                    } else {
                        dashboard(vm: vm)
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if vm == nil {
                let stats = DIContainer.shared.statsRepository(context: modelContext)
                let progress = DIContainer.shared.userProgressRepository(context: modelContext)
                vm = HomeViewModel(stats: stats, progress: progress)
            }
            vm?.refresh()
        }
        .enableInjection()
    }

    // MARK: - Setup

    private var setupCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "graduationcap")
                .font(.title2)
                .foregroundStyle(theme.accent)
                .padding(.top, 4)
            Text("Welcome to \(Constants.appName)")
                .font(.headline)
            Text("Pick your state to start practicing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { router.navigate(to: .statePicker) } label: {
                Text("Get started")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Dashboard

    @ViewBuilder
    private func dashboard(vm: HomeViewModel) -> some View {
        metaRow(vm: vm)
        countdownCard(examDate: vm.examDate, urgency: vm.urgencyTier)

        if let resume = vm.resume {
            resumeCard(resume: resume)
        }

        if vm.dueReviewCount > 0 {
            dailyReviewCard(vm: vm)
        }

        if let weakest = vm.weakestCategory {
            weaknessSpotlightCard(stat: weakest)
        }

        readinessCard(value: vm.passingProbability)
        quickActionsRow
        mockExamCTAIfAvailable(vm: vm)

        if !vm.categoryStats.isEmpty {
            sectionHeader(title: "Categories", trailing: "See all") {
                router.navigate(to: .categoryList)
            }
            categoriesList(stats: vm.categoryStats)
        }

        sectionHeader(title: "Library", trailing: nil) {}
        libraryRow
    }

    // MARK: - Meta row (streak + daily goal)

    private func metaRow(vm: HomeViewModel) -> some View {
        HStack(spacing: 10) {
            streakBanner(days: vm.streakDays)
            Spacer(minLength: 0)
            dailyGoalPill(answered: vm.answeredToday, goal: vm.dailyGoal)
        }
        .padding(.horizontal, 2)
    }

    private func dailyGoalPill(answered: Int, goal: Int) -> some View {
        let progress = min(1.0, Double(answered) / Double(max(goal, 1)))
        let reached = answered >= goal
        let tint: Color = reached ? .green : theme.accent
        return HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: max(0.001, progress))
                    .rotation(.degrees(-90))
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                if reached {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 14, height: 14)
            Text("\(answered)/\(goal)")
                .font(.footnote.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
            Text("today")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Resume

    private func resumeCard(resume: ResumeSnapshot) -> some View {
        Button {
            router.startSession(.resumeQuizSession(sessionId: resume.sessionId), gatedBy: appState)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue \(resume.categoryName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text("\(resume.answered) of \(resume.total) answered")
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(Self.relativeFormatter.localizedString(for: resume.lastActivityAt, relativeTo: Date()))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.accent.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    // MARK: - Weakness spotlight

    private func weaknessSpotlightCard(stat: CategoryStats) -> some View {
        Button {
            router.navigate(to: .practiceTestList(categoryCode: stat.code))
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "target")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus: \(stat.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("Avg \(Int(stat.avgScore * 100))% · practice 10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mock exam CTA (requires mixed exam spec)

    @ViewBuilder
    private func mockExamCTAIfAvailable(vm: HomeViewModel) -> some View {
        if hasMixedExamSpec(license: vm.licenseCode, state: vm.stateCode) {
            mockExamCard
        } else {
            EmptyView()
        }
    }

    private func hasMixedExamSpec(license: String?, state: String?) -> Bool {
        guard let license, !license.isEmpty, let state, !state.isEmpty else { return false }
        let spec = try? DIContainer.shared.contentRepository.examSpec(
            licenseCode: license,
            stateCode: state,
            categoryCode: nil
        )
        return spec != nil
    }

    private var mockExamCard: some View {
        Button {
            router.navigate(to: .categoryList) // TODO: wire dedicated mock exam builder when spec is seeded
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Take a full mock exam")
                        .font(.subheadline.weight(.semibold))
                    Text("State-spec'd · timed · scored")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak banner (top)

    private func streakBanner(days: Int) -> some View {
        let isActive = days > 0
        let tint: Color = isActive ? theme.celebration : .secondary

        return HStack(spacing: 6) {
            Image(systemName: isActive ? "flame.fill" : "flame")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(isActive ? "\(days)-day streak" : "Start a streak today")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
            Text("·")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Text(isActive ? "Keep it going" : "Answer a question")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Countdown

    @ViewBuilder
    private func countdownCard(examDate: Date?, urgency: UrgencyTier) -> some View {
        let colors = countdownGradient(for: urgency)
        Button { router.navigate(to: .examDatePicker) } label: {
            ZStack {
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let examDate {
                    countdownCardContent(examDate: examDate, urgency: urgency)
                } else {
                    countdownCardEmpty
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: colors.first?.opacity(0.25) ?? .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func countdownGradient(for urgency: UrgencyTier) -> [Color] {
        switch urgency {
        case .none: return [theme.accent, theme.gradientStart]
        case .warning: return [theme.accent, theme.gradientStart]
        case .critical: return [theme.warning, theme.warning.opacity(0.8)]
        }
    }

    private func urgencyPrefix(for urgency: UrgencyTier) -> String? {
        switch urgency {
        case .none: return nil
        case .warning: return "Focus on weak areas"
        case .critical: return "Final stretch — review daily"
        }
    }

    private func countdownCardContent(examDate: Date, urgency: UrgencyTier) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, examDate.timeIntervalSince(context.date))
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("Your exam date \(Self.examDateFormatter.string(from: examDate))")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "pencil")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                if let note = urgencyPrefix(for: urgency) {
                    Text(note)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentWarmLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(theme.accentWarm.opacity(0.18)))
                }

                HStack(spacing: 0) {
                    countdownTile(value: days(from: remaining), label: "days")
                    countdownSeparator
                    countdownTile(value: hours(from: remaining), label: "hrs")
                    countdownSeparator
                    countdownTile(value: minutes(from: remaining), label: "min")
                    countdownSeparator
                    countdownTile(value: seconds(from: remaining), label: "sec")
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
        }
    }

    private var countdownCardEmpty: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Set your exam date")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Track your countdown and stay on pace.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
    }

    private func countdownTile(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(theme.accentWarmLight)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    private var countdownSeparator: some View {
        Circle()
            .fill(theme.accentWarmLight.opacity(0.6))
            .frame(width: 3, height: 3)
            .offset(y: -6)
    }

    private func days(from seconds: TimeInterval) -> Int { Int(seconds) / 86_400 }
    private func hours(from seconds: TimeInterval) -> Int { (Int(seconds) % 86_400) / 3_600 }
    private func minutes(from seconds: TimeInterval) -> Int { (Int(seconds) % 3_600) / 60 }
    private func seconds(from seconds: TimeInterval) -> Int { Int(seconds) % 60 }

    private static let examDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("d MMMM")
        return f
    }()

    // MARK: - Daily review

    private func dailyReviewCard(vm: HomeViewModel) -> some View {
        let count = vm.dueReviewCount
        let batch = min(count, vm.dueBatchSize)
        return Button {
            startDailyReviewSession(vm: vm)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.celebration.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.celebration)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily review")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(count) due · review \(batch) now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(count)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.celebration)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.celebration.opacity(0.14))
                    .clipShape(Capsule())
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func startDailyReviewSession(vm: HomeViewModel) {
        guard let license = vm.licenseCode, !license.isEmpty,
              let state = vm.stateCode, !state.isEmpty,
              !vm.dueReviewIds.isEmpty else { return }
        let config = QuizConfig(
            kind: .weak,
            licenseCode: license,
            stateCode: state,
            categoryCode: nil,
            questionIds: Array(vm.dueReviewIds.prefix(vm.dueBatchSize)),
            passThreshold: 0.8,
            timeLimitSec: nil
        )
        router.startSession(.quizSession(config: config), gatedBy: appState)
    }

    // MARK: - Readiness

    private func readinessCard(value: Double) -> some View {
        let tint = readinessTint(for: value)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.001, value))
                    .rotation(.degrees(-90))
                    .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                Text("\(Int(value * 100))%")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness")
                    .font(.subheadline.weight(.semibold))
                Text(readinessMessage(for: value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func readinessMessage(for value: Double) -> String {
        switch value {
        case 0: return "Take a practice test to see your score."
        case 0..<0.5: return "Early days — keep practicing."
        case 0.5..<0.75: return "Getting close to passing."
        default: return "You're ready."
        }
    }

    private func readinessTint(for value: Double) -> Color {
        switch value {
        case 0: return Color(.systemGray3)
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }

    // MARK: - Quick actions (Simulator removed — no mixed CDL spec seeded yet)

    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            quickAction(
                icon: "list.bullet.rectangle",
                label: "Practice",
                tint: theme.accent
            ) { router.navigate(to: .categoryList) }

            quickAction(
                icon: "exclamationmark.triangle",
                label: "Weak Qs",
                tint: .orange
            ) { router.navigate(to: .weakQuestions) }
        }
    }

    private func quickAction(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(label)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Categories

    private func categoriesList(stats: [CategoryStats]) -> some View {
        let rows = Array(stats.prefix(5))
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.code) { idx, stat in
                Button {
                    router.navigate(to: .practiceTestList(categoryCode: stat.code))
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(stat.attempts == 0 ? "No attempts" : "\(stat.attempts) attempt\(stat.attempts == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(stat.avgScore * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(scoreTint(for: stat.avgScore, attempts: stat.attempts))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                if idx < rows.count - 1 {
                    Divider().padding(.leading, 14)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func scoreTint(for value: Double, attempts: Int) -> Color {
        guard attempts > 0 else { return .secondary }
        switch value {
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }

    // MARK: - Library

    private var libraryRow: some View {
        HStack(spacing: 8) {
            // Cheat Sheets hidden until content is seeded.
            libraryTile(
                icon: "book",
                label: "Handbooks",
                tint: theme.accent,
                locked: !appState.isProUser
            ) {
                if appState.isProUser {
                    router.navigate(to: .handbook)
                } else {
                    DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "handbook"])
                    appState.showPaywall()
                }
            }
            libraryTile(icon: "bookmark", label: "Bookmarks", tint: theme.accent) {
                router.navigate(to: .bookmarks)
            }
        }
    }

    private func libraryTile(
        icon: String,
        label: String,
        tint: Color,
        locked: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(tint)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .offset(x: 8, y: -4)
                    }
                }
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(title: String, trailing: String?, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            if let trailing {
                Button(trailing, action: action)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(.top, 12)
    }
}
