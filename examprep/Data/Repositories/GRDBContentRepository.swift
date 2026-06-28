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
                   categoryCode: String?,
                   lang: String,
                   limit: Int?) throws -> [(QuestionDTO, [AnswerDTO])] {
        var sql = """
            SELECT q.id, q.license_id, q.category_id, q.text,
                   q.explanation, q.image_name, q.difficulty, q.lang
            FROM questions q
            JOIN licenses l ON l.id = q.license_id
            LEFT JOIN categories c ON c.id = q.category_id
            WHERE l.code = ? AND q.lang = ?
        """
        var args: [SQLValue] = [.text(licenseCode), .text(lang)]
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
            SELECT id, license_id, category_id, text, explanation, image_name, difficulty, lang
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
            SELECT id, license_id, category_id, text, explanation, image_name, difficulty, lang
            FROM questions WHERE id IN (\(placeholders))
        """, args: args, map: mapQuestion)
        let byId = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
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

    func questionCounts(licenseCode: String, lang: String) throws -> [String: Int] {
        let rows = try db.query("""
            SELECT c.code, COUNT(q.id)
            FROM questions q
            JOIN licenses l ON l.id = q.license_id
            JOIN categories c ON c.id = q.category_id
            WHERE l.code = ? AND q.lang = ?
            GROUP BY c.code
        """, args: [.text(licenseCode), .text(lang)]) { row in
            (row.text(0), row.int(1))
        }
        return Dictionary(uniqueKeysWithValues: rows)
    }

    // MARK: Exam spec

    func examSpec(licenseCode: String, categoryCode: String?) throws -> ExamSpecDTO? {
        var sql = """
            SELECT e.id, e.license_id, e.category_id,
                   e.question_count, e.pass_threshold, e.time_limit_sec
            FROM exam_specs e
            JOIN licenses l ON l.id = e.license_id
            LEFT JOIN categories c ON c.id = e.category_id
            WHERE l.code = ?
        """
        var args: [SQLValue] = [.text(licenseCode)]
        if let categoryCode {
            sql += " AND c.code = ?"
            args.append(.text(categoryCode))
        } else {
            sql += " AND e.category_id IS NULL"
        }
        sql += " LIMIT 1"
        return try db.query(sql, args: args) { row in
            ExamSpecDTO(
                id: row.int(0), licenseId: row.int(1),
                categoryId: row.intOrNil(2), questionCount: row.int(3),
                passThreshold: row.double(4), timeLimitSec: row.intOrNil(5)
            )
        }.first
    }

    // MARK: Flashcards

    func flashcards(licenseCode: String, categoryCode: String?, lang: String) throws -> [FlashcardDTO] {
        var sql = """
            SELECT f.id, f.license_id, f.category_id, f.type, f.front, f.back,
                   f.tags_json, f.source, f.lang
            FROM flashcards f
            JOIN licenses l ON l.id = f.license_id
            LEFT JOIN categories c ON c.id = f.category_id
            WHERE l.code = ? AND f.lang = ?
        """
        var args: [SQLValue] = [.text(licenseCode), .text(lang)]
        if let categoryCode {
            sql += " AND c.code = ?"
            args.append(.text(categoryCode))
        }
        sql += " ORDER BY f.sort_order, f.id"
        return try db.query(sql, args: args, map: mapFlashcard)
    }

    func flashcard(id: Int) throws -> FlashcardDTO? {
        try db.query("""
            SELECT id, license_id, category_id, type, front, back, tags_json, source, lang
            FROM flashcards WHERE id = ?
        """, args: [.int(id)], map: mapFlashcard).first
    }

    func flashcards(ids: [Int]) throws -> [FlashcardDTO] {
        guard !ids.isEmpty else { return [] }
        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        let args = ids.map { SQLValue.int($0) }
        let cards = try db.query("""
            SELECT id, license_id, category_id, type, front, back, tags_json, source, lang
            FROM flashcards WHERE id IN (\(placeholders))
        """, args: args, map: mapFlashcard)
        let byId = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
        return ids.compactMap { byId[$0] }
    }

    func flashcardCounts(licenseCode: String, lang: String) throws -> [String: Int] {
        let rows = try db.query("""
            SELECT c.code, COUNT(f.id)
            FROM flashcards f
            JOIN licenses l ON l.id = f.license_id
            JOIN categories c ON c.id = f.category_id
            WHERE l.code = ? AND f.lang = ?
            GROUP BY c.code
        """, args: [.text(licenseCode), .text(lang)]) { row in
            (row.text(0), row.int(1))
        }
        return Dictionary(uniqueKeysWithValues: rows)
    }

    // MARK: Row → DTO

    private func mapQuestion(_ row: SQLRow) -> QuestionDTO {
        QuestionDTO(
            id: row.int(0), licenseId: row.int(1), categoryId: row.int(2),
            text: row.text(3), explanation: row.textOrNil(4),
            imageName: row.textOrNil(5), difficulty: row.int(6), lang: row.text(7)
        )
    }

    private func mapAnswer(_ row: SQLRow) -> AnswerDTO {
        AnswerDTO(
            id: row.int(0), questionId: row.int(1), text: row.text(2),
            isCorrect: row.int(3), sortOrder: row.int(4)
        )
    }

    private func mapFlashcard(_ row: SQLRow) -> FlashcardDTO {
        let tagsJson = row.textOrNil(6) ?? "[]"
        let tags = (try? JSONDecoder().decode([String].self, from: Data(tagsJson.utf8))) ?? []
        return FlashcardDTO(
            id: row.int(0), licenseId: row.int(1), categoryId: row.int(2),
            type: row.text(3), front: row.text(4), back: row.text(5),
            tags: tags, source: row.textOrNil(7), lang: row.text(8)
        )
    }
}

/// Kept for call-site compatibility with the pre-rewrite GRDB name.
typealias GRDBContentRepository = SQLiteContentRepository
