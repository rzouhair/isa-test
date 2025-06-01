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

struct OnboardingConstants {
    // Colors
    static let primaryColor: Color = Asset.Colors.appPrimary.swiftUIColor
    static let backgroundColor = Color.black
    static let textColor = Color.white
    static let secondaryTextColor = Color(hex: "#A0A0A0")
    
    // Spacing
    static let screenPadding: CGFloat = 24
    static let elementSpacing: CGFloat = 20
    static let buttonHeight: CGFloat = 56
    
    // Text Sizes
    static let titleSize: CGFloat = 28
    static let bodySize: CGFloat = 16
    static let buttonTextSize: CGFloat = 18
    
    // Animation
    static let transitionDuration: Double = 0.4
}

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let buttonText: String
}

// Onboarding Content
let onboardingSteps = [
    OnboardingStep(
        title: "Instant Banknote Recognition",
        description: "Point your camera at any banknote to identify currency, value, and authenticity in seconds",
        imageName: "onboarding_scan",
        buttonText: "Continue"
    ),
    OnboardingStep(
        title: "150+ Currencies Supported",
        description: "From USD to JPY, EUR to CNY - identify banknotes from all major countries",
        imageName: "onboarding_global",
        buttonText: "Continue"
    ),
    OnboardingStep(
        title: "Detailed Information",
        description: "Learn about security features, exchange rates, and historical context",
        imageName: "onboarding_details",
        buttonText: "Get Started"
    )
]

struct OnboardingFlowView: View {
    @ObserveInjection var inject
    @State private var currentStep = 0
    @State private var showPaywall = false
    
    @State private var isCameraAuthorized = false
    @State private var showReviewRequest = false
    
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router: Router
    @Environment(\.requestReview) var requestReview

    var body: some View {
        ZStack {
            Group {
                if (currentStep == 0) {
                    OnboardingWelcomeView(onContinue: {
                        withAnimation {
                            currentStep = 1
                        }
                    })
                }
                
                if (currentStep == 1) {
                    // Instant Value View
                    OnboardingInstantValueView(
                        onTryNowTapped: {
                            withAnimation {
                                currentStep = 2
                            }
                        },
                        onLearnMoreTapped: {
                            withAnimation {
                                currentStep = 2
                            }
                        }
                    )
                }
                
                if (currentStep == 2) {
                    // Features View
                    OnboardingFeaturesView(
                        onSkip: {
                            requestCameraPermission()
                        },
                        onFinish: {
                            requestCameraPermission()
                        }
                    )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
            
        }
        .onAppear {
            checkCameraAuthorization()
        }
    }
    
    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            isCameraAuthorized = false
            break
        case .denied, .restricted:
            isCameraAuthorized = false
            break
        @unknown default:
            isCameraAuthorized = false
            break
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                isCameraAuthorized = granted
                DIContainer.shared.userRepository.setOnboardingIsFinished()
                print(DIContainer.shared.userRepository.onboardingIsFinished())
                showReviewRequest = true
                requestReview()
                router.navigateToRoot()
                appState.showPaywall()
            }
        }
    }
}

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
                    Text("Enjoying Money Scanner?")
                        .font(.system(size: OnboardingConstants.titleSize, weight: .bold))
                        .foregroundColor(OnboardingConstants.textColor)
                    
                    Text("Your feedback helps us improve the app and provide better service for everyone.")
                        .font(.system(size: OnboardingConstants.bodySize))
                        .foregroundColor(OnboardingConstants.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, OnboardingConstants.screenPadding)
                
                Spacer()
                
                Button(action: {
                    // Request app review
                    requestReview()
                    // Continue to next screen
                    onContinue()
                }) {
                    Text("Rate Money Scanner")
                        .font(.system(size: OnboardingConstants.buttonTextSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: OnboardingConstants.buttonHeight)
                        .background(OnboardingConstants.primaryColor)
                        .cornerRadius(16)
                        .padding(.horizontal, OnboardingConstants.screenPadding)
                }
                
                Button(action: {
                    onContinue()
                }) {
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
