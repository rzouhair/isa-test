import XCTest
import SwiftData
@testable import examprep

@MainActor
final class StatsRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var progress: SwiftDataUserProgressRepository!
    var content: GRDBContentRepository!
    var stats: DefaultStatsRepository!

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
        progress = SwiftDataUserProgressRepository(context: context)
        content = GRDBContentRepository()
        stats = DefaultStatsRepository(content: content, progress: progress)
    }

    func testPassingProbabilityRisesWithGoodScores() throws {
        try progress.setProfile(licenseCode: "car", stateCode: "CA", examDate: nil)
        for score in [0.7, 0.8, 0.85, 0.9, 0.95] {
            let s = PracticeSession(
                kind: .practice,
                licenseCode: "car",
                stateCode: "CA",
                questionIds: [1, 2, 3]
            )
            try progress.createSession(s)
            try progress.completeSession(id: s.id, score: score)
        }
        let p = stats.passingProbability(licenseCode: "car", stateCode: "CA")
        XCTAssertGreaterThan(p, 0.1)
        XCTAssertLessThanOrEqual(p, 1.0)
    }

    func testWeakQuestionIdsSurfaceLearningAndWeak() throws {
        try progress.recordAnswer(questionId: 11, correct: false, timeMs: 1000)
        try progress.recordAnswer(questionId: 11, correct: false, timeMs: 1000)
        try progress.recordAnswer(questionId: 22, correct: true, timeMs: 1000)

        let ids = stats.weakQuestionIds(limit: 10)
        XCTAssertTrue(ids.contains(11))
        XCTAssertFalse(ids.contains(22), "Mastered questions must not surface as weak")
    }

    func testExamCountdownFutureDate() throws {
        let future = Date().addingTimeInterval(48 * 3600)
        try progress.setProfile(licenseCode: "car", stateCode: "CA", examDate: future)
        let seconds = stats.examCountdownSeconds()
        XCTAssertNotNil(seconds)
        XCTAssertGreaterThan(seconds ?? 0, 47 * 3600)
    }

    func testExamCountdownNilWhenUnset() throws {
        try progress.setProfile(licenseCode: "car", stateCode: "CA", examDate: nil)
        XCTAssertNil(stats.examCountdownSeconds())
    }
}
