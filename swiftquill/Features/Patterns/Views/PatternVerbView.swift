//
//  PatternVerbView.swift
//  swiftquill
//
//  Created by user on 29/1/2025.
//

import SwiftUI

struct PatternVerbView: View {
    var body: some View {
        VStack {
            PatternVerbInformationView()
            
            Spacer()
            
            List {
                Section ("Example Sentences in Context") {
                    VStack (alignment: .leading) {
                        Text("spanishText")
                            .font(.subheadline)
                            .fontWeight(.bold)

                        Text("englishText")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack (alignment: .leading) {
                        Text("spanishText")
                            .font(.subheadline)
                            .fontWeight(.bold)

                        Text("englishText")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .listStyle(.plain)
            .padding(.zero)
        }
        .navigationTitle("Regular -ar Verb")
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        PatternVerbView()
    }
}
