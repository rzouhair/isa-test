import Foundation

struct LearnLevel: Identifiable, Hashable, Sendable {
    let id: Int                  // 1-based
    let questionIds: [Int]
    let masteredRatio: Double    // 0.0 – 1.0
    let locked: Bool
}

/// Pure logic for learn-mode level computation so it can be unit-tested
/// without hitting SwiftData or the content DB.
enum LearnLevelService {
    static let questionsPerLevel = 10
    static let unlockThreshold = 0.8

    static func buildLevels(
        questionIds: [Int],
        attempts: [QuestionAttempt]
    ) -> [LearnLevel] {
        let sorted = questionIds.sorted()
        let batches = chunk(sorted, size: questionsPerLevel)
        let byId = Dictionary(uniqueKeysWithValues: attempts.map { ($0.questionId, $0) })

        var prevMastered = true
        return batches.enumerated().map { idx, batch in
            let count = batch.count
            let mastered = batch.filter { byId[$0]?.status == .mastered }.count
            let ratio = count == 0 ? 0 : Double(mastered) / Double(count)
            let locked = idx > 0 && !prevMastered
            prevMastered = ratio >= unlockThreshold
            return LearnLevel(id: idx + 1, questionIds: batch, masteredRatio: ratio, locked: locked)
        }
    }

    private static func chunk(_ array: [Int], size: Int) -> [[Int]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<Swift.min($0 + size, array.count)])
        }
    }
}
