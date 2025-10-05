import Foundation

struct JournalEntry: Identifiable {
    let id = UUID()
    let date: Date
    let prompt: String
    var text: String
    var aiSummary: String?

    static var sampleData: [JournalEntry] {
        [
            JournalEntry(date: .now.addingTimeInterval(-86_400), prompt: "What felt real today?", text: "Took a long walk without my phone and noticed the smell of rain.", aiSummary: "Mindful walk created sensory reset."),
            JournalEntry(date: .now.addingTimeInterval(-172_800), prompt: "How did your mind react to silence?", text: "The first 10 minutes were restless but then my focus softened.", aiSummary: "Initial restlessness transitioned into calm focus."),
            JournalEntry(date: .now.addingTimeInterval(-259_200), prompt: "What felt real today?", text: "Shared dinner with friends, no devices on the table.", aiSummary: "Offline social time brought connection.")
        ]
    }
}
