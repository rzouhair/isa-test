import XCTest
import SwiftData
@testable import examprep

@MainActor
final class LearnLevelServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([
            UserExamProfile.self,
            QuestionAttempt.self,
            PracticeSession.self,
            SessionAnswer.self,
            BookmarkedQuestion.self,
            StudyStreak.self,
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
    }

    func testLevel1AlwaysUnlocked() {
        let ids = Array(1...30)
        let levels = LearnLevelService.buildLevels(questionIds: ids, attempts: [])
        XCTAssertEqual(levels.count, 3)
        XCTAssertFalse(levels[0].locked)
        XCTAssertTrue(levels[1].locked)
        XCTAssertTrue(levels[2].locked)
    }

    func testLevel2UnlocksWhenLevel1Mastered() {
        let ids = Array(1...25)

        // Mark 8 of 10 level-1 questions as mastered (80% ≥ threshold).
        var attempts: [QuestionAttempt] = []
        for qid in 1...8 {
            let a = QuestionAttempt(questionId: qid)
            a.status = .mastered
            attempts.append(a)
            context.insert(a)
        }

        let levels = LearnLevelService.buildLevels(questionIds: ids, attempts: attempts)
        XCTAssertFalse(levels[0].locked)
        XCTAssertFalse(levels[1].locked, "Level 2 should unlock at 80% level-1 mastery")
        XCTAssertTrue(levels[2].locked, "Level 3 must still be locked")
    }

    func testPartialMasteryDoesNotUnlock() {
        let ids = Array(1...20)

        // 7 of 10 mastered — below the 80% threshold.
        var attempts: [QuestionAttempt] = []
        for qid in 1...7 {
            let a = QuestionAttempt(questionId: qid)
            a.status = .mastered
            attempts.append(a)
            context.insert(a)
        }

        let levels = LearnLevelService.buildLevels(questionIds: ids, attempts: attempts)
        XCTAssertFalse(levels[0].locked)
        XCTAssertTrue(levels[1].locked)
    }

    func testChunkingPreservesSortOrder() {
        let ids = [30, 11, 5, 22, 1, 16, 3, 27, 8, 19, 4]     // unsorted, 11 ids
        let levels = LearnLevelService.buildLevels(questionIds: ids, attempts: [])
        XCTAssertEqual(levels.count, 2)
        XCTAssertEqual(levels[0].questionIds, [1, 3, 4, 5, 8, 11, 16, 19, 22, 27])
        XCTAssertEqual(levels[1].questionIds, [30])
    }
}
