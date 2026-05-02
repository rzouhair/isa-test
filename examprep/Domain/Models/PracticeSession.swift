import Foundation
import SwiftData

enum SessionKind: String, Codable, Sendable {
    case practice, simulator, learn, weak, bookmark
}

@Model
final class PracticeSession {
    @Attribute(.unique) var id: UUID = UUID()
    var kind: SessionKind
    var licenseCode: String
    var stateCode: String
    var categoryCode: String?
    var startedAt: Date = Date()
    var endedAt: Date?
    var score: Double = 0                  // 0.0 – 1.0
    var passThreshold: Double = 0.8
    var timeLimitSec: Int?
    var elapsedSecAtPause: Int = 0         // persisted wall-clock for resume
    var questionIdsJSON: Data              // [Int] JSON-encoded

    @Relationship(deleteRule: .cascade, inverse: \SessionAnswer.session)
    var answers: [SessionAnswer] = []

    init(kind: SessionKind,
         licenseCode: String,
         stateCode: String,
         categoryCode: String? = nil,
         questionIds: [Int],
         passThreshold: Double = 0.8,
         timeLimitSec: Int? = nil) {
        self.kind = kind
        self.licenseCode = licenseCode
        self.stateCode = stateCode
        self.categoryCode = categoryCode
        self.passThreshold = passThreshold
        self.timeLimitSec = timeLimitSec
        self.questionIdsJSON = (try? JSONEncoder().encode(questionIds)) ?? Data()
    }

    var questionIds: [Int] {
        (try? JSONDecoder().decode([Int].self, from: questionIdsJSON)) ?? []
    }

    var passed: Bool { score >= passThreshold }
}
