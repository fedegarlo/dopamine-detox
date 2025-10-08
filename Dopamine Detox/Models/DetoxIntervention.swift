import Foundation

struct DetoxIntervention: Identifiable, Equatable {
    let id = UUID()
    let appName: String
    var displayName: String {
        let trimmed = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "la app" : trimmed
    }
}
