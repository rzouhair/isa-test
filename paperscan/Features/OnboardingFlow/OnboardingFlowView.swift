//
//  OnboardingFlowView.swift
//  paperscan
//
//  Created by user on 5/4/2025.
//

import SwiftUI
import Inject
import AVFoundation
import StoreKit

// MARK: - Kash Brand Colors

enum KashColors {
    static let green900 = Color(hex: "#0d2818")
    static let green800 = Color(hex: "#133520")
    static let green700 = Color(hex: "#1a4a2e")
    static let green600 = Color(hex: "#1f5c38")
    static let green500 = Color(hex: "#2a7a4a")
    static let green400 = Color(hex: "#3a9960")
    static let green300 = Color(hex: "#5ab87a")
    static let green100 = Color(hex: "#b8e8c8")
    static let green50  = Color(hex: "#e8f7ee")
    static let gold     = Color(hex: "#c8a84b")
    static let goldLight = Color(hex: "#f0d080")
}

struct OnboardingConstants {
    static let primaryColor: Color = KashColors.green500
    static let backgroundColor = KashColors.green900
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

// MARK: - Flow Orchestrator

struct OnboardingFlowView: View {
    @ObserveInjection var inject
    @State private var currentStep = 0
    @State private var isCameraAuthorized = false
    @State private var trialVM = TrialCloseViewModel()

    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router: Router
    @Environment(\.requestReview) var requestReview

    private func finishOnboardingAfterRestore() {
        Task {
            await SubscriptionService.shared.loadProStatus()
            DIContainer.shared.userRepository.setOnboardingIsFinished()
            router.navigateToRoot()
        }
    }

    // Steps 0-3: onboarding, 4: trial screen 1, 5: trial screen 2
    private let totalSteps = 6
    // Only show dots for the first 4 onboarding steps
    private let onboardingSteps = 4

    var body: some View {
        ZStack {
            KashColors.green900.ignoresSafeArea()

            VStack(spacing: 0) {
                // Screen content
                ZStack {
                    if currentStep == 0 {
                        OnboardingHeroView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 1 {
                        OnboardingValueView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 2 {
                        OnboardingPersonalizationView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 3 {
                        OnboardingCameraPermissionView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 4 {
                        TrialScreen1View(
                            legalText: trialVM.legalText,
                            onContinue: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    currentStep = 5
                                }
                            },
                            onRestore: {
                                Task { await trialVM.restorePurchases() }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }

                    if currentStep == 5 {
                        TrialScreen2View(
                            legalText: trialVM.legalText,
                            trialDays: trialVM.trialDaysText,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    currentStep = 4
                                }
                            },
                            onOpenPaywall: {
                                Task {
                                    await TrialCloseViewModel.requestNotificationPermission()
                                    finishOnboardingAndShowPaywall()
                                }
                            },
                            onRestore: {
                                Task { await trialVM.restorePurchases() }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .frame(maxHeight: .infinity)

                // Bottom navigation — only show for onboarding steps 0-3
                if currentStep < onboardingSteps {
                    VStack(spacing: 16) {
                        // Progress dots
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingSteps, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentStep ? KashColors.green400 : Color.white.opacity(0.2))
                                    .frame(width: index == currentStep ? 20 : 6, height: 6)
                                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                            }
                        }

                        // Primary button
                        Button(action: handlePrimaryAction) {
                            Text(primaryButtonLabel)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: OnboardingConstants.buttonHeight)
                                .background(KashColors.green500)
                                .clipShape(RoundedRectangle(cornerRadius: OnboardingConstants.buttonRadius))
                                .overlay(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: OnboardingConstants.buttonRadius))
                                )
                        }
                        .padding(.horizontal, OnboardingConstants.screenPadding)

                        // Skip button
                        if showsSkipButton {
                            Button(action: handleSkip) {
                                Text("Skip")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            checkCameraAuthorization()
            trialVM.onRestoreSuccess = {
                finishOnboardingAfterRestore()
            }
        }
        .enableInjection()
    }

    private var primaryButtonLabel: String {
        switch currentStep {
        case 0: return "Get started"
        case 1: return "Continue"
        case 2: return "Continue"
        case 3: return "Allow camera access"
        default: return "Continue"
        }
    }

    private var showsSkipButton: Bool {
        currentStep == 1 || currentStep == 2
    }

    private func handlePrimaryAction() {
        if currentStep < onboardingSteps - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentStep += 1
            }
        } else if currentStep == 3 {
            requestCameraPermission()
        }
    }

    private func handleSkip() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = 4
        }
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        default:
            isCameraAuthorized = false
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                isCameraAuthorized = granted
                // Advance to trial screen 1
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep = 4
                }
            }
        }
    }

    private func finishOnboardingAndShowPaywall() {
        DIContainer.shared.userRepository.setOnboardingIsFinished()
        requestReview()
        router.navigateToRoot()
        appState.showPaywall()
    }
}

// MARK: - Review Request View (kept for compatibility)

struct ReviewRequestView: View {
    @ObserveInjection var inject
    @Environment(\.requestReview) var requestReview
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            OnboardingConstants.backgroundColor.ignoresSafeArea()

            VStack(spacing: OnboardingConstants.elementSpacing) {
                Spacer()

                Image(systemName: "star.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(OnboardingConstants.primaryColor)

                Spacer()

                VStack(alignment: .center, spacing: 16) {
                    Text("Enjoying Kash?")
                        .font(.system(size: OnboardingConstants.titleSize, weight: .bold))
                        .foregroundColor(OnboardingConstants.textColor)

                    Text("Your feedback helps us improve the app.")
                        .font(.system(size: OnboardingConstants.bodySize))
                        .foregroundColor(OnboardingConstants.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, OnboardingConstants.screenPadding)

                Spacer()

                Button(action: {
                    requestReview()
                    onContinue()
                }) {
                    Text("Rate Kash")
                        .font(.system(size: OnboardingConstants.buttonTextSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: OnboardingConstants.buttonHeight)
                        .background(OnboardingConstants.primaryColor)
                        .cornerRadius(OnboardingConstants.buttonRadius)
                        .padding(.horizontal, OnboardingConstants.screenPadding)
                }

                Button(action: onContinue) {
                    Text("Maybe Later")
                        .font(.system(size: OnboardingConstants.bodySize))
                        .foregroundColor(OnboardingConstants.secondaryTextColor)
                        .padding()
                }
            }
            .padding(.vertical, OnboardingConstants.screenPadding)
        }
        .enableInjection()
    }
}

#Preview {
    var router: Router = Router()
    var appState: AppState = AppState()
    OnboardingFlowView()
        .environment(router)
        .environment(appState)
}

// Helper extension for hex colors
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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
