import Foundation
import SwiftUI
import RevenueCat

@main
struct AppMain: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    @State private var appState = AppState()

    @MainActor
    init() {
        Purchases.configure(
            with: Configuration.builder(withAPIKey: Constants.revenueCat)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .tint(.appPrimary)
        }
    }
}
