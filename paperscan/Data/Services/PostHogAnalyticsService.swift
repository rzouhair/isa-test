import Foundation
import PostHog

final class PostHogAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    func initialize() {
        #if !DEBUG
        let config = PostHogConfig(apiKey: Constants.posthogAPIKey, host: Constants.posthogHost)
        config.captureScreenViews = true
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)
        #endif
    }

    func capture(_ event: AnalyticsEvent, properties: [String: Any]) {
        #if !DEBUG
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
        #endif
    }

    func screen(_ name: String) {
        #if !DEBUG
        PostHogSDK.shared.screen(name)
        #endif
    }

    func reset() {
        #if !DEBUG
        PostHogSDK.shared.reset()
        #endif
    }
}
