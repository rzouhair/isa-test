import Foundation

struct CategoryStats: Sendable, Hashable {
    let code: String
    let name: String
    let avgScore: Double
    let attempts: Int
    let lastAttemptedAt: Date?
}

struct CategoryProgress: Sendable, Hashable {
    let code: String
    let name: String
    let iconName: String          // SF symbol
    let attemptedDistinct: Int    // DISTINCT question ids answered across all sessions
    let totalQuestions: Int       // size of the category pool for this license/state/lang
    let avgTestScore: Double      // 0–1, mean of practice/simulator session scores in this category

    var completionRatio: Double {
        totalQuestions == 0 ? 0 : min(1, Double(attemptedDistinct) / Double(totalQuestions))
    }
}

protocol StatsRepositoryProtocol {
    func categoryStats(licenseCode: String, stateCode: String) -> [CategoryStats]
    func categoryProgress(licenseCode: String, stateCode: String, lang: String) -> [CategoryProgress]
    func passingProbability(licenseCode: String, stateCode: String) -> Double
    func weakQuestionIds(limit: Int) -> [Int]
    /// Questions whose `nextReviewAt` is in the past (oldest-due first).
    /// Falls back to weak/learning attempts with no schedule yet (legacy rows).
    func dueReviewIds(limit: Int) -> [Int]
    /// Count of questions currently due for review (unbounded).
    func dueReviewCount() -> Int
    /// Seconds until the user's exam date, or nil if not set / in the past.
    func examCountdownSeconds() -> TimeInterval?
    func currentStreakDays() -> Int
}
