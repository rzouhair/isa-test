import SwiftUI
import Inject
import RevenueCat
import RevenueCatUI

struct SettingsView: View {
    @ObserveInjection var inject

    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) private var appState

    @State var viewModel: SettingsViewModel

    var body: some View {
        @Bindable var appStateBindable = appState
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                List {
                    ForEach(SettingsViewModel.SettingsSection.allCases.filter { !$0.items.isEmpty }) { section in
                        Section(section.name) {
                            ForEach(section.items) { item in
                                row(for: item)
                                    .listRowBackground(Color.gray.opacity(0.08))
                            }
                        }
                    }

                    Section("About") {
                        Text(Constants.isaContentDisclaimer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.gray.opacity(0.08))
                    }

                    #if DEBUG
                    Section("Developer") {
                        Toggle(isOn: $appStateBindable.debugForceProOverride) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bypass subscription")
                                    Text(appState.debugForceProOverride
                                         ? "All Pro features unlocked"
                                         : "Real entitlement check active")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "lock.open.fill")
                                    .foregroundStyle(appState.debugForceProOverride ? theme.accent : .secondary)
                            }
                        }
                        .tint(theme.accent)
                        .listRowBackground(Color.gray.opacity(0.08))
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
                .navigationDestination(for: Router.Route.self) { route in
                    destinationView(for: route)
                }
                Spacer()
                VStack {
                    Text(Constants.appName)
                    Text(viewModel.versionString)
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

    @ViewBuilder
    private func row(for item: SettingsViewModel.SettingsItem) -> some View {
        if let route = item.route {
            NavigationLink(value: route) {
                HStack {
                    Label(item.name, systemImage: item.icon)
                    Spacer()
                }
            }
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
        }
    }

    @ViewBuilder
    private func destinationView(for route: Router.Route) -> some View {
        switch route {
        case .examDatePicker: ExamDatePickerView()
        case .bookmarks: BookmarksView()
        case .flashcardsLibrary: FlashcardsLibraryView()
        case .flashcardBookmarks: FlashcardBookmarksView()
        case .aiTutor(let id): AITutorView(questionId: id)
        default: EmptyView()
        }
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
    SettingsView(viewModel: SettingsViewModel(onEvent: { _ in }))
}
