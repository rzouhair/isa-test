@_exported import Inject
import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var router = Router()
    @State private var isBootstrapped: Bool = false
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
            get: { appState.isPaywallShown },
            set: { appState.isPaywallShown = $0 }
        )
    }

    var isFullScreenCoverShown: Binding<Bool> {
        Binding(
            get: { router.presentedFullscreenCover != nil },
            set: { _ in }
        )
    }

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            Group {
                if !isBootstrapped {
                    bootstrapSplash
                } else if !DIContainer.shared.userRepository.onboardingIsFinished() {
                    setupOnboardingView()
                } else {
                    TabView(selection: selectedPage) {
                        HomeView()
                            .tabItem { Label("Home", systemImage: "house") }
                            .tag(0)

                        StatsDashboardView()
                            .tabItem { Label("Progress", systemImage: "chart.bar") }
                            .tag(1)
                    }
                    .navigationTitle(tabTitle)
                    .navigationBarTitleDisplayMode(appState.selectedTab == 0 ? .inline : .large)
                }
            }
            .navigationDestination(for: Router.Route.self) { route in
                getDestinationView(destination: route)
            }
            .sheet(item: $router.presentedSheet) { route in
                NavigationStack { getDestinationView(destination: route) }
            }
            .toolbar {
                if DIContainer.shared.userRepository.onboardingIsFinished() {
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
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        Task {
                            await SubscriptionService.shared.loadProStatus()
                            appState.isPaywallShown = false
                            TrialCloseViewModel.scheduleTrialReminderIfNeeded(customerInfo: customerInfo)
                            UIApplication.showAlert(title: "🎉 Congratulations!", message: "Your Pro subscription was successfully activated and all Pro features were unlocked!")
                            appState.triggerPostActivationNotificationPromptIfNeeded()
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        Task {
                            await SubscriptionService.shared.loadProStatus()
                            appState.isPaywallShown = false
                            TrialCloseViewModel.scheduleTrialReminderIfNeeded(customerInfo: customerInfo)
                            UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro features were unlocked!")
                            appState.triggerPostActivationNotificationPromptIfNeeded()
                        }
                    }
            }
            .fullScreenCover(isPresented: isFullScreenCoverShown) {
                if let cover = router.presentedFullscreenCover {
                    getDestinationView(destination: cover)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { appState.isPostActivationNotificationSheetShown },
                set: { if !$0 { appState.dismissPostActivationNotificationSheet() } }
            )) {
                ZStack {
                    LinearGradient(
                        colors: [theme.onboardingBg, theme.gradientEnd, theme.onboardingBg],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).ignoresSafeArea()
                    OnboardingNotificationsStepView(
                        onEnable: { appState.dismissPostActivationNotificationSheet() },
                        onSkip: { appState.dismissPostActivationNotificationSheet() }
                    )
                }
            }
            .task {
                guard !isBootstrapped else { return }
                await SubscriptionService.shared.loadProStatus()

                DIContainer.shared.crashReportingService.identifyUser(
                    revenueCatId: SubscriptionService.shared.customerId
                )

                isBootstrapped = true

                if appState.shouldShowPaywall && DIContainer.shared.userRepository.onboardingIsFinished() && !appState.isProUser {
                    DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "auto"])
                    appState.showPaywall()
                }
                DIContainer.shared.analyticsService.capture(.appOpened)
            }
        }
        .environment(router)
        .enableInjection()
    }

    private var bootstrapSplash: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(theme.accent)
            ProgressView().controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var tabTitle: String {
        switch appState.selectedTab {
        case 0: return ""
        case 1: return "Progress"
        default: return ""
        }
    }

    @ViewBuilder
    func setupOnboardingView() -> some View {
        OnboardingFlowView()
    }

    @ViewBuilder
    func setupSettingsView() -> some View {
        SettingsView(
            viewModel: SettingsViewModel(onEvent: { _ in
                router.dismissSheet()
            })
        )
    }

    @ViewBuilder
    func getDestinationView(destination: Router.Route) -> some View {
        switch destination {
        case .onboarding: setupOnboardingView()
        case .home: HomeView()
        case .progress: StatsDashboardView()
        case .settings: setupSettingsView()
        case .paywall: PaywallView()
        case .categoryList: CategoryListView()
        case .practiceTestList(let code): PracticeTestListView(categoryCode: code)
        case .quizSession(let config): QuizSessionView(config: config)
        case .resumeQuizSession(let id): QuizSessionView(resumingSessionId: id)
        case .quizResult(let id): QuizResultView(sessionId: id)
        case .reviewSession(let id): ReviewSessionView(sessionId: id)
        case .learnLevelList(let code): LearnLevelListView(categoryCode: code)
        case .weakQuestions: WeakQuestionsView()
        case .statsDashboard: StatsDashboardView()
        case .examDatePicker: ExamDatePickerView()
        case .bookmarks: BookmarksView()
        case .aiTutor(let qid): AITutorView(questionId: qid)
        case .flashcardsLibrary: FlashcardsLibraryView()
        case .flashcardSession(let config): FlashcardSessionView(config: config)
        case .flashcardBookmarks: FlashcardBookmarksView()
        }
    }
}

#Preview {
    let appState = AppState()
    RootView()
        .environment(appState)
        .tint(theme.accent)
}
