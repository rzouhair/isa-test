import Foundation

/// Reads content from the bundled read-only SQLite DB.
/// File name retained for git-history continuity; implementation uses raw
/// sqlite3 (no external dependency).
final class SQLiteContentRepository: ContentRepositoryProtocol {
    private let db: ContentDatabase

    init(database: ContentDatabase = .shared) {
        self.db = database
    }

    // MARK: Reference tables

    func allLicenses() throws -> [LicenseDTO] {
        try db.query("SELECT id, code, name, icon FROM licenses ORDER BY id") { row in
            LicenseDTO(id: row.int(0), code: row.text(1), name: row.text(2), icon: row.textOrNil(3))
        }
    }

    func allStates() throws -> [StateDTO] {
        try db.query("SELECT id, code, name FROM states ORDER BY name") { row in
            StateDTO(id: row.int(0), code: row.text(1), name: row.text(2))
        }
    }

    func categories(licenseCode: String) throws -> [CategoryDTO] {
        try db.query("""
            SELECT c.id, c.license_id, c.code, c.name, c.kind, c.sort_order
            FROM categories c
            JOIN licenses l ON l.id = c.license_id
            WHERE l.code = ?
            ORDER BY c.sort_order, c.id
        """, args: [.text(licenseCode)]) { row in
            CategoryDTO(
                id: row.int(0), licenseId: row.int(1), code: row.text(2),
                name: row.text(3), kind: row.text(4), sortOrder: row.int(5)
            )
        }
    }

    // MARK: Questions

    func questions(licenseCode: String,
                   stateCode: String,
                   categoryCode: String?,
                   lang: String,
                   limit: Int?) throws -> [(QuestionDTO, [AnswerDTO])] {
        var sql = """
            SELECT q.id, q.license_id, q.category_id, q.state_id, q.text,
                   q.explanation, q.image_name, q.difficulty, q.lang
            FROM questions q
            JOIN licenses l ON l.id = q.license_id
            LEFT JOIN states s ON s.id = q.state_id
            LEFT JOIN categories c ON c.id = q.category_id
            WHERE l.code = ?
              AND (q.state_id IS NULL OR s.code = ?)
              AND q.lang = ?
        """
        var args: [SQLValue] = [.text(licenseCode), .text(stateCode), .text(lang)]
        if let categoryCode {
            sql += " AND c.code = ?"
            args.append(.text(categoryCode))
        }
        sql += limit != nil ? " ORDER BY RANDOM()" : " ORDER BY q.id"
        if let limit { sql += " LIMIT \(limit)" }

        let questions = try db.query(sql, args: args, map: mapQuestion)
        return try attachAnswers(questions: questions)
    }

    func question(id: Int) throws -> (QuestionDTO, [AnswerDTO])? {
        let qs = try db.query("""
            SELECT id, license_id, category_id, state_id, text, explanation, image_name, difficulty, lang
            FROM questions WHERE id = ?
        """, args: [.int(id)], map: mapQuestion)
        guard let q = qs.first else { return nil }
        let answers = try db.query("""
            SELECT id, question_id, text, is_correct, sort_order
            FROM answers WHERE question_id = ? ORDER BY sort_order
        """, args: [.int(id)], map: mapAnswer)
        return (q, answers)
    }

    func questions(ids: [Int]) throws -> [(QuestionDTO, [AnswerDTO])] {
        guard !ids.isEmpty else { return [] }
        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        let args = ids.map { SQLValue.int($0) }
        let questions = try db.query("""
            SELECT id, license_id, category_id, state_id, text, explanation, image_name, difficulty, lang
            FROM questions WHERE id IN (\(placeholders))
        """, args: args, map: mapQuestion)
        let byId = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
        // Preserve requested order.
        let ordered = ids.compactMap { byId[$0] }
        return try attachAnswers(questions: ordered)
    }

    private func attachAnswers(questions: [QuestionDTO]) throws -> [(QuestionDTO, [AnswerDTO])] {
        guard !questions.isEmpty else { return [] }
        let ids = questions.map(\.id)
        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        let args = ids.map { SQLValue.int($0) }
        let all = try db.query("""
            SELECT id, question_id, text, is_correct, sort_order
            FROM answers WHERE question_id IN (\(placeholders))
            ORDER BY question_id, sort_order
        """, args: args, map: mapAnswer)
        let grouped = Dictionary(grouping: all, by: { $0.questionId })
        return questions.map { ($0, grouped[$0.id] ?? []) }
    }

    // MARK: Aggregate

