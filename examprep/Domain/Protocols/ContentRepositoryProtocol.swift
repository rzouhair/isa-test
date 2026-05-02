import Foundation

protocol ContentRepositoryProtocol: Sendable {
    func allLicenses() throws -> [LicenseDTO]
    func allStates() throws -> [StateDTO]
    func categories(licenseCode: String) throws -> [CategoryDTO]

    /// Returns questions paired with answer rows, joined and grouped.
    /// - Parameter limit: if nil, returns all; otherwise random N.
    func questions(licenseCode: String,
                   stateCode: String,
                   categoryCode: String?,
                   lang: String,
                   limit: Int?) throws -> [(QuestionDTO, [AnswerDTO])]

    func question(id: Int) throws -> (QuestionDTO, [AnswerDTO])?
    func questions(ids: [Int]) throws -> [(QuestionDTO, [AnswerDTO])]

    func cheatSheets(licenseCode: String, stateCode: String?, lang: String) throws -> [CheatSheetDTO]
    func handbook(licenseCode: String, stateCode: String, lang: String) throws -> HandbookDTO?
    func examSpec(licenseCode: String, stateCode: String, categoryCode: String?) throws -> ExamSpecDTO?

    /// Returns [category_code: total question count] for a license in a state
    /// (federal questions included). One SQL query per call.
    func questionCounts(licenseCode: String, stateCode: String, lang: String) throws -> [String: Int]
}
