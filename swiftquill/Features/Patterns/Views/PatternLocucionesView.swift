//
//  PatternCognatesView.swift
//  swiftquill
//
//  Created by user on 30/1/2025.
//

import SwiftUI

struct PatternLocucionesView: View {
    
    @State private var searchText: String = ""
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading, spacing: 16) {
                HStack (alignment: .center) {
                    VStack (alignment: .leading) {
                        Text("spanishText")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("englishText")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "star.filled")
                        .foregroundStyle(Color.gray)
                }
                
                Text("Where to use it, the context, and some examples lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ipsum lorem ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search Cognates")
        .navigationTitle("Locucìones")
    }
}

#Preview {
    NavigationStack {
        PatternLocucionesView()
    }
}
