@_exported import Inject
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    @State private var router = Router()
    @State private var showPaywallCrown: Bool = false
    @ObserveInjection var inject
    
    @State private var selectedPage: Int = 0
    
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
    
    @State private var isCameraViewShown = true
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Group {
                if !DIContainer.shared.userRepository.onboardingIsFinished() {
                    setupOnboardingView()
                } else {
                    TabView(selection: $selectedPage) {
                        ForEach(Array(router.tabViewRoutes.enumerated()), id: \.element) { index, route in
                            ScrollView {
                                getDestinationView(destination: route)
                            }
                            .tag(index)
                        }
                    }
                    .navigationTitle(router.tabViewRoutes[selectedPage].title)
                    .navigationBarTitleDisplayMode(.automatic)
                    .onAppear {
                        UITabBar.appearance().isHidden = true
                    }
                    
                    HighlightTabBar(selectedPage: $selectedPage)
                }
            }
            .navigationDestination(for: Router.Route.self) { route in
                getDestinationView(destination: route)
            }
            .sheet(item: $router.presentedSheet) { route in
                getDestinationView(destination: route)
            }
            .toolbar {
                if DIContainer.shared.userRepository.onboardingIsFinished() {
                    if showPaywallCrown {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                if !appState.isProUser {
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
                PaywallYearlyView(isPresented: isPaywallShown)
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
                        print("Requested")
                        appState.showPaywall()
                    }
                    print("====== root appearance ======")
                }
            }
        }
        .environment(router)
        .enableInjection()
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
        case .collection:
            CollectionView()
        case .detection(let images):
            BanknoteDetectionView(images: images)
        case .banknoteDetails(let banknote):
            BanknoteDetailView(banknote: banknote)
        case .settings:
            setupSettingsView()
        default:
            Text("Screen Not Found")
        }
    }
}

#Preview {
    var appState = AppState()
    
    RootView()
        .environment(appState)
        .tint(.appPrimary)
}
