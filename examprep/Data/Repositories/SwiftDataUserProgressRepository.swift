import Foundation
import SwiftData

final class SwiftDataUserProgressRepository: UserProgressRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Profile

    func profile() -> UserExamProfile? {
        try? context.fetch(FetchDescriptor<UserExamProfile>()).first
    }

    @discardableResult
    func setProfile(licenseCode: String, examDate: Date?) throws -> UserExamProfile {
        if let existing = profile() {
            existing.licenseCode = licenseCode
            existing.examDate = examDate
            existing.updatedAt = Date()
            try context.save()
            return existing
        }
        let profile = UserExamProfile(licenseCode: licenseCode, examDate: examDate)
        context.insert(profile)
        try context.save()
        return profile
    }

    func updateExamDate(_ date: Date?) throws {
        guard let profile = profile() else { return }
        profile.examDate = date
        profile.updatedAt = Date()
        try context.save()
    }

    // MARK: Attempts

    func attempt(for questionId: Int) -> QuestionAttempt? {
        let predicate = #Predicate<QuestionAttempt> { $0.questionId == questionId }
        var desc = FetchDescriptor<QuestionAttempt>(predicate: predicate)
        desc.fetchLimit = 1
        return (try? context.fetch(desc))?.first
    }

    func recordAnswer(questionId: Int, correct: Bool, timeMs: Int) throws {
        let existing = attempt(for: questionId)
        let target: QuestionAttempt
        if let existing {
            target = existing
        } else {
            target = QuestionAttempt(questionId: questionId)
            context.insert(target)
        }
        target.applyAnswer(correct: correct, at: Date())
        try context.save()
    }

    func allAttempts() -> [QuestionAttempt] {
        (try? context.fetch(FetchDescriptor<QuestionAttempt>())) ?? []
    }

    // MARK: Sessions

    func createSession(_ session: PracticeSession) throws {
        context.insert(session)
        try context.save()
    }

    func completeSession(id: UUID, score: Double) throws {
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        guard let session = (try? context.fetch(desc))?.first else { return }
        session.score = score
        session.endedAt = Date()
        try context.save()
    }

    func deleteSession(id: UUID) throws {
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        guard let session = (try? context.fetch(desc))?.first else { return }
        context.delete(session)
        try context.save()
    }

    func updateSessionElapsed(id: UUID, seconds: Int) throws {
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        guard let session = (try? context.fetch(desc))?.first else { return }
        session.elapsedSecAtPause = seconds
        try context.save()
    }

    func purgeIncompleteSessions(olderThan: Date) throws {
        let predicate = #Predicate<PracticeSession> {
            $0.endedAt == nil && $0.startedAt < olderThan
        }
        let desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        let stale = (try? context.fetch(desc)) ?? []
        guard !stale.isEmpty else { return }
        for session in stale {
            context.delete(session)
        }
        try context.save()
    }

    func session(id: UUID) -> PracticeSession? {
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        return (try? context.fetch(desc))?.first
    }

    func sessions(limit: Int) -> [PracticeSession] {
        var desc = FetchDescriptor<PracticeSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        desc.fetchLimit = limit
        return (try? context.fetch(desc)) ?? []
    }

    func appendSessionAnswer(
        sessionId: UUID,
        questionId: Int,
        selectedAnswerId: Int?,
        correct: Bool,
        timeMs: Int
    ) throws {
        let predicate = #Predicate<PracticeSession> { $0.id == sessionId }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        guard let session = (try? context.fetch(desc))?.first else { return }

        let answer = SessionAnswer(
            questionId: questionId,
            selectedAnswerId: selectedAnswerId,
            correct: correct,
            timeMs: timeMs
        )
        context.insert(answer)
        answer.session = session
        try context.save()
    }

    // MARK: Bookmarks (questions)

    func toggleBookmark(questionId: Int) throws {
        let predicate = #Predicate<BookmarkedQuestion> { $0.questionId == questionId }
        var desc = FetchDescriptor<BookmarkedQuestion>(predicate: predicate)
        desc.fetchLimit = 1
        if let existing = (try? context.fetch(desc))?.first {
            context.delete(existing)
        } else {
            context.insert(BookmarkedQuestion(questionId: questionId))
        }
        try context.save()
    }

    func bookmarks() -> [Int] {
        ((try? context.fetch(FetchDescriptor<BookmarkedQuestion>())) ?? []).map(\.questionId)
    }

    func isBookmarked(_ questionId: Int) -> Bool {
        let predicate = #Predicate<BookmarkedQuestion> { $0.questionId == questionId }
        var desc = FetchDescriptor<BookmarkedQuestion>(predicate: predicate)
        desc.fetchLimit = 1
        return ((try? context.fetch(desc))?.first) != nil
    }

    // MARK: Bookmarks (flashcards)

    func toggleFlashcardBookmark(flashcardId: Int) throws {
        let predicate = #Predicate<BookmarkedFlashcard> { $0.flashcardId == flashcardId }
        var desc = FetchDescriptor<BookmarkedFlashcard>(predicate: predicate)
        desc.fetchLimit = 1
        if let existing = (try? context.fetch(desc))?.first {
            context.delete(existing)
        } else {
            context.insert(BookmarkedFlashcard(flashcardId: flashcardId))
        }
        try context.save()
    }

    func flashcardBookmarks() -> [Int] {
        ((try? context.fetch(FetchDescriptor<BookmarkedFlashcard>())) ?? []).map(\.flashcardId)
    }

    func isFlashcardBookmarked(_ flashcardId: Int) -> Bool {
        let predicate = #Predicate<BookmarkedFlashcard> { $0.flashcardId == flashcardId }
        var desc = FetchDescriptor<BookmarkedFlashcard>(predicate: predicate)
        desc.fetchLimit = 1
        return ((try? context.fetch(desc))?.first) != nil
    }

    // MARK: Flashcard reviews (SM-2)

    func flashcardReview(for flashcardId: Int) -> FlashcardReview? {
        let predicate = #Predicate<FlashcardReview> { $0.flashcardId == flashcardId }
        var desc = FetchDescriptor<FlashcardReview>(predicate: predicate)
        desc.fetchLimit = 1
        return (try? context.fetch(desc))?.first
    }

    func recordFlashcardReview(flashcardId: Int, grade: FlashcardGrade) throws {
        let target: FlashcardReview
        if let existing = flashcardReview(for: flashcardId) {
            target = existing
        } else {
            target = FlashcardReview(flashcardId: flashcardId)
            context.insert(target)
        }
        target.apply(grade: grade)
        try context.save()
    }

    func allFlashcardReviews() -> [FlashcardReview] {
        (try? context.fetch(FetchDescriptor<FlashcardReview>())) ?? []
    }

    // MARK: Streak

    func incrementStreak(minutes: Int, questions: Int) throws {
        let today = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<StudyStreak> { $0.date == today }
        var desc = FetchDescriptor<StudyStreak>(predicate: predicate)
        desc.fetchLimit = 1
        let streak: StudyStreak
        if let existing = (try? context.fetch(desc))?.first {
            streak = existing
        } else {
            streak = StudyStreak(date: today)
            context.insert(streak)
        }
        streak.minutesStudied += minutes
        streak.questionsAnswered += questions
        try context.save()
    }

    func currentStreakDays() -> Int {
        let all = ((try? context.fetch(FetchDescriptor<StudyStreak>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? [])
            .filter { $0.minutesStudied > 0 || $0.questionsAnswered > 0 }
        var count = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        for streak in all {
            if Calendar.current.isDate(streak.date, inSameDayAs: cursor) {
                count += 1
                cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else if streak.date < cursor {
                break
            }
        }
        return count
    }
}
