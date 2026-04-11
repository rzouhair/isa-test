import Foundation

enum AnalyticsEvent: String, Sendable {
    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingStepSkipped = "onboarding_step_skipped"
    case onboardingCameraPermission = "onboarding_camera_permission"
    case onboardingCompleted = "onboarding_completed"

    // Scanning (Scanner flow)
    case scanStarted = "scan_started"
    case scanSubmitted = "scan_submitted"
    case scanCompleted = "scan_completed"
    case scanFailed = "scan_failed"
    case scanRetried = "scan_retried"

    // Detection (legacy flow)
    case detectionStarted = "detection_started"
    case detectionCompleted = "detection_completed"
    case detectionFailed = "detection_failed"

    // Purchases
    case paywallViewed = "paywall_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseRestored = "purchase_restored"

    // Collections
    case collectionCreated = "collection_created"
    case cardAddedToCollection = "card_added_to_collection"

    // General
    case appOpened = "app_opened"
}
