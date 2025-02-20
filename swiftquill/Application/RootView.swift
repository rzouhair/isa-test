import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    @State private var router = Router()
    
    @State private var selectedPage: Int = 0
    
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
    
    var isUserLoggedIn: Bool {
        DIContainer.shared.userRepository.isUserLoggedIn()
    }
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Group {
                if !DIContainer.shared.userRepository.onboardingIsFinished() {
                    setupOnboardingView()
                } else if !isUserLoggedIn {
                    setupSigninView()
                } else {
                    TabView(selection: $selectedPage) {
                        ForEach(Array(router.tabViewRoutes.enumerated()), id: \.element) { index, route in
                            getDestinationView(destination: route)
                                .tabItem {
                                    Label(route.title, systemImage: route.iconName)
                                }
                                .tag(index)
                        }
                    }
                    .navigationTitle(router.tabViewRoutes[selectedPage].title)
                }
            }
            .navigationDestination(for: Router.Route.self) { route in
                getDestinationView(destination: route)
            }
            .sheet(item: $router.presentedSheet) { route in
                getDestinationView(destination: route)
            }
            .toolbar {
                if DIContainer.shared.userRepository.onboardingIsFinished() && DIContainer.shared.userRepository.isUserLoggedIn() {
                    if !appState.isProUser {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                appState.showPaywall()
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
                // SailPaywallView(
                    // viewModel: PaywallViewModel()
                // )
                
                PaywallYearlyView(isPresented: isPaywallShown)
            }
            .onAppear {
                if appState.shouldShowPaywall && DIContainer.shared.userRepository.onboardingIsFinished() {
                    appState.showPaywall()
                }
            }
        }
        .environment(router)
    }
    
    @ViewBuilder
    func setupOnboardingView () -> some View {
        OnboardingView(onEvent: { event in
            switch event {
            case .finishButtonTapped:
                DIContainer.shared.userRepository.setOnboardingIsFinished()
                router.navigate(to: .home)
            case .skipButtonTapped:
                DIContainer.shared.userRepository.setOnboardingIsFinished()
                router.navigate(to: .home)
            }
        })
    }
    
    @ViewBuilder
    func setupSettingsView () -> some View {
        SettingsView(
            viewModel: SettingsViewModel(onEvent: { event in
                switch event {
                case .deleteAccount:
                    DIContainer.shared.userRepository.deleteAccount()
                    // router.navigate(to: .login, replace: true)
                    router.dismissSheet()
                case .logout:
                    DIContainer.shared.userRepository.signOut()
                    // router.navigate(to: .login, replace: true)
                    router.dismissSheet()
                }
            })
        )
    }

    @ViewBuilder
    func setupSigninView () -> some View {
        SignInView(
            viewModel: SignInView.ViewModel(onEvent: { event in
                switch event {
                case .signInSuccessful:
                    print("Successful Login")
                    router.navigateToRoot()
                    // router.navigate(to: .home)
                }
            })
        )
    }
    
    @ViewBuilder
    func getDestinationView (destination: Router.Route) -> some View {
        switch destination {
        case .onboarding:
            setupOnboardingView()
        case .login:
            setupSigninView()
        case .home:
            ChatView()
        case .settings:
            setupSettingsView()
        default:
            Text("Screen Not Found")
        }
    }
}
