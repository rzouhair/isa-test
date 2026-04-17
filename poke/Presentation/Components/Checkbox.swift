//
//  Checkbox.swift
//  poke
//
//  Created by user on 23/03/2024.
//

import SwiftUI
import Inject

struct Checkbox: View {
    @ObserveInjection var inject

    let title: String
    @Binding var isChecked: Bool

    var body: some View {
        Button(action: {
            isChecked.toggle()
        }, label: {
            HStack {
                Image(systemName: isChecked ? "square.inset.filled" : "square")
                Text(title)
                    .font(.defaultText.regular)
            }
        })
        .tint(.primary)
        .enableInjection()
    }
}

#Preview {
    Checkbox(title: "Check this if you want", isChecked: .constant(false))
}
