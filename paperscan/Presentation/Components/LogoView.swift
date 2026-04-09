//
//  LogoView.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import SwiftUI
import Inject

struct LogoView: View {
    @ObserveInjection var inject
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .padding(.trailing, 4)
            Text("Banknote")
            ZStack {
                Text("Scanner")
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.accent)
                    .rotationEffect(.degrees(-2))
            )
        }
        .font(.subtitle.medium)
        .enableInjection()
    }
}

#Preview {
    LogoView()
}
