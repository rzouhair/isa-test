//
//  Reviews.swift
//  examprep
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct Reviews: View {
    @ObserveInjection var inject

    let reviewItems: [ReviewItem]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(reviewItems, id: \.id) { item in
                    makeReview(stars: item.numberOfStars, title: item.title, text: item.description)
                }
            }
            .padding(8)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -8)
        .enableInjection()
    }

    func makeReview(stars: Int, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<stars, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.footnote)
                }
                ForEach(0..<abs(stars - 5), id: \.self) { index in
                    Image(systemName: "star")
                        .foregroundColor(.orange)
                        .font(.footnote)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("**\(title)**")
                Text("\"\(text)\"")
                    .fixedSize(horizontal: false, vertical: true)
                    .italic()
            }
            .font(.footnote)
            Spacer()
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.cardBackground.swiftUIColor)
                .shadow(radius: 2)
        )
    }
}

struct ReviewItem {
    let id = UUID()
    let numberOfStars: Int
    let title: String
    let description: String
}

#Preview {
    Reviews(reviewItems: [
        ReviewItem(numberOfStars: 5, title: "Streamlined trading journal", description: "Love this program! Very well laid out and it’s simple to use. Had some bugs on my end, but the developer was quick to respond and get it fixed. He always walked me through how the app works in the background to come to its totals. Definitely use it!"),
        ReviewItem(numberOfStars: 5, title: "Efficient trade journal", description: "Great for tracking trades and recording P/L on a regular basis. Shows your performance and you are able to add notes to reflect on your trades. Very well put together app."),
        ReviewItem(numberOfStars: 4, title: "Simple to use trading tool", description: "I’ve been looking for a testing journal app and enjoy the design this one has well as the widget functions. The developer was also quick to respond to any inquiries and critiques"),
        ReviewItem(numberOfStars: 5, title: "Top-notch tracking app", description: "Better then any other trade journal app. Intuitive and straight to the point. A lot of brokers on here. Better then other platforms at this price")
    ])
}
