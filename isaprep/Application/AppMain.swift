import Foundation
import SwiftUI
import SwiftData
import RevenueCat

@main
struct AppMain: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()

    let modelContainer: ModelContainer

    @MainActor
    init() {
        ReviewPromptService.recordInstallIfNeeded()

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        Purchases.configure(
            with: Configuration.builder(withAPIKey: Constants.revenueCat)
                .with(storeKitVersion: .storeKit2)
                .build()
        )

        do {
            modelContainer = try ModelContainer(for:
                UserExamProfile.self,
                QuestionAttempt.self,
                PracticeSession.self,
                SessionAnswer.self,
                BookmarkedQuestion.self,
                BookmarkedFlashcard.self,
                FlashcardReview.self,
                StudyStreak.self
            )
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "model_container_init", "critical": true]
            )
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
                .tint(theme.accent)
                .task {
                    if DemoDataSeeder.shouldRun() {
                        DemoDataSeeder.seed(into: modelContainer.mainContext)
                    }
                }
        }
    }
}
