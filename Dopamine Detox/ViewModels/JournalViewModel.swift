import Foundation
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var entryText: String = ""
    @Published var selectedPrompt: String
    let prompts: [String]

    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.prompts = [
            "What felt real today?",
            "How did your mind react to silence?",
            "Where did you feel the biggest urge to scroll?",
            "What micro-win are you proud of?"
        ]
        self.selectedPrompt = prompts.first ?? "What felt real today?"
    }

    func saveEntry() {
        let trimmed = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let summary = summarize(text: trimmed)
        let entry = JournalEntry(date: Date(), prompt: selectedPrompt, text: trimmed, aiSummary: summary)
        appState.addJournalEntry(entry)
        entryText = ""
    }

    private func summarize(text: String) -> String {
        let sentences = text.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let last = sentences.last {
            return String(last.prefix(80))
        }
        return text.count > 80 ? String(text.prefix(80)) + "…" : text
    }
}
