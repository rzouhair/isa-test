//
//  Accordion.swift
//  notescan
//
//  Created by user on 23/03/2024.
//

import SwiftUI

struct Accordion: View {

    let items: [AccordionItem]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 16) {
                    DisclosureGroup(item.title) {
                        Text(item.description)
                            .padding(.top, 16)
                    }
                    Divider()
                }
            }
            Spacer()
        }
        .padding(16)
        .font(.defaultText.regular)
        .tint(Asset.Colors.appPrimary.swiftUIColor)
    }
}

struct AccordionItem {
    let id = UUID()
    let title: String
    let description: String
}

#Preview {
    Accordion(items: [
        AccordionItem(
            title: "Why should I choose notescan?",
            description: "Because notescan is not just another boilerplate template. Yes, you'll get the full Xcode project will all the features and UI components. But you'll also get my years of experience in selling subscriptions and making money on the AppStore. I will share with you everything I know about selling strategies like when to show the paywall, what subscription to offer, when to ask for review, how to setup your keywords, title, subtitle of your app, and many more..."
        ),
        AccordionItem(
            title: "What if I want a slightly different tech stack?",
            description: "In this case, you can email me at me@marospetrus.com and I'll take care of the next steps!"
        ),
        AccordionItem(
            title: "Is notescan for beginners?",
            description: "Of course it is! notescan Xcode project is built on top of the clean architecture and best coding practices. I would encourage everyone to dive into that! It will help tremendously not only your project but also your career as iOS Developer as many companies require some knowledge of the clean architecture and SOLID principles."
        ),
        AccordionItem(
            title: "Is notescan being continuosly updated?",
            description: "Yes, I am constantly working on improving this code based on my current needs for my apps. notescan gets updates based on customers feedback, new iOS versions, bug fixes, and so on..."
        )
    ])
}
