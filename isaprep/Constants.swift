import Foundation

class Constants {
    static let appName = "ISA Arborist Prep"
    static let privacyPolicyUrl = "https://www.notion.so/ISA-Arborist-Exam-Prep-Privacy-Policy-3574d383e47680aca19cf83d66d14371?source=copy_link"
    static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appleEulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let supportEmail = "rouikaalt@gmail.com"  // TODO: replace with ISA-specific support address

    // RevenueCat — keep existing SDK key until a new app record is provisioned.
    // Entitlement ID must match the RevenueCat dashboard exactly.
    static let revenueCat = "appl_jVxyuIHicoWvOJdaAAVSxwejMwX"
    static let revenueCatProEntitlement = "ISA Exam Prep Pro"  // TODO: rename in dashboard
    static let revenueCatDefaultOffering = "Pro"
    static let revenueCatYearlyPackage = "$rc_annual"
    static let revenueCatWeeklyPackage = "$rc_weekly"

    // PostHog
    static let posthogAPIKey = "phc_yrpKbGUmHd4ixTRT3Admzj3Af3RM6BDojGH4fpavDMJB"  // TODO: rotate for new app
    static let posthogHost = "https://us.i.posthog.com"

    // Sentry
    static let sentryDSN = "https://6a565a2c385b8220ded6c0accc7ab6b8@o4511191277371392.ingest.us.sentry.io/4511191343169536"  // TODO: rotate

    static let appStoreId = ""  // TODO: set on submission

    // MARK: - License code
    /// Single supported license. ISA Certified Arborist.
    static let licenseCode = "isa"

    // MARK: - Feature flags

    // MARK: - AI Tutor (disabled — not used in ISA reskin)

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

    // MARK: - Disclaimers

    /// Shown in Settings/About. Required because ~33% of MCQs and all atomic
    /// flashcards are AI-authored study aids aligned to ISA standards but are
    /// not actual ISA exam questions.
    static let isaContentDisclaimer = """
    Roughly one-third of practice questions and all atomic flashcards in this app are AI-authored \
    study items aligned to the ISA Certified Arborist Study Guide, ANSI A300, ANSI Z133, \
    ANSI Z60.1, and ISA Best Management Practices. They are not actual ISA exam questions \
    (those are proprietary to the International Society of Arboriculture). Use this app as a \
    study aid, not a leak of the real exam.
    """
}
