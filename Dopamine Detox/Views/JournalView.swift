import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: JournalViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: JournalViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("New entry") {
                    Picker("Prompt", selection: $viewModel.selectedPrompt) {
                        ForEach(viewModel.prompts, id: \.self) { prompt in
                            Text(prompt).tag(prompt)
                        }
                    }

                    TextEditor(text: $viewModel.entryText)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)

                    Button {
                        viewModel.saveEntry()
                    } label: {
                        Label("Save reflection", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("History") {
                    if appState.journalEntries.isEmpty {
                        ContentUnavailableView("No entries yet", systemImage: "text.book.closed", description: Text("Capture how your mind reacts during detox sessions."))
                    } else {
                        ForEach(appState.journalEntries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.prompt)
                                        .font(.headline)
                                    Spacer()
                                    Text(entry.date, format: .dateTime.weekday().day().month())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(entry.text)
                                    .font(.body)
                                if let summary = entry.aiSummary {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .foregroundStyle(.accent)
                                        Text(summary)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Journal")
        }
    }
}

#Preview {
    let state = AppState()
    return JournalView(appState: state)
        .environmentObject(state)
}
