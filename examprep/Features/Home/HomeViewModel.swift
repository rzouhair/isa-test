import Foundation
import Observation

struct ResumeSnapshot: Sendable, Hashable {
    let sessionId: UUID
    let categoryCode: String?
    let categoryName: String
    let answered: Int
    let total: Int
    let lastActivityAt: Date
}

@MainActor
@Observable
final class HomeViewModel {
    var countdownSeconds: TimeInterval?
    var examDate: Date?
    var passingProbability: Double = 0
    var categoryStats: [CategoryStats] = []
    var streakDays: Int = 0
    var dueReviewCount: Int = 0
    var licenseCode: String?
    var stateCode: String?
    var hasProfile: Bool { licenseCode != nil && !(stateCode ?? "").isEmpty }
    var dailyGoal: Int = 20
    var answeredToday: Int = 0
    var resume: ResumeSnapshot?
    var weakestCategory: CategoryStats?
    var dueReviewIds: [Int] = []
    let dueBatchSize: Int = 20

    private let stats: StatsRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol

    init(stats: StatsRepositoryProtocol, progress: UserProgressRepositoryProtocol) {
        self.stats = stats
        self.progress = progress
    }

    func refresh() {
        // Purge incomplete sessions older than the cutoff so stale rows can't surface as "Continue".
        let cutoff = Date().addingTimeInterval(-Self.incompleteSessionTTL)
        try? progress.purgeIncompleteSessions(olderThan: cutoff)

        let profile = progress.profile()
        licenseCode = profile?.licenseCode
        stateCode = profile?.stateCode
        examDate = profile?.examDate
        dailyGoal = max(1, profile?.dailyGoalQuestions ?? 20)
        countdownSeconds = stats.examCountdownSeconds()
        streakDays = stats.currentStreakDays()
        dueReviewCount = stats.dueReviewCount()
        dueReviewIds = stats.dueReviewIds(limit: dueBatchSize)

        guard let profile, !profile.licenseCode.isEmpty, !profile.stateCode.isEmpty else {
            passingProbability = 0
            categoryStats = []
            resume = nil
            weakestCategory = nil
            answeredToday = 0
            return
        }
        passingProbability = stats.passingProbability(
            licenseCode: profile.licenseCode,
            stateCode: profile.stateCode
        )
        categoryStats = stats.categoryStats(
            licenseCode: profile.licenseCode,
            stateCode: profile.stateCode
        )
        weakestCategory = computeWeakest(stats: categoryStats)
        resume = latestIncompleteResume(license: profile.licenseCode, state: profile.stateCode)
        answeredToday = answeredTodayCount()
    }

    private func computeWeakest(stats: [CategoryStats]) -> CategoryStats? {
        let attempted = stats.filter { $0.attempts > 0 }
        guard let lowest = attempted.min(by: { $0.avgScore < $1.avgScore }) else { return nil }
        return lowest.avgScore < 0.75 ? lowest : nil
    }

    private func latestIncompleteResume(license: String, state: String) -> ResumeSnapshot? {
        let sessions = progress.sessions(limit: 20)
        let match = sessions.first { session in
            session.licenseCode == license
                && session.stateCode == state
                && session.endedAt == nil
        }
        guard let last = match else { return nil }
        let answered = last.answers.count
        let total = last.questionIds.count
        guard total > 0, answered < total else { return nil }
        let categoryName = categoryStats.first(where: { $0.code == last.categoryCode })?.name
        let fallback = last.categoryCode?.capitalized ?? "Practice"
        let answerDates: [Date] = last.answers.map { $0.answeredAt }
        let lastActivity = answerDates.max() ?? last.startedAt
        return ResumeSnapshot(
            sessionId: last.id,
            categoryCode: last.categoryCode,
            categoryName: categoryName ?? fallback,
            answered: answered,
            total: total,
            lastActivityAt: lastActivity
        )
    }

    private func answeredTodayCount() -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let sessions = progress.sessions(limit: 50)
        var count = 0
        for session in sessions {
            let startedToday = session.startedAt >= startOfDay
            let endedToday = session.endedAt.map { $0 >= startOfDay } ?? false
            if startedToday || endedToday {
                count += session.answers.count
            }
        }
        return count
    }

    var urgencyTier: UrgencyTier {
        guard let countdownSeconds else { return .none }
        let days = Int(countdownSeconds / 86_400)
        if days <= 3 { return .critical }
        if days <= 14 { return .warning }
        return .none
    }
}

enum UrgencyTier {
    case none, warning, critical
}

extension HomeViewModel {
    static let incompleteSessionTTL: TimeInterval = 30 * 24 * 60 * 60  // 30 days
}
