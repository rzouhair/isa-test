//
//  SplashView.swift
//  
//
//  Created by user on 30/06/2023.
//

import SwiftUI
import AVKit

public struct SplashView: View {

    public enum Event {
        case startButtonTapped
    }

    var onEvent: (Event) -> Void

    public init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }

    @State var isShowingOnboardingView = false

    public var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()
                LogoView()
                Spacer()
                Text("swiftquill is not just a boilerplate code. It's everything you need to launch a profitable iOS app in no time. Launch your app 10x faster and start making money asap!")
                    .font(.defaultText.regular)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                SailButton(
                    style: .primary,
                    action: {
                        onEvent(.startButtonTapped)
                    },
                    icon: Image(systemName: "checkmark.circle.fill"),
                    title: "Let's start"
                )
                .padding(.vertical, 32)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView { _ in

        }
    }
}
