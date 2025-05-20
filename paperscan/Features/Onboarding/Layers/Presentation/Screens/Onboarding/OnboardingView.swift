//
//  OnboardingView.swift
//  
//
//  Created by user on 30/06/2023.
//

import SwiftUI
import Inject

struct OnboardingView: View {
    @ObserveInjection var inject

    public enum Event {
        case skipButtonTapped
        case finishButtonTapped
    }

    var onEvent: (Event) -> Void

    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }

    @State var selectedIndex: Int = 0

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onEvent(.skipButtonTapped)
                    } label: {
                        Text("Skip")
                            .font(.body)
                            .fontWeight(.medium)
                    }

                }
                TabView(selection: $selectedIndex) {
                    ForEach(OnboardingPageConfig.allPages, id: \.id) { config in
                        OnboardingPageView(config: config)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack {
                    if selectedIndex > 0 {
                        Button {
                            withAnimation {
                                selectedIndex -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                    HStack {
                        ForEach(OnboardingPageConfig.allPages, id: \.id) { config in
                            Circle()
                                .fill(selectedIndex == config.index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 14, height: 14)
                                .onTapGesture {
                                    withAnimation {
                                        selectedIndex = config.index
                                    }
                                }
                        }
                    }
                    Spacer()
                    Button {
                        if selectedIndex == OnboardingPageConfig.allPages.count - 1 {
                            onEvent(.finishButtonTapped)
                        } else {
                            withAnimation {
                                selectedIndex += 1
                            }
                        }
                    } label: {
                        Text(selectedIndex == OnboardingPageConfig.allPages.count - 1 ? "Finish" : "Next")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.horizontal, 16)
            .tint(Asset.Colors.appPrimary.swiftUIColor)
        }
        .enableInjection()
    }
}

struct OnboardingSlide: Hashable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onEvent: { _ in
            
        })
    }
}
