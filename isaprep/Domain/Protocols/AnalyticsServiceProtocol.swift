import Foundation

protocol AnalyticsServiceProtocol: Sendable {
    func initialize()
    func capture(_ event: AnalyticsEvent, properties: [String: Any])
    func screen(_ name: String)
    func reset()
}

extension AnalyticsServiceProtocol {
    func capture(_ event: AnalyticsEvent) {
        capture(event, properties: [:])
    }
}
