//
//  OnboardingPageView.swift
//  
//
//  Created by user on 30/06/2023.
//

import SwiftUI

struct OnboardingPageView: View {

    let config: OnboardingPageConfig

    var body: some View {
        VStack(spacing: 32) {
            config.image
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
            VStack(alignment: .leading, spacing: 16) {
                Text(config.title)
                    .font(.title.bold)
                    .fontWeight(.medium)
                Text(config.description)
                    .font(.defaultText.regular)
            }
        }
        .tag(config.index)
        .padding(.bottom, 64)
    }
}

struct OnboardingPageView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPageView(config: .page1)
    }
}
