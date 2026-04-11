@_exported import Inject
import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    @State private var router = Router()
    @State private var showPaywallCrown: Bool = false
    @ObserveInjection var inject
    
    private var selectedPage: Binding<Int> {
        Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )
    }
    
    init() {
        InjectConfiguration.animation = .interactiveSpring()
    }
    
    var isPaywallShown: Binding<Bool> {
        Binding(
            get: {
                appState.isPaywallShown
            },
            set: { newValue in
                appState.isPaywallShown = newValue
            }
        )
    }

    var isFullScreenCoverShown: Binding<Bool> {
        Binding(
            get: {
                router.presentedFullscreenCover != nil
            },
            set: {newValue in }
        )
    }
    
    #if DEBUG
    @State private var debugAPIStatus: String = ""
    #endif


    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Group {
                if !DIContainer.shared.userRepository.onboardingIsFinished() {
                    setupOnboardingView()
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        TabView(selection: selectedPage) {
                            HomeView()
                                .tabItem { Label("Home", systemImage: "house") }
                                .tag(0)

                            WatchlistView()
                                .tabItem { Label("Watchlist", systemImage: "eye") }
                                .tag(1)

                            CollectionsGridView()
                                .tabItem { Label("Collections", systemImage: "square.stack") }
                                .tag(2)
                        }

                        // Floating scan button
                        Button {
                            if appState.isProUser {
                                router.presentFullscreenCover(.scanner)
                                DIContainer.shared.analyticsService.capture(.scanStarted)
                            } else {
                                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "scan_button"])
                                appState.showPaywall()
                            }
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(theme.accent)
                                .clipShape(Circle())
                                .shadow(color: theme.accent.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 70)
                    }
                    .navigationTitle(tabTitle)
                    .navigationBarTitleDisplayMode(.large)
                    .onAppear {
                        showPaywallCrown = !appState.isProUser
                    }
                }
            }
            .navigationDestination(for: Router.Route.self) { route in
                getDestinationView(destination: route)
            }
            .sheet(item: $router.presentedSheet) { route in
                NavigationStack {
                    getDestinationView(destination: route)
                }
            }
            .toolbar {
                if DIContainer.shared.userRepository.onboardingIsFinished() {
                    if showPaywallCrown {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                if !appState.isProUser {
                                    DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "crown_tap"])
                                    appState.showPaywall()
                                }
                            } label: {
                                Image(systemName: "crown")
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            router.presentSheet(.settings)
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: isPaywallShown) {
                // PaywallYearlyView(isPresented: isPaywallShown)
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        Task {
                            await SubscriptionService.shared.loadProStatus()
                            appState.isPaywallShown = false
                            showPaywallCrown = !appState.isProUser
                            TrialCloseViewModel.scheduleTrialReminderIfNeeded(customerInfo: customerInfo)
                            UIApplication.showAlert(title: "🎉 Congratulations!", message: "Your Pro subscription was successfully activated and all Pro features were unlocked!")
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        Task {
                            await SubscriptionService.shared.loadProStatus()
                            appState.isPaywallShown = false
                            showPaywallCrown = !appState.isProUser
                            TrialCloseViewModel.scheduleTrialReminderIfNeeded(customerInfo: customerInfo)
                            UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro features were unlocked!")
                        }
                    }
            }
            .fullScreenCover(isPresented: isFullScreenCoverShown) {
                if (router.presentedFullscreenCover != nil) {
                    getDestinationView(destination: router.presentedFullscreenCover!)
                }
            }
            .onAppear {
                Task {
                    await SubscriptionService.shared.loadProStatus()

                    showPaywallCrown = !appState.isProUser
                    print("====== root appearance ======")
                    print(appState.shouldShowPaywall)
                    print(DIContainer.shared.userRepository.onboardingIsFinished())
                    print(appState.isProUser)
                    if appState.shouldShowPaywall && DIContainer.shared.userRepository.onboardingIsFinished() && !appState.isProUser {
                        DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "auto"])
                        appState.showPaywall()
                    }
                    DIContainer.shared.analyticsService.capture(.appOpened)
                    print("====== root appearance ======")
                }
            }
        }
        .environment(router)
        .enableInjection()
    }


    private var tabTitle: String {
        switch appState.selectedTab {
        case 0: return "Home"
        case 1: return "Watchlist"
        case 2: return "Collections"
        default: return ""
        }
    }

    @ViewBuilder
    func setupOnboardingView () -> some View {
        /* OnboardingView(onEvent: { event in
            DIContainer.shared.userRepository.setOnboardingIsFinished()
            router.navigateToRoot()
        }) */
        OnboardingFlowView()
    }
    
    @ViewBuilder
    func setupSettingsView () -> some View {
        SettingsView(
            viewModel: SettingsViewModel(onEvent: { event in
                switch event {
                  default:
                    router.dismissSheet()
                }
            })
        )
    }
    
    @ViewBuilder
    func getDestinationView (destination: Router.Route) -> some View {
        switch destination {
        case .onboarding:
            setupOnboardingView()
        case .home:
            HomeView()
        case .camera:
            CameraCaptureView()
        case .detection(let images):
            DetectionView(images: images)
        case .settings:
            setupSettingsView()
        case .scanner:
            ScannerView()
        case .collection:
            CollectionView()
        case .cardDetail(let card):
            CardDetailView(card: card)
        case .collectionDetail(let collection):
            CollectionDetailView(collection: collection)
        case .search:
            SearchView()
        case .watchlist:
            WatchlistView()
        default:
            Text("Screen Not Found")
        }
    }
}

// MARK: - Debug API Validation

#if DEBUG
extension RootView {
    func debugTestCardIdentifier() async {
        let service = DIContainer.shared.cardIdentifierService
        print("🔵 [DEBUG] Starting card identifier API test...")

        // Use a tiny 1x1 white PNG as test payload
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==")!

        do {
            let submitResponse = try await service.submitJob(imageData: testImageData)
            print("🟢 [DEBUG] Job submitted — jobId: \(submitResponse.jobId), status: \(submitResponse.status)")

            // Poll until complete or failed
            var attempts = 0
            let maxAttempts = 30
            while attempts < maxAttempts {
                try await Task.sleep(for: .seconds(2))
                attempts += 1

                let statusResponse = try await service.checkStatus(jobId: submitResponse.jobId)
                let scanStatus = ScanStatus(apiStatus: statusResponse.status)
                print("🔵 [DEBUG] Poll \(attempts) — API status: \(statusResponse.status), mapped: \(scanStatus)")

                switch scanStatus {
                case .complete:
                    if let result = statusResponse.result {
                        print("🟢 [DEBUG] Card identified!")
                        print("  Name: \(result.cardData?.product.name ?? "nil")")
                        print("  Platform: \(result.cardData?.product.platform ?? "nil")")
                        print("  Market price: \(result.cardData?.pricing?.marketPrice.map { String($0) } ?? "nil")")
                        print("  Confidence: \(result.metadata?.confidence ?? 0)")
                        print("  Game: \(result.metadata?.game ?? "nil")")
                    }
                    return
                case .failed:
                    print("🔴 [DEBUG] Job failed: \(statusResponse.error ?? "unknown")")
                    return
                case .pending, .processing:
                    continue
                }
            }
            print("🟡 [DEBUG] Timed out after \(maxAttempts) polls")
        } catch {
            print("🔴 [DEBUG] Error: \(error)")
        }
    }
}
#endif

#Preview {
    var appState = AppState()
    
    RootView()
        .environment(appState)
        .tint(theme.accent)
}
