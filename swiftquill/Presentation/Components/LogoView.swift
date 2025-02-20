//
//  LogoView.swift
//  swiftquill
//
//  Created by user on 06/03/2024.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "swift")
                .font(.largeTitle)
                .padding(.trailing, 4)
            Text("Swift")
            ZStack {
                Text("Sail")
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Asset.Colors.appPrimary.swiftUIColor)
                    .rotationEffect(.degrees(-6))
            )
        }
        .font(.subtitle.medium)
    }
}

#Preview {
    LogoView()
}
