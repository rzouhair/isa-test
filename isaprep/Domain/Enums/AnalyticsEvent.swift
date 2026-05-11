import Foundation

enum AnalyticsEvent: String, Sendable {
    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingStepSkipped = "onboarding_step_skipped"
    case onboardingCompleted = "onboarding_completed"
    case trialCloseScreen1Viewed = "trial_close_screen_1_viewed"
    case trialCloseScreen2Viewed = "trial_close_screen_2_viewed"
    case trialCloseScreen2Tapped = "trial_close_screen_2_tapped"

    // Exam setup
    case licenseSelected = "license_selected"
    case stateSelected = "state_selected"
    case examDateSet = "exam_date_set"

    // Practice & Learn
    case quizStarted = "quiz_started"
    case questionAnswered = "question_answered"
    case quizCompleted = "quiz_completed"
    case learnSessionStarted = "learn_session_started"
    case weakQuestionMastered = "weak_question_mastered"

    // Content
    case cheatSheetViewed = "cheat_sheet_viewed"
    case handbookOpened = "handbook_opened"
    case bookmarkToggled = "bookmark_toggled"

    // Purchases
    case paywallViewed = "paywall_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseRestored = "purchase_restored"

    // General
    case appOpened = "app_opened"
    case settingsOpened = "settings_opened"
}
