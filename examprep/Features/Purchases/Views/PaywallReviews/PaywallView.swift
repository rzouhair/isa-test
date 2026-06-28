//
//  PaywallView.swift
//  isaprep
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

public struct SailPaywallView: View {
    @ObserveInjection var inject
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: PaywallViewModel

    @State var isShowingOtherOptions = false

    public init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    logoView
                    featuresView
                    RatingView(rating: "4.7", numberOfFilledStars: 4, subtitle: "200+ reviews")
                    reviewsView
                    Spacer()
                }
                .padding(16)
            }
            .padding(.bottom, 180)
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.bottom, 64)
                } else {
                    buttonsView
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            Task {
                await viewModel.onAppear()
            }
        }
        .sheet(isPresented: $isShowingOtherOptions) {
            otherOptionsView
                .presentationDetents([.medium])
        }
        .enableInjection()
    }

    var logoView: some View {
        HStack {
            Spacer()
            LogoView()
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
            })
            .tint(.primary)
        }
    }

    var reviewsView: some View {
        VStack {
            Text("From isaprep users")
                .fontWeight(.bold)
            Reviews(reviewItems: [
                ReviewItem(numberOfStars: 5, title: "Streamlined trading journal", description: "Love this program! Very well laid out and it’s simple to use. Had some bugs on my end, but the developer was quick to respond and get it fixed. He always walked me through how the app works in the background to come to its totals. Definitely use it!"),
                ReviewItem(numberOfStars: 5, title: "Efficient trade journal", description: "Great for tracking trades and recording P/L on a regular basis. Shows your performance and you are able to add notes to reflect on your trades. Very well put together app."),
                ReviewItem(numberOfStars: 4, title: "Simple to use trading tool", description: "I’ve been looking for a testing journal app and enjoy the design this one has well as the widget functions. The developer was also quick to respond to any inquiries and critiques"),
                ReviewItem(numberOfStars: 5, title: "Top-notch tracking app", description: "Better then any other trade journal app. Intuitive and straight to the point. A lot of brokers on here. Better then other platforms at this price")
            ])
        }
    }

    var featuresView: some View {
        FeaturesList(featuresListItems: [
            FeaturesListItem(title: "UI Components", isProOnly: false),
            FeaturesListItem(title: "Authentication", isProOnly: false),
            FeaturesListItem(title: "Clean architecture", isProOnly: false),
            FeaturesListItem(title: "Unlimited downloads", isProOnly: true),
            FeaturesListItem(title: "Lifetime updates", isProOnly: true)
        ])
    }

    var buttonsView: some View {
        VStack(spacing: 12) {
            VStack {
                if viewModel.isUserEligibleForIntroOffer {
                    Text("Try 7-day free trial, then **\(viewModel.mainPackageWeeklyPriceString)**. Cancel anytime.")
                        .padding(.horizontal, 32)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Start today for **\(viewModel.mainPackageWeeklyPriceString)**. Cancel anytime.")
                        .padding(.horizontal, 32)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                if viewModel.isUserEligibleForIntroOffer {
                    SailButton(action: {
                        Task {
                            await viewModel.purchase(viewModel.mainPackage)
                        }
                    }, icon: Image(systemName: "trophy.fill"), title: "Start 7-day free trial")
                } else {
                    SailButton(action: {
                        Task {
                            await viewModel.purchase(viewModel.mainPackage)
                        }
                    }, icon: Image(systemName: "trophy.fill"), title: "Get isaprep Pro")
                }
            }
            Button("Other options") {
                isShowingOtherOptions = true
            }
            .foregroundColor(.primary)
            .fontWeight(.medium)
            .font(.footnote)
            HStack {
                Button("Privacy policy") {
                    viewModel.showPrivacyPolicy()
                }
                Button("EULA") {
                    viewModel.showEula()
                }
                Spacer()
                Button("Restore purchase") {
                    Task {
                        await viewModel.restorePurchase()
                    }
                }
            }
            .font(.footnote)
            .foregroundColor(.primary)
        }
        .padding(16)
        .padding(.bottom, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.cardBackground.swiftUIColor)
                .shadow(radius: 4)
        )
    }

    var otherOptionsView: some View {
        VStack {
            HStack {
                Text("Other options")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    isShowingOtherOptions = false
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .foregroundColor(.primary)
            VStack {
                ForEach(viewModel.packages, id: \.identifier) { package in
                    Button {
                        Task {
                            await viewModel.purchase(package)
                        }
                        isShowingOtherOptions = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(package.periodSting)")
                                        .fontWeight(.bold)
                                    if viewModel.mainPackage == package {
                                        makeTagView(text: "Most popular", color: .orange)
                                        if viewModel.isUserEligibleForIntroOffer  {
                                            makeTagView(text: "7-day free trial", color: .green)
                                        }
                                    }
                                }
                                Text("for \(package.priceString)")
                                    .font(.footnote)
                            }
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Asset.Colors.cardBackground.swiftUIColor)
                                .shadow(radius: 2)
                        )
                    }
                }
                Spacer()
            }
        }
        .padding(16)
    }

    func makeTagView(text: String, color: Color) -> some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
            )
    }
}

#Preview {
    SailPaywallView(
        viewModel: PaywallViewModel()
    )
}
