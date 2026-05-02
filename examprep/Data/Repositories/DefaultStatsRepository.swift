import Foundation

final class DefaultStatsRepository: StatsRepositoryProtocol {
    private let content: ContentRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol

    init(content: ContentRepositoryProtocol, progress: UserProgressRepositoryProtocol) {
        self.content = content
        self.progress = progress
    }

    func categoryStats(licenseCode: String, stateCode: String) -> [CategoryStats] {
        guard let categories = try? content.categories(licenseCode: licenseCode) else { return [] }
        let sessions = progress.sessions(limit: 200)
        return categories.map { cat in
            let matching = sessions.filter {
                $0.licenseCode == licenseCode &&
                $0.stateCode == stateCode &&
                $0.categoryCode == cat.code &&
                $0.endedAt != nil
            }
            let avg: Double = matching.isEmpty ? 0 : matching.map(\.score).reduce(0, +) / Double(matching.count)
            return CategoryStats(
                code: cat.code,
                name: cat.name,
                avgScore: avg,
                attempts: matching.count,
                lastAttemptedAt: matching.compactMap(\.endedAt).max()
            )
        }
    }

    func categoryProgress(licenseCode: String, stateCode: String, lang: String) -> [CategoryProgress] {
        guard let categories = try? content.categories(licenseCode: licenseCode) else { return [] }
        let totals = (try? content.questionCounts(licenseCode: licenseCode, stateCode: stateCode, lang: lang)) ?? [:]

        // questionId → categoryCode map for cross-session attribution.
        let categoryById: [Int: String] = {
            var map: [Int: String] = [:]
            let byId = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.code) })
            let rows = (try? content.questions(
                licenseCode: licenseCode,
                stateCode: stateCode,
                categoryCode: nil,
                lang: lang,
                limit: nil
            )) ?? []
            for (q, _) in rows {
                if let code = byId[q.categoryId] { map[q.id] = code }
            }
            return map
        }()

        let sessions = progress.sessions(limit: 500)
            .filter { $0.licenseCode == licenseCode && $0.stateCode == stateCode }

        // Distinct answered questionIds per category (any session kind).
        var answeredIds: [String: Set<Int>] = [:]
        for session in sessions {
            for answer in session.answers {
                guard let code = categoryById[answer.questionId] else { continue }
                answeredIds[code, default: []].insert(answer.questionId)
            }
        }

        // Avg test score = mean PracticeSession.score of completed practice/simulator runs per category.
        var scoresByCat: [String: [Double]] = [:]
        for session in sessions where session.endedAt != nil {
            guard let code = session.categoryCode else { continue }
            guard session.kind == .practice || session.kind == .simulator else { continue }
            scoresByCat[code, default: []].append(session.score)
        }

        return categories.map { cat in
            let scores = scoresByCat[cat.code] ?? []
            let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
            return CategoryProgress(
                code: cat.code,
                name: cat.name,
                iconName: Self.iconName(for: cat.code),
                attemptedDistinct: answeredIds[cat.code]?.count ?? 0,
                totalQuestions: totals[cat.code] ?? 0,
                avgTestScore: avg
            )
        }
    }

    private static func iconName(for categoryCode: String) -> String {
        switch categoryCode {
        case "general_knowledge": return "book.fill"
        case "air_brakes": return "wind"
        case "combination_vehicles": return "truck.box.fill"
        case "doubles_triples": return "rectangle.stack.fill"
        case "hazmat": return "exclamationmark.triangle.fill"
        case "passenger": return "person.2.fill"
        case "pre_trip": return "checklist"
        case "school_bus": return "bus.fill"
        case "tanker": return "drop.fill"
        case "road_signs", "motorcycle_signs": return "signpost.right.fill"
        case "traffic_rules": return "car.fill"
        case "motorcycle_basics": return "bicycle"
        default: return "square.grid.2x2.fill"
        }
    }

    /// Weighted average of the last 5 completed practice/simulator sessions vs threshold,
    /// with a small momentum bonus/penalty based on the most recent trend.
    func passingProbability(licenseCode: String, stateCode: String) -> Double {
        let recent = progress.sessions(limit: 5)
            .filter { $0.licenseCode == licenseCode && $0.stateCode == stateCode && $0.endedAt != nil }
        guard !recent.isEmpty else { return 0 }

        let avgScore = recent.map(\.score).reduce(0, +) / Double(recent.count)
        let avgThreshold = recent.map(\.passThreshold).reduce(0, +) / Double(recent.count)
        let delta = avgScore - (avgThreshold - 0.05)

        var momentum: Double = 0
        if recent.count >= 3 {
            let first3 = recent.prefix(3).map(\.score)
            if first3[0] > first3[1] && first3[1] > first3[2] { momentum = 0.05 }
            else if first3[0] < first3[1] && first3[1] < first3[2] { momentum = -0.05 }
        }

        return max(0, min(1, delta + momentum))
    }

    func weakQuestionIds(limit: Int) -> [Int] {
        progress.allAttempts()
            .filter { $0.status == .weak || $0.status == .learning }
            .sorted {
                // Rank by wrong rate desc, then most-recent wrong first.
                let lhsRate = Double($0.attemptCount - $0.correctCount) / Double(max($0.attemptCount, 1))
                let rhsRate = Double($1.attemptCount - $1.correctCount) / Double(max($1.attemptCount, 1))
                if lhsRate != rhsRate { return lhsRate > rhsRate }
                return ($0.lastAttemptedAt ?? .distantPast) > ($1.lastAttemptedAt ?? .distantPast)
            }
            .prefix(limit)
            .map(\.questionId)
    }

    func dueReviewIds(limit: Int) -> [Int] {
        let now = Date()
        return progress.allAttempts()
            .filter { $0.status != .mastered && isDue($0, now: now) }
            .sorted { dueDate(for: $0) < dueDate(for: $1) }
            .prefix(limit)
            .map(\.questionId)
    }

    func dueReviewCount() -> Int {
        let now = Date()
        return progress.allAttempts()
            .filter { $0.status != .mastered && isDue($0, now: now) }
            .count
    }

    /// Due if scheduled time has passed. Legacy rows (no schedule yet) count
    /// as due when they're weak/learning so existing users see the queue.
    private func isDue(_ attempt: QuestionAttempt, now: Date) -> Bool {
        if let due = attempt.nextReviewAt { return due <= now }
        return attempt.status == .weak || attempt.status == .learning
    }

    private func dueDate(for attempt: QuestionAttempt) -> Date {
        attempt.nextReviewAt ?? attempt.lastAttemptedAt ?? .distantPast
    }

    func examCountdownSeconds() -> TimeInterval? {
        guard let date = progress.profile()?.examDate else { return nil }
        let interval = date.timeIntervalSinceNow
        return interval > 0 ? interval : nil
    }

    func currentStreakDays() -> Int {
        progress.currentStreakDays()
    }
}
