//
//  PatternCardView.swift
//  swiftquill
//
//  Created by user on 29/1/2025.
//

import SwiftUI

struct PatternCardView: View {
    var spanishText: String
    var englishText: String
    
    var imageName: String?
    var imageColor: Color?
    
    var onCardClick: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(spanishText)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(englishText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: imageName ?? "leaf.fill")
                .foregroundStyle(imageColor ?? .statusEasy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            guard onCardClick != nil else { return }
            onCardClick!()
        }
    }
}

#Preview {
    PatternCardView(
        spanishText: "-ar Verbos",
        englishText: "-ar Verbs",
        onCardClick: {}
    )
}
