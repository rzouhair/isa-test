//
//  OnboardingFlowView.swift
//  poke
//
//  Created by user on 5/4/2025.
//

import SwiftUI
import StoreKit
import Inject
import AVFoundation


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

// MARK: - Flow Orchestrator

struct OnboardingFlowView: View {
    @ObserveInjection var inject
    @State private var currentStep = 0
    @State private var isCameraAuthorized = false
    @State private var trialVM = TrialCloseViewModel()

    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router: Router

    private func finishOnboardingAfterRestore() {
        Task {
            await SubscriptionService.shared.loadProStatus()
            DIContainer.shared.userRepository.setOnboardingIsFinished()
            router.navigateToRoot()
        }
    }

    @Environment(\.requestReview) private var requestReview

    // Steps 0-10: onboarding screens, 11: trial 1, 12: trial 2
    private let totalSteps = 13
    private let onboardingSteps = 11

    var body: some View {
        ZStack {
            theme.onboardingBg.ignoresSafeArea()

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
                        OnboardingCorrectionView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 3 {
                        OnboardingBulkScanView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 4 {
                        OnboardingPortfolioView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 5 {
                        OnboardingGradingView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 6 {
                        OnboardingWatchlistView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 7 {
                        OnboardingMultiGameView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 8 {
                        OnboardingExportImportView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 9 {
                        OnboardingRateUsView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 10 {
                        OnboardingCameraPermissionView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    if currentStep == 11 {
                        TrialScreen1View(
                            legalText: trialVM.legalText,
                            onContinue: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    currentStep = 12
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

                    if currentStep == 12 {
                        TrialScreen2View(
                            legalText: trialVM.legalText,
                            trialDays: trialVM.trialDaysText,
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    currentStep = 11
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

                // Bottom navigation — only for onboarding steps 0-4
                if currentStep < onboardingSteps {
                    VStack(spacing: 16) {
                        // Progress dots
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingSteps, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentStep ? theme.dotActive : Color.white.opacity(0.2))
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
                                .background(theme.accent)
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

                        // Skip intentionally removed — see QA plan Wave 2.
                        // If drop-off exceeds 20% at step 3, reintroduce skip to paywall (not scanner).
                    }
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            checkCameraAuthorization()
            analytics.capture(.onboardingStarted)
            analytics.capture(.onboardingStepViewed, properties: stepProperties(for: 0))
            trialVM.onRestoreSuccess = {
                finishOnboardingAfterRestore()
            }
        }
        .onChange(of: currentStep) { _, newStep in
            analytics.capture(.onboardingStepViewed, properties: stepProperties(for: newStep))
        }
        .enableInjection()
    }

    private func stepProperties(for index: Int) -> [String: Any] {
        ["step": index, "step_name": stepName(for: index)]
    }

    private func stepName(for index: Int) -> String {
        switch index {
        case 0: return "hero"
        case 1: return "value"
        case 2: return "correction"
        case 3: return "bulk_scan"
        case 4: return "portfolio"
        case 5: return "grading"
        case 6: return "watchlist"
        case 7: return "multi_game"
        case 8: return "export_import"
        case 9: return "rate_us"
        case 10: return "camera_permission"
        case 11: return "trial_close_1"
        case 12: return "trial_close_2"
        default: return "unknown"
        }
    }

    private var primaryButtonLabel: String {
        switch currentStep {
        case 0: return "Get started"
        case 9: return "Rate us"
        case 10:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .denied || status == .restricted {
                return "Open Settings"
            }
            return "Allow camera access"
        default: return "Continue"
        }
    }

    private let analytics = DIContainer.shared.analyticsService

    private func handlePrimaryAction() {
        if currentStep == 9 {
            requestReview()
            withAnimation(.easeInOut(duration: 0.4)) {
                currentStep += 1
            }
        } else if currentStep == 10 {
            requestCameraPermission()
        } else if currentStep < onboardingSteps - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentStep += 1
            }
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
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if currentStatus == .denied || currentStatus == .restricted {
            // Permission permanently denied — open Settings instead of silently advancing.
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            analytics.capture(.onboardingCameraPermission, properties: ["granted": false, "deep_linked_to_settings": true])
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                isCameraAuthorized = granted
                analytics.capture(.onboardingCameraPermission, properties: ["granted": granted])
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep = 11
                }
            }
        }
    }

    private func finishOnboardingAndShowPaywall() {
        analytics.capture(.onboardingCompleted)
        DIContainer.shared.userRepository.setOnboardingIsFinished()
        router.navigateToRoot()
        appState.showPaywall()
    }
}

#Preview {
    let router: Router = Router()
    let appState: AppState = AppState()
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
