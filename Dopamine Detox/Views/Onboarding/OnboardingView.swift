import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showResult: Bool = false
    @State private var calculatedScore: Int = 0
    @State private var hasSubmitted: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome to Dopamine Detox")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Answer a few questions to understand your current stimulation level. We'll tailor your detox plan and check-ins.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 32)

                ProgressView(value: viewModel.progress)
                    .tint(.accentColor)
                    .padding(.horizontal)
                    .padding(.vertical, 16)

                List {
                    ForEach(viewModel.questions) { question in
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(question.prompt)
                                    .font(.headline)
                                Text(question.helpText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Picker("Response", selection: binding(for: question)) {
                                    ForEach(viewModel.options) { option in
                                        Text(option.label)
                                            .tag(option.score)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.insetGrouped)

                VStack(spacing: 16) {
                    if !hasSubmitted {
                        Button {
                            calculatedScore = viewModel.score()
                            showResult = true
                            hasSubmitted = true
                        } label: {
                            Text("See my detox plan")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasAnsweredAll)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }

                    if showResult {
                        VStack(spacing: 6) {
                            Text("Your Dopamine Index is \(calculatedScore)")
                                .font(.headline)
                            Text(detoxRecommendation(for: calculatedScore))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .transition(.opacity)

                        Button {
                            appState.markOnboardingComplete(score: calculatedScore)
                        } label: {
                            Text("Start my detox journey")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var hasAnsweredAll: Bool {
        viewModel.answeredQuestions.count == viewModel.questions.count
    }

    private func binding(for question: OnboardingQuestion) -> Binding<Int> {
        Binding(
            get: {
                viewModel.responseScores[question.id] ?? 0
            },
            set: { newValue in
                viewModel.responseScores[question.id] = newValue
                viewModel.answeredQuestions.insert(question.id)
            }
        )
    }

    private func detoxRecommendation(for score: Int) -> String {
        switch score {
        case ..<30:
            return "You're in a healthy range. Schedule a 1 hour focus loop to stay sharp."
        case 30..<60:
            return "Mild overload. Try a 3 hour detox and daily mindful journaling."
        case 60..<80:
            return "High stimulation detected. Commit to a 3 day detox with nightly check-ins."
        default:
            return "Severe overstimulation. Start a guided 7 day reset with frequent breaks from screens."
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
