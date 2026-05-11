import Foundation
import SwiftData

@Model
final class UserExamProfile {
    @Attribute(.unique) var id: UUID = UUID()
    /// Always "isa" for v1; kept as field for future certification-type expansion.
    var licenseCode: String
    var examDate: Date?
    var dailyGoalQuestions: Int = 20
    var preferredLang: String = "en"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(licenseCode: String = Constants.licenseCode, examDate: Date? = nil) {
        self.licenseCode = licenseCode
        self.examDate = examDate
    }
}
