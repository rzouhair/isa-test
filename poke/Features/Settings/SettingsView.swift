//
//  SettingsView.swift
//  poke
//
//  Created by user on 06/03/2024.
//

import SwiftUI
import Inject
import RevenueCat
import RevenueCatUI

struct SettingsView: View {
    @ObserveInjection var inject

    @Environment(\.dismiss) var dismiss

    @State var viewModel: SettingsViewModel

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                List {
                    ForEach(SettingsViewModel.SettingsSection.allCases.filter { !$0.items.isEmpty }) { section in
                        Section(section.name) {
                            ForEach(section.items) { item in
                                if item == .importExport {
                                    NavigationLink {
                                        ImportExportView()
                                    } label: {
                                        Label(item.name, systemImage: item.icon)
                                    }
                                    .listRowBackground(Color.gray.opacity(0.08))
                                } else if item == .priceCheckInterval {
                                    HStack {
                                        Label(item.name, systemImage: item.icon)
                                        Spacer()
                                        Menu {
                                            ForEach(WatchlistPriceService.intervalOptions, id: \.self) { hours in
                                                Button {
                                                    viewModel.setRefreshInterval(hours)
                                                } label: {
                                                    if viewModel.selectedRefreshInterval == hours {
                                                        Label("Every \(hours)h", systemImage: "checkmark")
                                                    } else {
                                                        Text("Every \(hours)h")
                                                    }
                                                }
                                            }
                                        } label: {
                                            Text("Every \(viewModel.selectedRefreshInterval)h")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .listRowBackground(Color.gray.opacity(0.08))
                                } else if item == .priceCheckRemindersEnabled {
                                    Toggle(isOn: Binding(
                                        get: { viewModel.remindersEnabled },
                                        set: { viewModel.remindersEnabled = $0 }
                                    )) {
                                        Label(item.name, systemImage: item.icon)
                                    }
                                    .tint(theme.accent)
                                    .listRowBackground(Color.gray.opacity(0.08))
                                    .alert("Notifications disabled", isPresented: Binding(
                                        get: { viewModel.reminderPermissionDenied },
                                        set: { viewModel.reminderPermissionDenied = $0 }
                                    )) {
                                        Button("Open Settings") {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                        Button("Cancel", role: .cancel) {}
                                    } message: {
                                        Text("Enable notifications in Settings to receive daily reminders.")
                                    }
                                } else if item == .priceCheckReminderTime {
                                    HStack {
                                        Label(item.name, systemImage: item.icon)
                                        Spacer()
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { viewModel.reminderTime },
                                                set: { viewModel.reminderTime = $0 }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        .labelsHidden()
                                        .disabled(!viewModel.remindersEnabled)
                                    }
                                    .opacity(viewModel.remindersEnabled ? 1 : 0.5)
                                    .listRowBackground(Color.gray.opacity(0.08))
                                } else {
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
                }
                .scrollContentBackground(.hidden)
                Spacer()
                VStack {
                    Text("Made by RZouhair")
                    Text("Version \(viewModel.versionString)")
                }
                .frame(maxWidth: .infinity)
                .font(.footnote)
                .foregroundColor(.gray)
                .offset(y: -20)
            }
            .font(.defaultText.regular)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(theme.accent)
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $viewModel.isShowingManageSubscriptionsSheet)
        .sheet(isPresented: $viewModel.isShowingCustomerCenter) {
            CustomerCenterView()
        }
        .fullScreenCover(isPresented: $viewModel.isShowingMailComposer) {
            MailView()
        }
        .modifier(SentryTestAlertModifier(viewModel: viewModel))
        .enableInjection()
    }
}

private struct SentryTestAlertModifier: ViewModifier {
    let viewModel: SettingsViewModel

    func body(content: Content) -> some View {
        #if DEBUG
        content.alert(
            "Sentry Test Event",
            isPresented: Binding(
                get: { viewModel.sentryTestResult != nil },
                set: { if !$0 { viewModel.sentryTestResult = nil } }
            )
        ) {
            Button("OK") { viewModel.sentryTestResult = nil }
        } message: {
            Text(viewModel.sentryTestResult ?? "")
        }
        #else
        content
        #endif
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(onEvent: { event in
        print(event)
    }))
}
