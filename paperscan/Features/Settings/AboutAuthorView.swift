//
//  AboutMakerView.swift
//  Trading Tracker
//
//  Created by user on 17/01/2023.
//

import SwiftUI
import Inject

struct AboutAuthorView: View {
    @ObserveInjection var inject

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openUrl
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("About author")
                        .font(.title.bold)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(Color(uiColor: .label))
                    }
                }
                .padding(16)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Asset.Images.author.swiftUIImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        Text("Hi, I am Maros, the creator of this app.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(uiColor: .label))
                        Text("As a day trader myself, I built this app to suit my needs and requirements. I use the app every day to see how my strategy is evolving, what's working and what's not working. My objective is to become a full-time independent developer and to provide additional features to my apps.\n\nYou're helping me in my quest by subscribing to this app.\n\nPlease feel free to reach out to me at any moment via this app or my social media accounts.")
                            .foregroundColor(Color(uiColor: .label))
                        HStack(spacing: 16) {
                            Spacer()
                            Button {
                                guard let instagramUrl = URL(string: Constants.instagram) else { return }
                                openUrl(instagramUrl)
                            } label: {
                                Asset.Images.instagram.swiftUIImage
                            }
                            Button {
                                guard let twitterUrl = URL(string: Constants.twitter) else { return }
                                openUrl(twitterUrl)
                            } label: {
                                Asset.Images.twitterColor.swiftUIImage
                            }
                            Button {
                                guard let twitchUrl = URL(string: Constants.twitch) else { return }
                                openUrl(twitchUrl)
                            } label: {
                                Asset.Images.twitch.swiftUIImage
                            }
                            Button {
                                guard let instagramUrl = URL(string: "mailto:\(Constants.supportEmail)") else { return }
                                openUrl(instagramUrl)
                            } label: {
                                Image(systemName: "envelope")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(Color(uiColor: .label))
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .enableInjection()
    }
}

struct AboutAuthorView_Previews: PreviewProvider {
    static var previews: some View {
        AboutAuthorView()
    }
}
