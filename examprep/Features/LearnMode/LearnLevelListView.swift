import SwiftUI
import SwiftData
import Inject

struct LearnLevelListView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let categoryCode: String

    @State private var levels: [LearnLevel] = []
    @State private var categoryName: String = ""
    @State private var licenseCode: String = ""
    @State private var stateCode: String = ""
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let error {
                    Text(error).font(.callout).foregroundStyle(.secondary).padding()
                }

                ForEach(levels) { level in
                    levelRow(level)
                }
            }
            .padding(16)
        }
        .navigationTitle(categoryName.isEmpty ? "Learn" : "Learn: \(categoryName)")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private func levelRow(_ level: LearnLevel) -> some View {
        Button {
            guard !level.locked else { return }
            let config = QuizConfig(
                kind: .learn,
                licenseCode: licenseCode,
                stateCode: stateCode,
                categoryCode: categoryCode,
                questionIds: level.questionIds,
                passThreshold: LearnLevelService.unlockThreshold,
                timeLimitSec: nil
            )
            DIContainer.shared.analyticsService.capture(.learnSessionStarted, properties: [
                "category": categoryCode,
                "level": level.id,
            ])
            router.startSession(.quizSession(config: config), gatedBy: appState)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(level.locked ? Color(.systemFill) : theme.accent.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Text("\(level.id)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(level.locked ? .secondary : theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Level \(level.id)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if level.locked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(level.masteredRatio * 100))% mastered")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: level.masteredRatio)
                        .tint(level.masteredRatio >= LearnLevelService.unlockThreshold ? .green : theme.accent)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(level.locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(level.locked)
    }

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        guard let profile = progress.profile() else {
            error = "Pick a license and state first."
            return
        }
        licenseCode = profile.licenseCode
        stateCode = profile.stateCode
        do {
            let categories = try DIContainer.shared.contentRepository.categories(licenseCode: licenseCode)
            categoryName = categories.first { $0.code == categoryCode }?.name ?? "Learn"

            let rows = try DIContainer.shared.contentRepository.questions(
                licenseCode: licenseCode,
                stateCode: stateCode,
                categoryCode: categoryCode,
                lang: profile.preferredLang,
                limit: nil
            )
            let ids = rows.map(\.0.id)
            levels = LearnLevelService.buildLevels(questionIds: ids, attempts: progress.allAttempts())
        } catch {
            self.error = "Couldn't load levels: \(error.localizedDescription)"
        }
    }
}
