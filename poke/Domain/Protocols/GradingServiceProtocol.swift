import Foundation

protocol GradingServiceProtocol: Sendable {
    func submitGrade(request: GradeRequest) async throws -> GradeResponse
}