    func questionCounts(licenseCode: String, stateCode: String, lang: String) throws -> [String: Int] {
        let rows = try db.query("""
            SELECT c.code, COUNT(q.id)
            FROM questions q
            JOIN licenses l ON l.id = q.license_id
            JOIN categories c ON c.id = q.category_id
            LEFT JOIN states s ON s.id = q.state_id
            WHERE l.code = ?
              AND q.lang = ?
              AND (q.state_id IS NULL OR s.code = ?)
            GROUP BY c.code
        """, args: [.text(licenseCode), .text(lang), .text(stateCode)]) { row in
            (row.text(0), row.int(1))
        }
        return Dictionary(uniqueKeysWithValues: rows)
    }

    // MARK: Content extras

    func cheatSheets(licenseCode: String, stateCode: String?, lang: String) throws -> [CheatSheetDTO] {
        var sql = """
            SELECT cs.id, cs.license_id, cs.state_id, cs.title, cs.body_md, cs.cover_image, cs.lang
            FROM cheat_sheets cs
            JOIN licenses l ON l.id = cs.license_id
            LEFT JOIN states s ON s.id = cs.state_id
            WHERE l.code = ? AND cs.lang = ?
        """
        var args: [SQLValue] = [.text(licenseCode), .text(lang)]
        if let stateCode {
            sql += " AND (cs.state_id IS NULL OR s.code = ?)"
            args.append(.text(stateCode))
        }
        sql += " ORDER BY cs.id"
        return try db.query(sql, args: args) { row in
            CheatSheetDTO(
                id: row.int(0), licenseId: row.int(1), stateId: row.intOrNil(2),
                title: row.text(3), bodyMd: row.text(4),
                coverImage: row.textOrNil(5), lang: row.text(6)
            )
        }
    }

    func handbook(licenseCode: String, stateCode: String, lang: String) throws -> HandbookDTO? {
        try db.query("""
            SELECT h.id, h.state_id, h.license_id, h.title, h.pdf_name, h.body_md, h.version, h.lang
            FROM handbooks h
            JOIN licenses l ON l.id = h.license_id
            JOIN states s ON s.id = h.state_id
            WHERE l.code = ? AND s.code = ? AND h.lang = ?
            LIMIT 1
        """, args: [.text(licenseCode), .text(stateCode), .text(lang)]) { row in
            HandbookDTO(
                id: row.int(0), stateId: row.int(1), licenseId: row.int(2),
                title: row.text(3), pdfName: row.textOrNil(4), bodyMd: row.textOrNil(5),
                version: row.textOrNil(6), lang: row.text(7)
            )
        }.first
    }

    func examSpec(licenseCode: String, stateCode: String, categoryCode: String?) throws -> ExamSpecDTO? {
        var sql = """
            SELECT e.id, e.state_id, e.license_id, e.category_id,
                   e.question_count, e.pass_threshold, e.time_limit_sec
            FROM exam_specs e
            JOIN licenses l ON l.id = e.license_id
            JOIN states s ON s.id = e.state_id
            LEFT JOIN categories c ON c.id = e.category_id
            WHERE l.code = ? AND s.code = ?
        """
        var args: [SQLValue] = [.text(licenseCode), .text(stateCode)]
        if let categoryCode {
            sql += " AND c.code = ?"
            args.append(.text(categoryCode))
        } else {
            sql += " AND e.category_id IS NULL"
        }
        sql += " LIMIT 1"
        return try db.query(sql, args: args) { row in
            ExamSpecDTO(
                id: row.int(0), stateId: row.int(1), licenseId: row.int(2),
                categoryId: row.intOrNil(3), questionCount: row.int(4),
                passThreshold: row.double(5), timeLimitSec: row.intOrNil(6)
            )
        }.first
    }

    // MARK: Row → DTO

    private func mapQuestion(_ row: SQLRow) -> QuestionDTO {
        QuestionDTO(
            id: row.int(0), licenseId: row.int(1), categoryId: row.int(2),
            stateId: row.intOrNil(3), text: row.text(4),
            explanation: row.textOrNil(5), imageName: row.textOrNil(6),
            difficulty: row.int(7), lang: row.text(8)
        )
    }

    private func mapAnswer(_ row: SQLRow) -> AnswerDTO {
        AnswerDTO(
            id: row.int(0), questionId: row.int(1), text: row.text(2),
            isCorrect: row.int(3), sortOrder: row.int(4)
        )
    }
}

/// Kept for call-site compatibility with the pre-rewrite GRDB name.
typealias GRDBContentRepository = SQLiteContentRepository
