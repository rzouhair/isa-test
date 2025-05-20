//
//  SettingsView.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import SwiftUI
import Inject

struct SettingsView: View {
    @ObserveInjection var inject

    @Environment(\.dismiss) var dismiss

    @State var viewModel: SettingsViewModel

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                List {
                    ForEach(SettingsViewModel.SettingsSection.allCases, id: \.id) { section in
                        Section(section.name) {
                            ForEach(section.items, id: \.id) { item in
                                Button {
                                    viewModel.handleItemTap(item)
                                } label: {
                                    HStack {
                                        Label(item.name, systemImage: item.icon)
                                        Spacer()
                                        if item == .restorePurchase && viewModel.isLoadingRestoration {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .listRowBackground(Color.gray.opacity(0.08))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                Spacer()
                VStack {
                    Text("Made by user")
                    Text("Version \(viewModel.versionString)")
                }
                .frame(maxWidth: .infinity)
                .font(.footnote)
                .foregroundColor(.gray)
            }
            .font(.defaultText.regular)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Asset.Colors.appPrimary.swiftUIColor)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(Asset.Colors.appPrimary.swiftUIColor)
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $viewModel.isShowingManageSubscriptionsSheet)
        .fullScreenCover(isPresented: $viewModel.isShowingMailComposer) {
            MailView()
        }
        .enableInjection()
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(onEvent: { event in
        print(event)
    }))
}
