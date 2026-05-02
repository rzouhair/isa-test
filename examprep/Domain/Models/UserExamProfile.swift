import Foundation
import SwiftData

@Model
final class UserExamProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var licenseCode: String        // always "cdl" for v1; kept as field for future license-type expansion
    var stateCode: String          // "CA"
    var examDate: Date?
    var dailyGoalQuestions: Int = 20
    var preferredLang: String = "en"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(licenseCode: String, stateCode: String, examDate: Date? = nil) {
        self.licenseCode = licenseCode
        self.stateCode = stateCode
        self.examDate = examDate
    }
}
