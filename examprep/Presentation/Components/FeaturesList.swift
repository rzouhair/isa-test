//
//  FeaturesList.swift
//  isaprep
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct FeaturesList: View {
    @ObserveInjection var inject

    let featuresListItems: [FeaturesListItem]

    var body: some View {
        VStack {
            Grid(verticalSpacing: 8) {
                GridRow {
                    Text("Features")
                        .font(.footnote)
                    Spacer()
                    Text("Free")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Pro")
                        .font(.footnote)
                        .foregroundColor(theme.accent)
                }
                .fontWeight(.bold)
                .gridCellAnchor(.leading)
                ForEach(featuresListItems, id: \.id) { item in
                    GridRow {
                        Text(item.title)
                            .font(.footnote)
                            .gridCellAnchor(.leading)
                        Spacer()
                        if item.isProOnly {
                            Image(systemName: "xmark.circle.fill")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.footnote)
                                .foregroundColor(theme.accent)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.cardBackground.swiftUIColor)
                .shadow(radius: 2)
        )
        .enableInjection()
    }

    func makeRow(title: String, free: some View, pro: some View) -> some View {
        GridRow {
            Text(title)
                .font(.footnote)
                .gridCellAnchor(.leading)
            Spacer()
            free
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            pro
                .font(.footnote)
                .foregroundColor(theme.accent)
        }
    }
}

struct FeaturesListItem {
    let id = UUID()
    let title: String
    let isProOnly: Bool
}

#Preview {
    FeaturesList(
        featuresListItems: [
            FeaturesListItem(title: "UI Components", isProOnly: false),
            FeaturesListItem(title: "Authentication", isProOnly: false),
            FeaturesListItem(title: "Clean architecture", isProOnly: false),
            FeaturesListItem(title: "Unlimited downloads", isProOnly: true),
            FeaturesListItem(title: "Lifetime updates", isProOnly: true)
        ]
    )
}
