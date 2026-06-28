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
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(theme.accent)
                .padding(.top, 4)
            Text("Welcome to \(Constants.appName)")
                .font(.headline)
            Text("Practice 750 ISA Certified Arborist questions and 250 atomic flashcards across 10 domains.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                let progress = DIContainer.shared.userProgressRepository(context: modelContext)
                if progress.profile() == nil {
                    try? progress.setProfile(licenseCode: Constants.licenseCode, examDate: nil)
                }
                vm?.refresh()
            } label: {
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
    //
    // Layout, top-to-bottom:
    //   headerCard       — streak + daily goal + readiness ring + accuracy + Answered, taps to Progress tab
    //   examDateRow      — slim CTA pill (no exam date) or compact countdown row (date set)
    //   resumeCard       — only when an unfinished session exists
    //   dailyReviewCard  — only when due > 0
    //   actionStrip      — horizontal pills: Mock Exam · Weak Qs · Flashcards · Bookmarks
    //   Topics grid      — primary action surface (always shown)

    @ViewBuilder
    private func dashboard(vm: HomeViewModel) -> some View {
        headerCard(vm: vm)
        examDateRow(examDate: vm.examDate)

        if let resume = vm.resume {
            resumeCard(resume: resume)
        }

        if vm.dueReviewCount > 0 {
            dailyReviewCard(vm: vm)
        }

        actionStrip(vm: vm)

        sectionHeader(title: "Topics", trailing: "See all") {
            router.navigate(to: .categoryList)
        }
        topicsGrid(stats: vm.categoryStats)
    }

    // MARK: - Header card (streak + goal + readiness + accuracy in one card)

    private func headerCard(vm: HomeViewModel) -> some View {
        Button {
            appState.selectedTab = 1   // Progress tab
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    streakChip(days: vm.streakDays)
                    goalChip(answered: vm.answeredToday, goal: vm.dailyGoal)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Text("Progress")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                }

                Divider()

                HStack(spacing: 14) {
                    readinessInline(value: vm.passingProbability)
                    Spacer(minLength: 0)
                    statColumn(
                        value: vm.totalAnswered == 0 ? "—" : "\(Int(vm.lifetimeAccuracy * 100))%",
                        label: "Accuracy",
                        tint: accuracyTint(vm.lifetimeAccuracy, hasData: vm.totalAnswered > 0)
                    )
                    Divider().frame(height: 28)
                    statColumn(value: "\(vm.totalAnswered)", label: "Answered")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func streakChip(days: Int) -> some View {
        let active = days > 0
        let tint: Color = active ? theme.celebration : .secondary
        return HStack(spacing: 4) {
            Image(systemName: active ? "flame.fill" : "flame")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(active ? "\(days)-day" : "No streak")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private func goalChip(answered: Int, goal: Int) -> some View {
        let reached = answered >= goal
        let tint: Color = reached ? .green : theme.accent
        return HStack(spacing: 4) {
            Image(systemName: reached ? "checkmark.circle.fill" : "target")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text("\(answered)/\(goal) today")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private func readinessInline(value: Double) -> some View {
        let tint = readinessTint(for: value)
        return HStack(spacing: 8) {
            ZStack {
                Circle().stroke(Color(.systemFill), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: max(0.001, value))
                    .rotation(.degrees(-90))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Text("\(Int(value * 100))%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text("Readiness")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(value == 0 ? "Take a test" : "Pass-ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statColumn(value: String, label: String, tint: Color = .primary) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func accuracyTint(_ value: Double, hasData: Bool) -> Color {
        guard hasData else { return .secondary }
        switch value {
        case 0..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
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

    // MARK: - Exam date (slim row)

    @ViewBuilder
    private func examDateRow(examDate: Date?) -> some View {
        Button { router.navigate(to: .examDatePicker) } label: {
            if let date = examDate {
                let days = max(0, Int(date.timeIntervalSinceNow / 86_400))
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(theme.accent)
                    Text("\(days) day\(days == 1 ? "" : "s") to exam")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(Self.examDateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundStyle(.white)
                    Text("Set your exam date")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(theme.accent)
                .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private static let examDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("d MMM")
        return f
    }()

    // MARK: - Resume

    private func resumeCard(resume: ResumeSnapshot) -> some View {
        Button {
            router.startSession(.resumeQuizSession(sessionId: resume.sessionId), gatedBy: appState)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(theme.accent))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue \(resume.categoryName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(resume.answered) of \(resume.total) · \(Self.relativeFormatter.localizedString(for: resume.lastActivityAt, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
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

    // MARK: - Daily review

    private func dailyReviewCard(vm: HomeViewModel) -> some View {
        let count = vm.dueReviewCount
        let batch = min(count, vm.dueBatchSize)
        return Button {
            startDailyReviewSession(vm: vm)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.celebration)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(theme.celebration.opacity(0.18)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily review")
                        .font(.subheadline.weight(.semibold))
                    Text("\(count) due · review \(batch) now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(count)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.celebration)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(theme.celebration.opacity(0.14))
                    .clipShape(Capsule())
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func startDailyReviewSession(vm: HomeViewModel) {
        guard let license = vm.licenseCode, !license.isEmpty,
              !vm.dueReviewIds.isEmpty else { return }
        let config = QuizConfig(
            kind: .weak,
            licenseCode: license,
            categoryCode: nil,
            questionIds: Array(vm.dueReviewIds.prefix(vm.dueBatchSize)),
            passThreshold: 0.76,
            timeLimitSec: nil
        )
        router.startSession(.quizSession(config: config), gatedBy: appState)
    }

    // MARK: - Topics grid (always shown, even with zero attempts)

    private func topicsGrid(stats: [CategoryStats]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(stats.enumerated()), id: \.element.code) { idx, stat in
                topicTile(stat: stat, color: CategoryPalette.color(at: idx))
            }
        }
    }

    private func topicTile(stat: CategoryStats, color: Color) -> some View {
        Button {
            router.navigate(to: .practiceTestList(categoryCode: stat.code))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: topicIcon(for: stat.code))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if stat.attempts > 0 {
                        Text("\(Int(stat.avgScore * 100))%")
                            .font(.caption2.bold().monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }
                Spacer(minLength: 2)
                Text(stat.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(stat.attempts == 0 ? "Tap to start" : "\(stat.attempts) attempt\(stat.attempts == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func topicIcon(for code: String) -> String {
        switch code {
        case "tree_biology": return "leaf.fill"
        case "identification_and_selection": return "magnifyingglass"
        case "soil_management": return "square.grid.3x3.fill"
        case "installation_and_establishment": return "shovel.fill"
        case "pruning": return "scissors"
        case "diagnosis_and_treatment": return "stethoscope"
        case "tree_protection": return "shield.fill"
        case "tree_risk_management": return "exclamationmark.triangle.fill"
        case "safe_work_practices": return "hammer.fill"
        case "urban_forestry": return "building.2.fill"
        default: return "leaf.fill"
        }
    }

    // MARK: - Action strip (Mock Exam / Weak Qs / Flashcards / Bookmarks)

    private func actionStrip(vm: HomeViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if hasMixedExamSpec(license: vm.licenseCode) {
                    actionPill(icon: "doc.text.magnifyingglass", label: "Mock Exam", tint: theme.accent) {
                        startFullMockExam(vm: vm)
                    }
                }
                actionPill(icon: "bolt.fill", label: "Weak Qs", tint: .orange) {
                    router.navigate(to: .weakQuestions)
                }
                actionPill(icon: "rectangle.stack.fill", label: "Flashcards", tint: theme.accent) {
                    router.navigate(to: .flashcardsLibrary)
                }
                actionPill(icon: "bookmark.fill", label: "Bookmarks", tint: theme.accent) {
                    router.navigate(to: .bookmarks)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func actionPill(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption.weight(.semibold))
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func hasMixedExamSpec(license: String?) -> Bool {
        guard let license, !license.isEmpty else { return false }
        let spec = try? DIContainer.shared.contentRepository.examSpec(
            licenseCode: license,
            categoryCode: nil
        )
        return spec != nil
    }

    private func startFullMockExam(vm: HomeViewModel) {
        guard let license = vm.licenseCode, !license.isEmpty,
              let spec = try? DIContainer.shared.contentRepository.examSpec(
                licenseCode: license,
                categoryCode: nil
              ) else { return }

        let pool = (try? DIContainer.shared.contentRepository.questions(
            licenseCode: license,
            categoryCode: nil,
            lang: "en",
            limit: spec.questionCount
        )) ?? []
        let ids = pool.map(\.0.id)
        guard !ids.isEmpty else { return }

        let config = QuizConfig(
            kind: .simulator,
            licenseCode: license,
            categoryCode: nil,
            questionIds: ids,
            passThreshold: spec.passThreshold,
            timeLimitSec: spec.timeLimitSec
        )
        router.startSession(.quizSession(config: config), gatedBy: appState)
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
        .padding(.top, 4)
    }
}
