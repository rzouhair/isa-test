import Foundation
import Sentry

final class SentryCrashReportingService: CrashReportingServiceProtocol, @unchecked Sendable {
    func initialize() {
        #if !DEBUG
        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            options.tracesSampleRate = 0.2
            options.attachScreenshot = true
            options.enableMetricKit = true
        }
        #endif
    }

    func captureError(_ error: Error, context: [String: Any]) {
        #if !DEBUG
        let sentryEvent = Sentry.Event(error: error)
        sentryEvent.extra = context
        SentrySDK.capture(event: sentryEvent)
        #endif
    }

    func captureMessage(_ message: String) {
        #if !DEBUG
        SentrySDK.capture(message: message)
        #endif
    }

    func addBreadcrumb(category: String, message: String) {
        #if !DEBUG
        let crumb = Breadcrumb()
        crumb.category = category
        crumb.message = message
        crumb.level = .info
        SentrySDK.addBreadcrumb(crumb)
        #endif
    }
}
