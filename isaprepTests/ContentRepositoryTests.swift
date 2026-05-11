import XCTest
@testable import isaprep

final class ContentRepositoryTests: XCTestCase {
    var repo: GRDBContentRepository!

    override func setUp() {
        super.setUp()
        repo = GRDBContentRepository()
    }

    func testAllLicensesContainsCarMotorcycleCDL() throws {
        let licenses = try repo.allLicenses()
        let codes = licenses.map(\.code)
        XCTAssertTrue(codes.contains("car"))
        XCTAssertTrue(codes.contains("motorcycle"))
        XCTAssertTrue(codes.contains("cdl"))
    }

    func testAllStatesIncludesCA() throws {
        let states = try repo.allStates()
        XCTAssertTrue(states.contains(where: { $0.code == "CA" }))
    }

    func testCarCategoriesIncludeRoadSigns() throws {
        let cats = try repo.categories(licenseCode: "car")
        XCTAssertTrue(cats.contains(where: { $0.code == "road_signs" }))
    }

    func testQuestionsForCACarGeneralKnowledgeReturnsRows() throws {
        let rows = try repo.questions(
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            lang: "en",
            limit: nil
        )
        XCTAssertGreaterThan(rows.count, 0)
        for (q, answers) in rows {
            XCTAssertFalse(q.text.isEmpty)
            XCTAssertEqual(answers.count, 4, "Expected 4-option MCQ")
            XCTAssertEqual(answers.filter { $0.isCorrect == 1 }.count, 1, "Exactly one correct answer")
        }
    }

    func testQuestionByIdHasMatchingAnswers() throws {
        let any = try repo.questions(
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: nil,
            lang: "en",
            limit: 1
        ).first
        guard let (question, _) = any else { XCTFail("No questions seeded"); return }

        let pair = try repo.question(id: question.id)
        XCTAssertNotNil(pair)
        XCTAssertEqual(pair?.0.id, question.id)
    }

    func testExamSpecForCACDLHazmatExists() throws {
        let spec = try repo.examSpec(licenseCode: "cdl", stateCode: "CA", categoryCode: "hazmat")
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec?.questionCount, 30)
    }

    func testCheatSheetsReturnsSeededSheets() throws {
        let sheets = try repo.cheatSheets(licenseCode: "car", stateCode: nil, lang: "en")
        XCTAssertGreaterThan(sheets.count, 0)
    }

    /// Confirms the CristCDL import landed. Federal questions (state_id NULL)
    /// surface for any requested state via the OR clause in the SQL join.
    func testCDLHazmatHasAtLeastFortyQuestions() throws {
        let rows = try repo.questions(
            licenseCode: "cdl",
            stateCode: "CA",
            categoryCode: "hazmat",
            lang: "en",
            limit: nil
        )
        XCTAssertGreaterThan(rows.count, 40, "Expected >40 hazmat questions after CristCDL import")
        for (_, answers) in rows.prefix(10) {
            XCTAssertGreaterThanOrEqual(answers.count, 3, "Each MCQ should have ≥3 options")
            XCTAssertEqual(answers.filter { $0.isCorrect == 1 }.count, 1, "Exactly one correct answer")
        }
    }

    func testCDLGeneralKnowledgeHasAtLeast100Questions() throws {
        let rows = try repo.questions(
            licenseCode: "cdl",
            stateCode: "TX",
            categoryCode: "general_knowledge",
            lang: "en",
            limit: nil
        )
        XCTAssertGreaterThan(rows.count, 100)
    }
}
