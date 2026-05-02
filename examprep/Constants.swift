import Foundation

class Constants {
    static let appName = "CDL Exam Prep"
    static let privacyPolicyUrl = "https://www.notion.so/CDL-Hazmat-Practice-Test-Prep-Privacy-Policy-3524d383e4768017bf00fa1604067d85"  // TODO: set before submission
    static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appleEulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let supportEmail = "rouikaalt@gmail.com"  // TODO: update

    // RevenueCat — keep existing SDK key until a new app record is provisioned.
    // Entitlement ID must match the RevenueCat dashboard exactly.
    static let revenueCat = "appl_rmryhNyxuuzLFVOnnKdrTZsdSdR"
    static let revenueCatProEntitlement = "CDL Hazmat Practice Test Prep Pro"
    static let revenueCatDefaultOffering = "Pro"
    static let revenueCatYearlyPackage = "$rc_annual"
    static let revenueCatWeeklyPackage = "$rc_weekly"

    // PostHog
    static let posthogAPIKey = "phc_yrpKbGUmHd4ixTRT3Admzj3Af3RM6BDojGH4fpavDMJB"  // TODO: rotate for new app
    static let posthogHost = "https://us.i.posthog.com"

    // Sentry
    static let sentryDSN = "https://6a565a2c385b8220ded6c0accc7ab6b8@o4511191277371392.ingest.us.sentry.io/4511191343169536"  // TODO: rotate

    static let appStoreId = ""  // TODO: set on submission

    // MARK: - Feature flags

    /// Free cheat-sheet allowance before the paywall takes over. Set to
    /// `.max` for all-free or `0` to paywall everything.
    static let cheatSheetsFreeCount = 2

    // MARK: - AI Tutor (optional, off by default)

    /// Master switch. When false the tutor UI is hidden everywhere.
    static let aiTutorEnabled = false

    /// Gate the tutor behind the Pro entitlement in addition to the flag.
    static let aiTutorProOnly = true

    /// OpenAI-compatible chat completions endpoint. Leave empty to show a
    /// "not configured" fallback instead of making a network call.
    static let aiTutorEndpoint = ""

    /// Bearer token for the above endpoint. Never commit a real key.
    static let aiTutorAPIKey = ""

    /// Model name passed in the request body.
    static let aiTutorModel = "gpt-4o-mini"

    /// Soft daily cap per installation. 0 = unlimited.
    static let aiTutorDailyLimit = 10
}
