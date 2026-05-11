import XCTest
import SwiftData
@testable import isaprep

@MainActor
final class UserProgressRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var repo: SwiftDataUserProgressRepository!

    override func setUp() async throws {
        let schema = Schema([
            UserExamProfile.self,
            QuestionAttempt.self,
            PracticeSession.self,
            SessionAnswer.self,
            BookmarkedQuestion.self,
            StudyStreak.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        repo = SwiftDataUserProgressRepository(context: context)
    }

    func testSetAndFetchProfile() throws {
        try repo.setProfile(licenseCode: "car", stateCode: "CA", examDate: nil)
        let profile = repo.profile()
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.licenseCode, "car")
        XCTAssertEqual(profile?.stateCode, "CA")
    }

    func testRecordAnswerTransitionsStatus() throws {
        try repo.recordAnswer(questionId: 1, correct: true, timeMs: 2500)
        XCTAssertEqual(repo.attempt(for: 1)?.status, .mastered)

        try repo.recordAnswer(questionId: 1, correct: false, timeMs: 4000)
        XCTAssertEqual(repo.attempt(for: 1)?.status, .reviewing)

        try repo.recordAnswer(questionId: 1, correct: false, timeMs: 3000)
        XCTAssertEqual(repo.attempt(for: 1)?.status, .weak)

        try repo.recordAnswer(questionId: 1, correct: true, timeMs: 2000)
        XCTAssertEqual(repo.attempt(for: 1)?.status, .reviewing)
    }

    func testToggleBookmark() throws {
        XCTAssertFalse(repo.isBookmarked(42))
        try repo.toggleBookmark(questionId: 42)
        XCTAssertTrue(repo.isBookmarked(42))
        XCTAssertEqual(repo.bookmarks(), [42])
        try repo.toggleBookmark(questionId: 42)
        XCTAssertFalse(repo.isBookmarked(42))
    }

    func testSessionRoundTrip() throws {
        let session = PracticeSession(
            kind: .practice,
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            questionIds: [1, 2, 3]
        )
        try repo.createSession(session)
        XCTAssertEqual(session.questionIds, [1, 2, 3])

        try repo.completeSession(id: session.id, score: 0.9)
        let fetched = repo.sessions(limit: 10).first
        XCTAssertEqual(fetched?.score, 0.9)
        XCTAssertNotNil(fetched?.endedAt)
    }

    func testStreakIncrement() throws {
        try repo.incrementStreak(minutes: 5, questions: 10)
        XCTAssertEqual(repo.currentStreakDays(), 1)
    }
}
