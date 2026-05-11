import Foundation

protocol ContentRepositoryProtocol: Sendable {
    func allLicenses() throws -> [LicenseDTO]
    func categories(licenseCode: String) throws -> [CategoryDTO]

    /// Returns questions paired with answer rows, joined and grouped.
    /// - Parameter limit: if nil, returns all; otherwise random N.
    func questions(licenseCode: String,
                   categoryCode: String?,
                   lang: String,
                   limit: Int?) throws -> [(QuestionDTO, [AnswerDTO])]

    func question(id: Int) throws -> (QuestionDTO, [AnswerDTO])?
    func questions(ids: [Int]) throws -> [(QuestionDTO, [AnswerDTO])]

    func examSpec(licenseCode: String, categoryCode: String?) throws -> ExamSpecDTO?

    /// [category_code: total question count] for a license.
    func questionCounts(licenseCode: String, lang: String) throws -> [String: Int]

    // MARK: Flashcards

    func flashcards(licenseCode: String, categoryCode: String?, lang: String) throws -> [FlashcardDTO]
    func flashcard(id: Int) throws -> FlashcardDTO?
    func flashcards(ids: [Int]) throws -> [FlashcardDTO]
    func flashcardCounts(licenseCode: String, lang: String) throws -> [String: Int]
}
