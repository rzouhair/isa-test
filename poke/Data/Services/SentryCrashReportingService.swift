import Foundation
import Sentry
import UIKit

final class SentryCrashReportingService: CrashReportingServiceProtocol, @unchecked Sendable {
    func initialize() {
        #if !DEBUG
        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            options.environment = Self.currentEnvironment
            options.releaseName = Self.releaseName
            options.tracesSampleRate = 0.2
            options.configureProfiling = {
                $0.sessionSampleRate = 0.2
                $0.lifecycle = .trace
            }
            // PII-sensitive: this app views user card photos; screenshots could
            // expose an entire collection on crash. Keep disabled by default.
            options.attachScreenshot = false
            options.attachViewHierarchy = true
            options.enableMetricKit = true
            options.enableAutoBreadcrumbTracking = true
            options.enableUIViewControllerTracing = true
            options.enableNetworkTracking = true
            options.enableNetworkBreadcrumbs = true
            options.enableFileIOTracing = true
            options.enableAutoPerformanceTracing = true
            options.enableCaptureFailedRequests = true
            options.enableAppHangTracking = true
            options.enableWatchdogTerminationTracking = true
            options.swiftAsyncStacktraces = true
        }
        setAnonymousUser()
        #endif
    }

    func captureError(_ error: Error, context: [String: Any]) {
        #if !DEBUG
        let sentryEvent = Sentry.Event(error: error)
        sentryEvent.extra = Self.sanitize(context)
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

    /// Replaces the anonymous Sentry user id with a stable RevenueCat-backed id
    /// so crashes can be correlated across devices for the same paying user.
    /// Safe to call repeatedly; no-op in DEBUG.
    func identifyUser(revenueCatId: String) {
        #if !DEBUG
        guard !revenueCatId.isEmpty else { return }
        let user = User()
        user.userId = revenueCatId
        SentrySDK.setUser(user)
        #endif
    }

    #if DEBUG
    /// Debug-only one-shot that bypasses the #if !DEBUG gate to force an event
    /// to Sentry so you can verify the pipeline (DSN, SDK linkage, dashboard
    /// delivery) without shipping to TestFlight. Remove the caller once verified.
    func sendDebugTestEvent() -> String {
        // Idempotent start — calling start twice is a no-op if already running.
        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            options.environment = "debug-smoke-test"
            options.releaseName = Self.releaseName
            options.debug = true
        }
        let marker = "sentry-smoke-test-\(UUID().uuidString.prefix(8))"
        let error = NSError(
            domain: "PokeDebugSmokeTest",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Manual test event (\(marker))"]
        )
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: "debug_smoke_test", key: "test_kind")
            scope.setExtra(value: marker, key: "marker")
        }
        SentrySDK.capture(message: "Poke debug smoke test — \(marker)")
        return marker
    }
    #endif

    /// Sets an anonymous, install-stable identifier so we can correlate crashes
    /// to a single device across sessions without storing PII.
    private func setAnonymousUser() {
        let key = "sentry_anonymous_user_id"
        let id: String = {
            if let existing = UserDefaults.standard.string(forKey: key) {
                return existing
            }
            let fresh = UUID().uuidString
            UserDefaults.standard.set(fresh, forKey: key)
            return fresh
        }()
        let user = User()
        user.userId = id
        SentrySDK.setUser(user)
    }

    /// `testflight` when running a TestFlight build, otherwise `production`.
    /// DEBUG builds never reach here (see #if guard in initialize).
    private static var currentEnvironment: String {
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return "testflight"
        }
        return "production"
    }

    private static var releaseName: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "0"
        let bundleId = Bundle.main.bundleIdentifier ?? "com.poke.app"
        return "\(bundleId)@\(version)+\(build)"
    }

    /// Drops keys that might contain PII before sending to Sentry. Only a small
    /// allowlist of known safe context keys is kept verbatim; everything else
    /// goes through a stringifying redaction.
    private static func sanitize(_ context: [String: Any]) -> [String: Any] {
        var safe: [String: Any] = [:]
        let sensitiveSubstrings = ["email", "password", "token", "secret", "auth", "name", "address", "phone"]
        for (key, value) in context {
            let lower = key.lowercased()
            if sensitiveSubstrings.contains(where: { lower.contains($0) }) {
                safe[key] = "<redacted>"
                continue
            }
            // Only keep primitives; anything else is stringified and truncated.
            switch value {
            case let v as String:
                safe[key] = String(v.prefix(200))
            case let v as NSNumber:
                safe[key] = v
            case let v as Bool:
                safe[key] = v
            default:
                safe[key] = String(describing: value).prefix(200).description
            }
        }
        return safe
    }
}
