//
//  PatternVerbInformationView.swift
//  swiftquill
//
//  Created by user on 29/1/2025.
//

import SwiftUI

struct PatternVerbInformationView: View {
    var body: some View {
        HStack (alignment: .lastTextBaseline, spacing: 16) {
            VStack {
                Text("Group")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("-ar")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                Text("Regularity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Regular")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            

            VStack (spacing: 6) {
                Text("Frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                Stars(numberOfFilledStars: 5, totalNumberOfStars: 5)
            }
            .frame(maxWidth: .infinity)
            
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    PatternVerbInformationView()
}
