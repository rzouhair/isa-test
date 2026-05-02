import SwiftUI
import Inject

struct AITutorView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState

    let questionId: Int?

    @State private var vm = AITutorViewModel()

    var body: some View {
        Group {
            if !Constants.aiTutorEnabled {
                ContentUnavailableView(
                    "AI Tutor is off",
                    systemImage: "sparkles",
                    description: Text("Enable via `Constants.aiTutorEnabled` in source.")
                )
            } else if Constants.aiTutorProOnly && !appState.isProUser {
                lockedState
            } else {
                tutorContent
            }
        }
        .navigationTitle("AI Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .task { prepareContext() }
        .enableInjection()
    }

    private var lockedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(theme.accent)
            Text("AI Tutor — Pro feature")
                .font(.title3.weight(.semibold))
            Text("Get instant explanations and rule citations for any question.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Unlock Pro") {
                appState.showPaywall()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var tutorContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.messages) { msg in
                            bubble(msg: msg).id(msg.id)
                        }
                        if vm.loading {
                            HStack {
                                ProgressView().controlSize(.small)
                                Text("Thinking…").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    if let last = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            if let remaining = vm.remainingQuota {
                Text("\(remaining) questions left today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 8) {
                TextField("Ask anything", text: $vm.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await vm.send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(vm.loading || vm.input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
    }

    private func bubble(msg: AITutorViewModel.Message) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }
            Text(msg.content)
                .font(.callout)
                .foregroundStyle(msg.role == .user ? .white : .primary)
                .padding(10)
                .background(msg.role == .user ? theme.accent : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
            if msg.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private func prepareContext() {
        guard let id = questionId,
              let pair = try? DIContainer.shared.contentRepository.question(id: id) else { return }
        let correct = pair.1.first(where: { $0.isCorrect == 1 })
        vm = AITutorViewModel(question: pair.0, correctAnswer: correct)
    }
}
