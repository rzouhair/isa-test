import Foundation

// Read-only DTOs mirroring `exam_content.sqlite` rows.

struct LicenseDTO: Codable, Sendable, Hashable {
    let id: Int
    let code: String
    let name: String
    let icon: String?
}

struct CategoryDTO: Codable, Sendable, Hashable {
    let id: Int
    let licenseId: Int
    let code: String
    let name: String
    let kind: String           // "core" | "endorsement"
    let sortOrder: Int
}

struct QuestionDTO: Codable, Sendable, Hashable {
    let id: Int
    let licenseId: Int
    let categoryId: Int
    let text: String
    let explanation: String?
    let imageName: String?
    let difficulty: Int
    let lang: String
}

struct AnswerDTO: Codable, Sendable, Hashable {
    let id: Int
    let questionId: Int
    let text: String
    let isCorrect: Int         // 0/1
    let sortOrder: Int
}

struct FlashcardDTO: Codable, Sendable, Hashable {
    let id: Int
    let licenseId: Int
    let categoryId: Int
    let type: String           // "concept" | "definition" | "list" | "key_value" | "id_key" | "mnemonic" | "standard"
    let front: String
    let back: String
    let tags: [String]
    let source: String?
    let lang: String
}

struct ExamSpecDTO: Codable, Sendable, Hashable {
    let id: Int
    let licenseId: Int
    let categoryId: Int?
    let questionCount: Int
    let passThreshold: Double
    let timeLimitSec: Int?
}
