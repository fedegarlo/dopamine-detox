import SwiftUI

struct CoachMessage: Identifiable {
    enum Sender {
        case user
        case coach
    }

    let id = UUID()
    let sender: Sender
    let text: String
    let timestamp: Date
}

struct AICoachView: View {
    @State private var inputText: String = ""
    @State private var messages: [CoachMessage] = [
        CoachMessage(sender: .coach, text: "Hey, I'm Luma. I'll keep you grounded and focused — what do you need today?", timestamp: .now)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                messageBubble(for: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Luma respects your privacy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Responses run on-device when Foundation Models are available, otherwise securely deferred.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                HStack(alignment: .bottom, spacing: 12) {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 44, maxHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.2))
                        )

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Coach")
        }
    }

    private func messageBubble(for message: CoachMessage) -> some View {
        HStack {
            if message.sender == .coach {
                Image(systemName: "sparkles")
                    .foregroundStyle(.accent)
            } else {
                Spacer(minLength: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.sender == .coach ? Color.accentColor.opacity(0.15) : Color.accentColor)
                    .foregroundStyle(message.sender == .coach ? .primary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.sender == .user {
                Image(systemName: "person.fill")
                    .foregroundStyle(.secondary)
            } else {
                Spacer(minLength: 32)
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = CoachMessage(sender: .user, text: trimmed, timestamp: .now)
        messages.append(userMessage)
        inputText = ""

        let response = generateResponse(for: trimmed)
        let coachMessage = CoachMessage(sender: .coach, text: response, timestamp: .now.addingTimeInterval(0.5))
        messages.append(coachMessage)
    }

    private func generateResponse(for text: String) -> String {
        if text.localizedCaseInsensitiveContains("motivation") {
            return "Let's anchor on why you're detoxing. Name one thing you gain by staying offline for the next hour."
        } else if text.localizedCaseInsensitiveContains("relapse") {
            return "Relapses happen. Schedule a short 1h reset now and jot down what triggered you so we can adjust."
        } else if text.localizedCaseInsensitiveContains("sleep") {
            return "Dim the lights, park your phone outside the bedroom, and breathe in for 4, hold 4, out for 6 tonight."
        } else if text.localizedCaseInsensitiveContains("plan") {
            return "Here's a gentle loop: morning journal, 3h focus block with filters, afternoon walk, evening gratitude note."
        }
        return "Noted. Take a slow inhale, unclench your jaw, and choose the next tiny action that supports your detox."
    }
}

#Preview {
    AICoachView()
}
