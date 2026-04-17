//
//  HighlightTabBar.swift
//  poke
//
//  Created by user on 24/3/2025.
//

import SwiftUI
import Inject
import Foundation

struct HighlightTabBar: View {
    @ObserveInjection var inject
    @Environment(AppState.self) private var appState: AppState
    @Environment(Router.self) private var router: Router
    @Environment(\.colorScheme) private var colorScheme

    var tint: Color = theme.accent
    var inactiveTint: Color = theme.accent
    
    @Binding var selectedPage: Int

    var body: some View {
        /// Moving all the Remaining Tab Item's to Bottom
        ZStack (alignment: .center) {
            HStack(alignment: .bottom, spacing: 0) {
                TabItem(
                    tint: tint,
                    inactiveTint: inactiveTint,
                    tab: Router.Route.home,
                    tabIndex: 0,
                    activeTab: $selectedPage
                )

                Spacer()
                Spacer()

                TabItem(
                    tint: tint,
                    inactiveTint: inactiveTint,
                    tab: Router.Route.collection,
                    tabIndex: 2,
                    activeTab: $selectedPage
                )
            }
            .padding(.horizontal, 15)
            .padding(.top, 6)
            .background(content: {
                Rectangle()
                    .fill(backgroundColorForColorScheme)
                    .ignoresSafeArea()
            })
            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: selectedPage)
            
            VStack(spacing: 5) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    /// Increasing Size for the Active Tab
                    .frame(width: 58, height: 58)
                    .background {
                        Circle()
                            .fill(theme.fabFill.gradient)
                    }
            }
            .shadow(color: theme.fabShadow, radius: 8, y: 4)
            .frame(minWidth: 0)
            .contentShape(Rectangle())
            .onTapGesture {
                if (appState.isProUser) {
                    router.presentFullscreenCover(.scanner)
                } else {
                    appState.showPaywall()
                }
            }
            .offset(y: -33)
        }
        .tint(theme.accent)
    }
    
    private var backgroundColorForColorScheme: Color {
        switch colorScheme {
        case .dark:
            return Color(UIColor.systemBackground)
        case .light:
            return .white
        @unknown default:
            return .white
        }
    }
}

struct TabItem: View {
    @ObserveInjection var inject
    var tint: Color
    var inactiveTint: Color
    var tab: Router.Route
    var tabIndex: Int?
    var isAlwaysActive: Bool = false
    var onClick: (() -> Void)?
    @Binding var activeTab: Int
    
    var showTitle: Bool = true
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "\(tab.iconName)")
                .font(.title2)
                .foregroundColor(activeTab == tabIndex || isAlwaysActive ? tint : .gray)
                /// Increasing Size for the Active Tab
                .frame(width: 35, height: 35)
            
            if !tab.title.isEmpty && showTitle {
                Text(tab.title)
                    .font(.caption)
                    .foregroundColor(activeTab == tabIndex || isAlwaysActive ? tint : .gray)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if let action = onClick {
                action()
            } else if (tabIndex != nil) {
                activeTab = tabIndex!
            }
        }
    }
}

#Preview {
    @Previewable
    @State var selectedPage: Int = 0
    
    var router = Router()
    
    HighlightTabBar(selectedPage: $selectedPage)
        .environment(Router())
}

