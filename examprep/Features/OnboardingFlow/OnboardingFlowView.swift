import SwiftUI
import StoreKit
import Inject

struct OnboardingConstants {
    static var primaryColor: Color { theme.accent }
    static var backgroundColor: Color { theme.onboardingBg }
    static let textColor = Color.white
    static let secondaryTextColor = Color.white.opacity(0.55)

    static let screenPadding: CGFloat = 24
    static let elementSpacing: CGFloat = 20
    static let buttonHeight: CGFloat = 56
    static let buttonRadius: CGFloat = 16

    static let titleSize: CGFloat = 28
    static let bodySize: CGFloat = 16
    static let buttonTextSize: CGFloat = 16

    static let transitionDuration: Double = 0.4
}

// MARK: - Steps

enum OnboardingStep: Int, CaseIterable {
    case hero
    case value1
    case value2
    case examDate
    case rateUs
    case trial1
    case trial2

    static var indicatorSteps: Int { 5 }

    var showsProgressDots: Bool { self != .trial1 && self != .trial2 }
    var hasBuiltInCTA: Bool {
        self == .examDate || self == .trial1 || self == .trial2
    }
}

// MARK: - Orchestrator

struct OnboardingFlowView: View {
    @ObserveInjection var inject
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router: Router
    @Environment(\.requestReview) private var requestReview

    @State private var step: OnboardingStep = .hero
    @State private var trialVM = TrialCloseViewModel()

    private let analytics = DIContainer.shared.analyticsService

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    currentStepView
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .frame(maxHeight: .infinity)

                if !step.hasBuiltInCTA {
                    footerControls
                        .padding(.bottom, 28)
                        .frame(maxWidth: .infinity)
                } else if step.showsProgressDots {
                    progressDots
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            analytics.capture(.onboardingStarted)
            analytics.capture(.onboardingStepViewed, properties: stepProperties(for: step))
            trialVM.onRestoreSuccess = { finishAfterRestore() }
        }
        .onChange(of: step) { _, newStep in
            analytics.capture(.onboardingStepViewed, properties: stepProperties(for: newStep))
        }
        .enableInjection()
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [theme.onboardingBg, theme.gradientEnd, theme.onboardingBg],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .hero: OnboardingHeroView()
        case .value1: OnboardingValueProp1View()
        case .value2: OnboardingValueProp2View()
        case .examDate:
            OnboardingExamDateStepView(onSave: { advance() }, onSkip: { advance() })
        case .rateUs:
            OnboardingRateUsView()
        case .trial1:
            TrialScreen1View(
                legalText: trialVM.legalText,
                onContinue: { goTo(.trial2) },
                onRestore: { Task { await trialVM.restorePurchases() } }
            )
        case .trial2:
            TrialScreen2View(
                legalText: trialVM.legalText,
                trialDays: trialVM.trialDaysText,
                onBack: { goTo(.trial1) },
                onOpenPaywall: {
                    Task {
                        await TrialCloseViewModel.requestNotificationPermission()
                        finishAndShowPaywall()
                    }
                },
                onRestore: { Task { await trialVM.restorePurchases() } }
            )
        }
    }

    private var footerControls: some View {
        VStack(spacing: 14) {
            progressDots

            Button(action: primaryAction) {
                Text(primaryLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: OnboardingConstants.buttonHeight)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: OnboardingConstants.buttonRadius))
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: OnboardingConstants.buttonRadius))
                    )
                    .shadow(color: theme.accent.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.horizontal, OnboardingConstants.screenPadding)
        }
    }

    private var primaryLabel: String {
        switch step {
        case .hero: return "Get started"
        case .rateUs: return "Rate us"
        default: return "Continue"
        }
    }

    private func primaryAction() {
        if step == .rateUs {
            requestReview()
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advance()
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<OnboardingStep.indicatorSteps, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentIndicatorIndex ? theme.accentBright : Color.white.opacity(0.18))
                    .frame(width: idx == currentIndicatorIndex ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: step)
            }
        }
    }

    private var currentIndicatorIndex: Int {
        switch step {
        case .hero: return 0
        case .value1: return 1
        case .value2: return 2
        case .examDate: return 3
        case .rateUs: return 4
        default: return OnboardingStep.indicatorSteps - 1
        }
    }

    private func goTo(_ newStep: OnboardingStep) {
        withAnimation(.easeInOut(duration: OnboardingConstants.transitionDuration)) {
            step = newStep
        }
    }

    private func advance() {
        let all = OnboardingStep.allCases
        guard let idx = all.firstIndex(of: step), idx + 1 < all.count else {
            finishAndShowPaywall()
            return
        }
        goTo(all[idx + 1])
    }

    private func finishAndShowPaywall() {
        analytics.capture(.onboardingCompleted)
        DIContainer.shared.userRepository.setOnboardingIsFinished()
        router.navigateToRoot()
        appState.showPaywall()
    }

    private func finishAfterRestore() {
        Task {
            await SubscriptionService.shared.loadProStatus()
            DIContainer.shared.userRepository.setOnboardingIsFinished()
            router.navigateToRoot()
        }
    }

    private func stepProperties(for step: OnboardingStep) -> [String: Any] {
        ["step": step.rawValue, "step_name": stepName(for: step)]
    }

    private func stepName(for step: OnboardingStep) -> String {
        switch step {
        case .hero: return "hero"
        case .value1: return "value_questions"
        case .value2: return "value_simulator"
        case .examDate: return "exam_date"
        case .rateUs: return "rate_us"
        case .trial1: return "trial_close_1"
        case .trial2: return "trial_close_2"
        }
    }
}

#Preview {
    let router = Router()
    let appState = AppState()
    OnboardingFlowView()
        .environment(router)
        .environment(appState)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    init(hex: Int, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}
