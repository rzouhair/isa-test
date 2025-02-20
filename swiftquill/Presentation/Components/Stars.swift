//
//  Stars.swift
//  swiftquill
//
//  Created by user on 29/1/2025.
//

import SwiftUI

struct Stars: View {
    
    var numberOfFilledStars: Double
    var totalNumberOfStars: Int
    
    var body: some View {
        let fullStars = Int(numberOfFilledStars)
        let hasHalfStar = numberOfFilledStars.truncatingRemainder(dividingBy: 1) >= 0.5
        let emptyStars = totalNumberOfStars - fullStars - (hasHalfStar ? 1 : 0)
        
        HStack(spacing: 2) {
            ForEach(0..<fullStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.footnote)
            }
            
            if hasHalfStar {
                Image(systemName: "star.leadinghalf.filled")
                    .foregroundColor(.orange)
                    .font(.footnote)
            }
            
            ForEach(0..<emptyStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
    }
}

#Preview {
    Stars(
        numberOfFilledStars: 4, totalNumberOfStars: 5
    )
}
