import Foundation
import SwiftUI
import SwiftData
import RevenueCat

@main
struct AppMain: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    @State private var appState = AppState()

    let modelContainer: ModelContainer

    @MainActor
    init() {
        Purchases.configure(
            with: Configuration.builder(withAPIKey: Constants.revenueCat)
                .with(storeKitVersion: .storeKit2)
                .build()
        )

        do {
            modelContainer = try ModelContainer(for: ScanRecord.self, CardRecord.self, CardCollection.self, WatchlistItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
                .tint(theme.accent)
        }
    }
}
