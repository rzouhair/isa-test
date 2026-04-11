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

        WatchlistPriceService.modelContainer = modelContainer
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(modelContainer)
                .tint(theme.accent)
                .task {
                    await WatchlistPriceService.shared.checkOnAppOpen()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await WatchlistPriceService.shared.checkOnAppOpen() }
                    }
                }
        }
    }
}
