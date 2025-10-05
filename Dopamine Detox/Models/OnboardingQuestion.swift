import Foundation

struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let helpText: String
    /// Weight defines the contribution (0-1) of this question to the overall index.
    let weight: Double
}

struct OnboardingOption: Identifiable {
    let id = UUID()
    let label: String
    /// Score between 0 (low stimulation) and 4 (high stimulation).
    let score: Int
}
