import Foundation

/// Tracks milestone state for SKStoreReviewController prompts.
/// Apple caps `requestReview()` to 3 prompts per 365-day window per app, so
/// we only ask after the user has clear signal of value (≥3 passed sessions,
/// ≥2 days since install, no recent prompt).
enum ReviewPromptService {
    private static let installDateKey = "review.installDate"
    private static let passedCountKey = "review.passedCount"
    private static let lastPromptKey = "review.lastPromptAt"

    private static let minPassedSessions = 3
    private static let minDaysSinceInstall: TimeInterval = 2 * 86_400
    private static let cooldownBetweenPrompts: TimeInterval = 90 * 86_400

    /// Call once at app launch. Idempotent.
    static func recordInstallIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: installDateKey) == nil {
            defaults.set(Date(), forKey: installDateKey)
        }
    }

    /// Increment the passed-session counter and return whether the caller
    /// should fire `requestReview()` right now.
    static func recordPassAndShouldPrompt() -> Bool {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: passedCountKey) + 1
        defaults.set(count, forKey: passedCountKey)

        guard count >= minPassedSessions else { return false }

        let installDate = defaults.object(forKey: installDateKey) as? Date ?? Date()
        guard Date().timeIntervalSince(installDate) >= minDaysSinceInstall else { return false }

        if let lastPrompt = defaults.object(forKey: lastPromptKey) as? Date,
           Date().timeIntervalSince(lastPrompt) < cooldownBetweenPrompts {
            return false
        }

        defaults.set(Date(), forKey: lastPromptKey)
        return true
    }
}
