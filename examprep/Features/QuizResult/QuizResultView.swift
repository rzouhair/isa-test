import SwiftUI
import SwiftData
import Inject

struct QuizResultView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    let sessionId: UUID

    @State private var session: PracticeSession?
    @State private var previousScore: Double?
    @State private var hasCheckedReviewPrompt: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let s = session {
                    summary(session: s)
                    stats(session: s)
                    insights(session: s)
                    actions(session: s)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
            maybePromptForReview()
        }
        .enableInjection()
    }

    // MARK: - Summary

    private func summary(session: PracticeSession) -> some View {
        let passed = session.score >= session.passThreshold
        let tint: Color = passed ? .green : .orange

        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0.001, session.score))
                    .rotation(.degrees(-90))
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                Text("\(Int(session.score * 100))%")
                    .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
            }
            .frame(width: 128, height: 128)

            Text(passed ? "Passed" : "Keep practicing")
                .font(.headline)
                .foregroundStyle(passed ? theme.accent : .primary)

            Text("Threshold \(Int(session.passThreshold * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Stats

    private func stats(session: PracticeSession) -> some View {
        let correct = session.answers.filter(\.correct).count
        let answered = session.answers.count
        let totalMs = session.answers.map(\.timeMs).reduce(0, +)

        return HStack(spacing: 1) {
            statCell(value: "\(correct)", label: "Correct")
            Divider().frame(height: 48)
            statCell(value: "\(answered)", label: "Answered")
            Divider().frame(height: 48)
            statCell(value: timeString(totalMs: totalMs), label: "Time")
        }
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Insights

    @ViewBuilder
    private func insights(session: PracticeSession) -> some View {
        let answered = session.answers.count
        let correct = session.answers.filter(\.correct).count
        let wrong = answered - correct
        let totalMs = session.answers.map(\.timeMs).reduce(0, +)
        let avgSec = answered == 0 ? 0 : Double(totalMs) / Double(answered) / 1000.0
        let streak = longestCorrectStreak(in: session)

        VStack(spacing: 0) {
            insightRow(label: "Avg time / question", value: String(format: "%.1fs", avgSec), divider: true)
            insightRow(label: "Best streak", value: streak == 0 ? "—" : "\(streak) in a row", divider: true)
            insightRow(label: "Wrong answers", value: "\(wrong)", divider: previousScore != nil)
            if let prev = previousScore {
                let delta = session.score - prev
                let sign = delta >= 0 ? "+" : ""
                let arrow = delta > 0.001 ? "arrow.up" : (delta < -0.001 ? "arrow.down" : "minus")
                let tint: Color = delta > 0.001 ? .green : (delta < -0.001 ? .red : .secondary)
                insightRow(
                    label: "vs. last attempt",
                    value: "\(sign)\(Int(delta * 100))%",
                    valueIcon: arrow,
                    valueTint: tint,
                    divider: false
                )
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func insightRow(
        label: String,
        value: String,
        valueIcon: String? = nil,
        valueTint: Color = .primary,
        divider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let icon = valueIcon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(valueTint)
                }
                Text(value)
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(valueTint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if divider {
                Divider().padding(.leading, 14)
            }
        }
    }

    private func longestCorrectStreak(in session: PracticeSession) -> Int {
        var best = 0
        var run = 0
        for a in session.answers.sorted(by: { $0.answeredAt < $1.answeredAt }) {
            if a.correct {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        return best
    }

    // MARK: - Actions

    private func actions(session: PracticeSession) -> some View {
        VStack(spacing: 8) {
            Button {
                router.startSession(.reviewSession(sessionId: session.id), gatedBy: appState)
            } label: {
                Text("Review all questions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                let retry = QuizConfig(
                    kind: session.kind,
                    licenseCode: session.licenseCode,
                    categoryCode: session.categoryCode,
                    questionIds: session.questionIds,
                    passThreshold: session.passThreshold,
                    timeLimitSec: session.timeLimitSec
                )
                guard appState.isProUser else {
                    DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "session_gate"])
                    appState.showPaywall()
                    return
                }
                router.replaceTop(with: .quizSession(config: retry))
            } label: {
                Text("Try again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("Back to practice tests") {
                router.navigateBack()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Load

    private func load() {
        let id = sessionId
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        let fetched = (try? modelContext.fetch(desc))?.first
        session = fetched

        // Look up the most recent completed session in the same scope for
        // the "vs. last attempt" delta.
        if let s = fetched {
            let lic = s.licenseCode, cat = s.categoryCode, thisId = s.id
            let prevPredicate = #Predicate<PracticeSession> { other in
                other.licenseCode == lic
                && other.categoryCode == cat
                && other.id != thisId
                && other.endedAt != nil
            }
            var prevDesc = FetchDescriptor<PracticeSession>(
                predicate: prevPredicate,
                sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
            )
            prevDesc.fetchLimit = 1
            previousScore = (try? modelContext.fetch(prevDesc))?.first?.score
        }
    }

    private func timeString(totalMs: Int) -> String {
        let totalSec = totalMs / 1000
        let m = totalSec / 60
        let s = totalSec % 60
        return "\(m)m \(s)s"
    }

    /// Trigger SKStoreReviewController on a passed session if milestone gates
    /// are met. Runs once per result view visit.
    private func maybePromptForReview() {
        guard !hasCheckedReviewPrompt else { return }
        hasCheckedReviewPrompt = true
        guard let session, session.score >= session.passThreshold else { return }
        guard ReviewPromptService.recordPassAndShouldPrompt() else { return }
        // Small delay so the result UI lands before the system sheet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            requestReview()
        }
    }
}
