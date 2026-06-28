import SwiftUI
import Inject
import SwiftData

struct FlashcardSessionView: View {
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FlashcardSessionViewModel?
    @State private var bookmarkPulse: Bool = false
    @ObserveInjection var inject

    let config: FlashcardDeckConfig

    var body: some View {
        Group {
            if let vm = viewModel {
                content(for: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel?.deckTitle ?? "")
        .toolbar {
            if let vm = viewModel, case .studying = vm.state {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.toggleBookmark()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            bookmarkPulse.toggle()
                        }
                    } label: {
                        Image(systemName: vm.isCurrentBookmarked ? "bookmark.fill" : "bookmark")
                            .scaleEffect(bookmarkPulse ? 1.2 : 1.0)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = FlashcardSessionViewModel(
                    config: config,
                    progress: DIContainer.shared.userProgressRepository(context: modelContext)
                )
                viewModel = vm
                vm.start()
            }
        }
        .enableInjection()
    }

    @ViewBuilder
    private func content(for vm: FlashcardSessionViewModel) -> some View {
        switch vm.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty(let message):
            ContentUnavailableView {
                Label("No cards", systemImage: "rectangle.stack.badge.minus")
            } description: {
                Text(message)
            } actions: {
                Button("Done") { router.navigateBack() }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
            }

        case .studying(let card, let isFlipped, let position, let total):
            studyView(card: card, isFlipped: isFlipped, position: position, total: total, vm: vm)

        case .finished(let reviewed, let seconds):
            finishedView(reviewed: reviewed, seconds: seconds)
        }
    }

    private func studyView(
        card: FlashcardDTO,
        isFlipped: Bool,
        position: Int,
        total: Int,
        vm: FlashcardSessionViewModel
    ) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(position), total: Double(total))
                .tint(theme.accent)
                .padding(.horizontal)

            Text("Card \(position) of \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)

            cardFace(card: card, isFlipped: isFlipped)
                .padding(.horizontal)
                .frame(maxHeight: .infinity)
                .onTapGesture { withAnimation(.easeInOut(duration: 0.18)) { vm.flip() } }

            if isFlipped {
                gradeButtons(vm: vm)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            } else {
                Button { withAnimation(.easeInOut(duration: 0.18)) { vm.flip() } } label: {
                    Label("Tap card to reveal answer", systemImage: "rectangle.portrait.on.rectangle.portrait")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 12)
    }

    private func cardFace(card: FlashcardDTO, isFlipped: Bool) -> some View {
        let fillColor = isFlipped ? theme.accent.opacity(0.08) : Color(.secondarySystemGroupedBackground)
        return VStack(spacing: 14) {
            HStack {
                Text(card.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(theme.accent.opacity(0.15))
                    .foregroundStyle(theme.accent)
                    .clipShape(Capsule())
                Spacer()
                Text(isFlipped ? "BACK" : "FRONT")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ScrollView {
                // .id forces a view-identity swap on flip → SwiftUI uses the
                // attached transition (opacity) instead of interpolating font
                // size/position, which made words shift visibly during the
                // spring. transaction(.disablesAnimations) keeps any inherited
                // animation from re-applying to the new copy.
                Text(isFlipped ? card.back : card.front)
                    .font(isFlipped ? .body : .title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .id(isFlipped)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.18), value: isFlipped)

            Spacer()

            if isFlipped, let source = card.source {
                Text(source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(fillColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.accent.opacity(isFlipped ? 0.35 : 0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func gradeButtons(vm: FlashcardSessionViewModel) -> some View {
        HStack(spacing: 8) {
            gradeButton(.again, color: .red, vm: vm)
            gradeButton(.hard,  color: .orange, vm: vm)
            gradeButton(.good,  color: theme.accent, vm: vm)
            gradeButton(.easy,  color: .blue, vm: vm)
        }
    }

    private func gradeButton(_ grade: FlashcardGrade, color: Color, vm: FlashcardSessionViewModel) -> some View {
        Button {
            vm.grade(grade)
        } label: {
            Text(grade.label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func finishedView(reviewed: Int, seconds: Int) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(theme.accent)
            Text("Session complete")
                .font(.title2.bold())
            Text("Reviewed \(reviewed) cards in \(seconds / 60)m \(seconds % 60)s")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                router.navigateBack()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
