//
//  PatternCognatesView.swift
//  swiftquill
//
//  Created by user on 30/1/2025.
//

import SwiftUI

struct PatternCognatesView: View {
    
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            List {
                ForEach (0..<3, id: \.self) { tag in
                    Section ("-ty -> -dad Cognates") {
                        ForEach (0..<4, id: \.self) { _ in
                            HStack (alignment: .lastTextBaseline) {
                                Text("spanishText")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Spacer()

                                Text("englishText")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Image(systemName: "star.fill")
                                    .font(.headline)
                                    .foregroundStyle(Color.gray)
                                    .padding(.leading, 4)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search Cognates")
        .navigationTitle("Cognates")
    }
}

#Preview {
    NavigationStack {
        PatternCognatesView()
    }
}
