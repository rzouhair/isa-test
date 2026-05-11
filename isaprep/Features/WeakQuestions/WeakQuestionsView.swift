import SwiftUI
import SwiftData
import Inject

struct WeakQuestionsView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var weakIds: [Int] = []
    @State private var licenseCode: String = Constants.licenseCode
    @State private var error: String?

    private let batchSize = 20

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let error {
                    Text(error).font(.callout).foregroundStyle(.secondary)
                }
                if weakIds.isEmpty {
                    emptyState
                } else {
                    startButton
                }
            }
            .padding(16)
        }
        .navigationTitle("Weak Questions")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(theme.celebration)
                Text("Strengthen skills")
                    .font(.title2.weight(.bold))
                Spacer()
            }
            Text("Practice the questions you've missed most. Getting them right promotes them out of your weak list.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(theme.accent)
            Text("No weak questions yet")
                .font(.headline)
            Text("Keep practicing — anything you get wrong will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var startButton: some View {
        VStack(spacing: 10) {
            Text("\(weakIds.count) weak question\(weakIds.count == 1 ? "" : "s") queued")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                let config = QuizConfig(
                    kind: .weak,
                    licenseCode: licenseCode,
                    categoryCode: nil,
                    questionIds: Array(weakIds.prefix(batchSize)),
                    passThreshold: 0.76,
                    timeLimitSec: nil
                )
                router.startSession(.quizSession(config: config), gatedBy: appState)
            } label: {
                Text("Start Weak-Questions Session")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func load() {
        let stats = DIContainer.shared.statsRepository(context: modelContext)
        weakIds = stats.weakQuestionIds(limit: batchSize)
    }
}
