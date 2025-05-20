//
//  RatingView.swift
//  paperscan
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct RatingView: View {
    @ObserveInjection var inject

    var rating: String = "4.7"
    var numberOfFilledStars: Int = 4
    var subtitle: String = "200+ reviews"

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: "laurel.leading")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(rating)
                Image(systemName: "laurel.trailing")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
            }
            .font(.largeTitle.weight(.black))
            HStack(spacing: 2) {
                ForEach(0..<numberOfFilledStars, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.footnote)
                }
                ForEach(0..<1, id: \.self) { index in
                    Image(systemName: "star.leadinghalf.filled")
                        .foregroundColor(.orange)
                        .font(.footnote)
                }
            }
            Text(subtitle)
                .font(.footnote)
        }
        .enableInjection()
    }
}

#Preview {
    RatingView()
}
