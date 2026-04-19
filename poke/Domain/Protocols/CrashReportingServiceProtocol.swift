import Foundation

protocol CrashReportingServiceProtocol: Sendable {
    func initialize()
    func captureError(_ error: Error, context: [String: Any])
    func captureMessage(_ message: String)
    func addBreadcrumb(category: String, message: String)
    func identifyUser(revenueCatId: String)
}

extension CrashReportingServiceProtocol {
    func identifyUser(revenueCatId: String) {}
}

extension CrashReportingServiceProtocol {
    func captureError(_ error: Error) {
        captureError(error, context: [:])
    }
}
