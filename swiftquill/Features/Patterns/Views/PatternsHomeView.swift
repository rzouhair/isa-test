//
//  PatternsHomeView.swift
//  swiftquill
//
//  Created by user on 28/1/2025.
//

import SwiftUI

struct PatternsHomeView: View {
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0
    
    var body: some View {
        VStack (alignment: .leading) {
            Picker("Select the Entity you want to learn patterns for", selection: $selectedTab) {
                Text("Verbs")
                    .tag(0)
                Text("Cognates")
                    .tag(1)
                Text("Locucìones")
                    .tag(2)
            }
            .pickerStyle(.segmented)
            
            TabView (selection: $selectedTab) {
                ForEach (0..<3, id: \.self) { tag in
                    ScrollView {
                        VStack (alignment: .trailing) {
                            ForEach (0..<10, id: \.self) { _ in
                                PatternCardView(
                                    spanishText: "-ar Verbos \(tag)",
                                    englishText: "-ar Verbs \(tag)",
                                    onCardClick: {}
                                )
                            }
                        }
                    }
                    .tag(tag)
                }
            }.tabViewStyle(.page)
            
        }
        .padding(.horizontal, 16)
        .navigationTitle("swiftquill")
        .searchable(text: $searchText, prompt: "Find patterns, verbs, cognates...")
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .background(Color(UIColor.secondarySystemBackground))
        .navigationBarBackButtonHidden()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fixedSizeScrollView()
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    NavigationStack {
        PatternsHomeView()
    }
}
