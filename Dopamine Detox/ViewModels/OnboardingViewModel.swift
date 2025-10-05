import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var questions: [OnboardingQuestion]
    @Published var responseScores: [UUID: Int]
    @Published var answeredQuestions: Set<UUID>

    let options: [OnboardingOption] = [
        OnboardingOption(label: "Rarely", score: 0),
        OnboardingOption(label: "Sometimes", score: 1),
        OnboardingOption(label: "Often", score: 2),
        OnboardingOption(label: "Very Often", score: 3),
        OnboardingOption(label: "Constantly", score: 4)
    ]

    init() {
        let baseWeight = 1.0 / 8.0
        questions = [
            OnboardingQuestion(prompt: "How often do you lose track of time scrolling?", helpText: "High frequency indicates overstimulation.", weight: baseWeight),
            OnboardingQuestion(prompt: "Do you check your phone within 5 minutes of waking?", helpText: "Morning habits set the tone for the day.", weight: baseWeight),
            OnboardingQuestion(prompt: "How restless do you feel when away from screens?", helpText: "Restlessness = higher dopamine load.", weight: baseWeight),
            OnboardingQuestion(prompt: "How often do notifications interrupt deep work?", helpText: "Interruptions fracture focus.", weight: baseWeight),
            OnboardingQuestion(prompt: "How late do you stay up browsing or gaming?", helpText: "Late hours affect recovery.", weight: baseWeight),
            OnboardingQuestion(prompt: "How impulsive are your social media checks?", helpText: "Impulse loops accelerate dopamine spikes.", weight: baseWeight),
            OnboardingQuestion(prompt: "How difficult is it to start a focused task?", helpText: "Difficulty starting hints at overload.", weight: baseWeight),
            OnboardingQuestion(prompt: "How satisfied are you with your current balance?", helpText: "Satisfaction correlates with lower stimulation.", weight: baseWeight)
        ]
        responseScores = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, 2) })
        answeredQuestions = []
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(answeredQuestions.count) / Double(questions.count)
    }

    func score() -> Int {
        let totalWeight = questions.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let weightedScore = questions.reduce(0.0) { partial, question in
            let answer = Double(responseScores[question.id] ?? 0)
            let normalized = answer / 4.0
            return partial + (normalized * question.weight)
        }
        return Int((weightedScore / totalWeight) * 100)
    }
}
