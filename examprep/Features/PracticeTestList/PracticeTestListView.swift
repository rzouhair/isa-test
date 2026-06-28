import SwiftUI
import SwiftData
import Inject

/// Splits a category's question pool into deterministic numbered batches
/// and annotates each with its latest session status. Tiles are grouped
/// into tens when the category has more than one tier's worth so the user
/// isn't staring at a wall of 19 identical buttons.
struct PracticeTestListView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let categoryCode: String

    @State private var tests: [TestTile] = []
    @State private var licenseCode: String = Constants.licenseCode
    @State private var categoryName: String = ""
    @State private var passThreshold: Double = 0.76
    @State private var timeLimitSec: Int?
    @State private var error: String?

    private let questionsPerTest = 20
    private let testsPerGroup = 10

    enum TestStatus { case locked, start, continueTest, failed, passed }

    struct TestTile: Identifiable {
        let id: Int                // 1-based test number
        let questionIds: [Int]
        let status: TestStatus
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error {
                    Text(error).font(.callout).foregroundStyle(.secondary)
                }

                headerSummary

                ForEach(groupedBatches, id: \.offset) { group in
                    groupSection(group: group)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(categoryName.isEmpty ? "Practice" : categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    router.navigate(to: .learnLevelList(categoryCode: categoryCode))
                } label: {
                    Label("Learn", systemImage: "graduationcap")
                }
            }
        }
        .task { load() }
        .enableInjection()
    }

    // MARK: - Header summary

    private var headerSummary: some View {
        let total = tests.count
        let passed = tests.filter { $0.status == .passed }.count
        return HStack(spacing: 10) {
            Image(systemName: "list.number")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.accent)
            Text("\(total) test\(total == 1 ? "" : "s") · \(questionsPerTest) questions each")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            if passed > 0 {
                Text("\(passed) passed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Groups

    /// Returns [(offset: Int, tiles: [TestTile])] chunked by `testsPerGroup`.
    private var groupedBatches: [(offset: Int, tiles: [TestTile])] {
        guard !tests.isEmpty else { return [] }
        return stride(from: 0, to: tests.count, by: testsPerGroup).map { start in
            let end = min(start + testsPerGroup, tests.count)
            return (offset: start, tiles: Array(tests[start..<end]))
        }
    }

    @ViewBuilder
    private func groupSection(group: (offset: Int, tiles: [TestTile])) -> some View {
        // Only show the header if there's more than one group.
        if groupedBatches.count > 1, let first = group.tiles.first, let last = group.tiles.last {
            Text("Tests \(first.id) – \(last.id)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.top, 4)
        }
        LearningPathView(
            nodes: group.tiles.map(pathNode(for:)),
            onTap: { node in
                guard let tile = group.tiles.first(where: { $0.id == node.id }) else { return }
                startTest(tile)
            }
        )
    }

    private func pathNode(for tile: TestTile) -> LearningPathView.Node {
        LearningPathView.Node(
            id: tile.id,
            label: "Test \(tile.id)",
            status: mapStatus(tile.status)
        )
    }

    private func mapStatus(_ status: TestStatus) -> LearningPathView.Node.Status {
        switch status {
        case .locked: return .locked
        case .start: return .start
        case .continueTest: return .continueInProgress
        case .failed: return .failed
        case .passed: return .passed
        }
    }

    private func startTest(_ tile: TestTile) {
        guard tile.status != .locked else { return }
        let config = QuizConfig(
            kind: .practice,
            licenseCode: licenseCode,
            categoryCode: categoryCode,
            questionIds: tile.questionIds,
            passThreshold: passThreshold,
            timeLimitSec: timeLimitSec
        )
        router.startSession(.quizSession(config: config), gatedBy: appState)
    }

    // MARK: - Load

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let lang = progress.profile()?.preferredLang ?? "en"

        do {
            let categories = try DIContainer.shared.contentRepository.categories(licenseCode: licenseCode)
            categoryName = categories.first { $0.code == categoryCode }?.name ?? "Practice"

            if let spec = try DIContainer.shared.contentRepository.examSpec(
                licenseCode: licenseCode,
                categoryCode: categoryCode
            ) {
                passThreshold = spec.passThreshold
                timeLimitSec = spec.timeLimitSec
            }

            let questions = try DIContainer.shared.contentRepository.questions(
                licenseCode: licenseCode,
                categoryCode: categoryCode,
                lang: lang,
                limit: nil
            )
            let ids = questions.map(\.0.id).sorted()
            let batches = ids.chunked(into: questionsPerTest)
            let sessions = progress.sessions(limit: 200)
                .filter { $0.licenseCode == licenseCode && $0.categoryCode == categoryCode }

            var prevPassed = true
            tests = batches.enumerated().map { idx, batch in
                let matching = sessions.filter { Set($0.questionIds) == Set(batch) }
                let latest = matching.max(by: { ($0.endedAt ?? .distantPast) < ($1.endedAt ?? .distantPast) })
                let status: TestStatus
                if let latest {
                    if latest.endedAt == nil { status = .continueTest }
                    else if latest.passed { status = .passed }
                    else { status = .failed }
                } else {
                    status = prevPassed ? .start : .locked
                }
                if status == .passed { prevPassed = true }
                else if status == .start || status == .continueTest || status == .failed { prevPassed = false }
                return TestTile(id: idx + 1, questionIds: batch, status: status)
            }
        } catch {
            self.error = "Couldn't load tests: \(error.localizedDescription)"
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
