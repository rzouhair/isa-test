//
//  TrialCloseContainerView.swift
//  isaprep
//

import SwiftUI
import Inject
import RevenueCat
import RevenueCatUI

struct TrialCloseContainerView: View {
    @ObserveInjection var inject
    var onOpenPaywall: () -> Void
    var onDismiss: () -> Void

    @State private var step: Int = 0
    @State private var trialVM = TrialCloseViewModel()

    var body: some View {
        ZStack {
            theme.onboardingBg.ignoresSafeArea()

            ZStack {
                if step == 0 {
                    TrialScreen1View(
                        legalText: trialVM.legalText,
                        onContinue: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                step = 1
                            }
                        },
                        onRestore: {
                            Task { await trialVM.restorePurchases() }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }

                if step == 1 {
                    TrialScreen2View(
                        legalText: trialVM.legalText,
                        trialDays: trialVM.trialDaysText,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                step = 0
                            }
                        },
                        onOpenPaywall: onOpenPaywall,
                        onRestore: {
                            Task { await trialVM.restorePurchases() }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                }
            }
            .id(step)
        }
        .enableInjection()
    }
}

#Preview {
    TrialCloseContainerView(
        onOpenPaywall: {},
        onDismiss: {}
    )
}
