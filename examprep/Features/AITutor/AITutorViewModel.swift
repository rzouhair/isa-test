import Foundation
import Observation

/// Optional Pro-gated feature. Hidden unless `Constants.aiTutorEnabled`.
/// All network and auth details pulled from `Constants` — keeps secrets out
/// of source via a simple configure-in-Constants pattern.
@MainActor
@Observable
final class AITutorViewModel {
    struct Message: Identifiable, Hashable {
        let id = UUID()
        let role: Role
        let content: String
        enum Role { case user, assistant, system }
    }

    private(set) var messages: [Message] = []
    var input: String = ""
    private(set) var loading: Bool = false
    private(set) var error: String?

    private let contextQuestion: QuestionDTO?
    private let correctAnswer: AnswerDTO?

    private static let quotaKey = "aiTutorUsageDate"
    private static let quotaCountKey = "aiTutorUsageCount"

    init(question: QuestionDTO? = nil, correctAnswer: AnswerDTO? = nil) {
        self.contextQuestion = question
        self.correctAnswer = correctAnswer
    }

    var isConfigured: Bool {
        !Constants.aiTutorEndpoint.isEmpty && !Constants.aiTutorAPIKey.isEmpty
    }

    var remainingQuota: Int? {
        guard Constants.aiTutorDailyLimit > 0 else { return nil }
        refreshQuotaIfNeeded()
        let used = UserDefaults.standard.integer(forKey: Self.quotaCountKey)
        return max(0, Constants.aiTutorDailyLimit - used)
    }

    func send() async {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        guard Constants.aiTutorEnabled else {
            error = "AI Tutor is disabled."
            return
        }

        if let remaining = remainingQuota, remaining <= 0 {
            error = "Daily limit reached — try again tomorrow."
            return
        }

        messages.append(Message(role: .user, content: prompt))
        input = ""
        loading = true
        defer { loading = false }

        guard isConfigured, let url = URL(string: Constants.aiTutorEndpoint) else {
            messages.append(Message(
                role: .assistant,
                content: "AI Tutor isn't configured yet. Set `aiTutorEndpoint` and `aiTutorAPIKey` in `Constants.swift`."
            ))
            return
        }

        do {
            let reply = try await callEndpoint(url: url, userPrompt: prompt)
            messages.append(Message(role: .assistant, content: reply))
            incrementQuota()
        } catch {
            self.error = error.localizedDescription
            messages.append(Message(role: .assistant, content: "Couldn't reach the tutor. Try again."))
        }
    }

    // MARK: - Networking

    private func callEndpoint(url: URL, userPrompt: String) async throws -> String {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(Constants.aiTutorAPIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = buildSystemPrompt()
        let body: [String: Any] = [
            "model": Constants.aiTutorModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "temperature": 0.3,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "AITutor", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let msg = first["message"] as? [String: Any],
            let content = msg["content"] as? String
        else {
            throw NSError(domain: "AITutor", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Malformed response"])
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSystemPrompt() -> String {
        var parts = [
            "You are a friendly DMV/CDL exam tutor.",
            "Keep answers under 3 sentences and cite the relevant rule.",
        ]
        if let q = contextQuestion { parts.append("Current question: \(q.text)") }
        if let a = correctAnswer { parts.append("Correct answer: \(a.text)") }
        return parts.joined(separator: " ")
    }

    // MARK: - Quota

    private func refreshQuotaIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = UserDefaults.standard.object(forKey: Self.quotaKey) as? Date
        if stored.map({ Calendar.current.startOfDay(for: $0) }) != today {
            UserDefaults.standard.set(today, forKey: Self.quotaKey)
            UserDefaults.standard.set(0, forKey: Self.quotaCountKey)
        }
    }

    private func incrementQuota() {
        refreshQuotaIfNeeded()
        let used = UserDefaults.standard.integer(forKey: Self.quotaCountKey)
        UserDefaults.standard.set(used + 1, forKey: Self.quotaCountKey)
    }
}
