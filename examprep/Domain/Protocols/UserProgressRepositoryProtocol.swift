import Foundation

protocol UserProgressRepositoryProtocol {
    // Profile
    func profile() -> UserExamProfile?
    @discardableResult
    func setProfile(licenseCode: String, stateCode: String, examDate: Date?) throws -> UserExamProfile
    func updateExamDate(_ date: Date?) throws

    // Attempts
    func attempt(for questionId: Int) -> QuestionAttempt?
    func recordAnswer(questionId: Int, correct: Bool, timeMs: Int) throws
    func allAttempts() -> [QuestionAttempt]

    // Sessions
    func createSession(_ session: PracticeSession) throws
    func appendSessionAnswer(sessionId: UUID, questionId: Int, selectedAnswerId: Int?, correct: Bool, timeMs: Int) throws
    func completeSession(id: UUID, score: Double) throws
    func deleteSession(id: UUID) throws
    func updateSessionElapsed(id: UUID, seconds: Int) throws
    func purgeIncompleteSessions(olderThan: Date) throws
    func session(id: UUID) -> PracticeSession?
    func sessions(limit: Int) -> [PracticeSession]

    // Bookmarks
    func toggleBookmark(questionId: Int) throws
    func bookmarks() -> [Int]
    func isBookmarked(_ questionId: Int) -> Bool

    // Streak
    func incrementStreak(minutes: Int, questions: Int) throws
    func currentStreakDays() -> Int
}
