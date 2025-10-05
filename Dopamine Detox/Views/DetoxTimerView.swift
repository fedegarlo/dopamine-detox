import SwiftUI

struct DetoxTimerView: View {
    @StateObject private var viewModel: DetoxTimerViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: DetoxTimerViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Choose your detox length")
                    .font(.title3)
                    .fontWeight(.semibold)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(DetoxDuration.allCases) { duration in
                            Button {
                                guard !viewModel.isRunning else { return }
                                viewModel.selectedDuration = duration
                                viewModel.remainingTime = duration.rawValue
                            } label: {
                                VStack(spacing: 8) {
                                    Text(duration.label)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(duration.description)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 120)
                                }
                                .padding()
                                .frame(width: 160, height: 140)
                                .background(viewModel.selectedDuration == duration ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(viewModel.selectedDuration == duration ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: viewModel.isRunning ? viewModel.progress : 0)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                    VStack(spacing: 8) {
                        Text(viewModel.formattedRemaining)
                            .font(.largeTitle)
                            .monospacedDigit()
                            .fontWeight(.bold)
                        Text(viewModel.isRunning ? "Focus mode" : "Ready when you are")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.isRunning {
                        Button(role: .destructive) {
                            viewModel.cancelSession()
                        } label: {
                            Label("Abort", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            viewModel.startSession()
                        } label: {
                            Label("Start detox", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Focus Filters ready", systemImage: "moon.zzz")
                    .foregroundStyle(.secondary)
                Text("When you start a detox, enable Focus Filters to silence distracting notifications.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 24)
        .overlay(alignment: .bottom) {
            if viewModel.showCelebration {
                CelebrationBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
            }
        }
    }
}

private struct CelebrationBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "party.popper")
                .font(.title)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text("Clarity unlocked")
                    .font(.headline)
                Text("You completed a detox session. Streak +1!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 10)
    }
}

#Preview {
    DetoxTimerView(appState: AppState())
}
