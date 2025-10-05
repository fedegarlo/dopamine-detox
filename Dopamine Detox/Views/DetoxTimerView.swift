import RevenueCatUI
import SwiftUI
import UIKit

struct DetoxTimerView: View {
    @StateObject private var viewModel: DetoxTimerViewModel
    @State private var isCheckingAccess = false
    @State private var showingPaywall = false
    @State private var paywallError: PaywallError?
    @StateObject private var focusAutomation = FocusAutomationManager.shared
    @Environment(\.scenePhase) private var scenePhase

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
                    .padding(.vertical)
                }
            }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)

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
                                .padding(.vertical, 18)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            handleStartTapped()
                        } label: {
                            if isCheckingAccess {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Start detox", systemImage: "play.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isCheckingAccess)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }

            FocusAutomationCard(focusManager: focusAutomation)
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
        .overlay {
            if viewModel.showCelebration {
                ZStack {
                    Color(.systemBackground)
                        .opacity(0.9)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color("AccentColor"))
                            .symbolEffect(.bounce)
                        Text("Session completed!")
                            .font(.title2.bold())
                        Text("Great job staying focused")
                            .foregroundStyle(.secondary)
                    }
                    .onAppear {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.showCelebration)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(displayCloseButton: true)
                .ignoresSafeArea()
        }
        .alert(item: $paywallError) { error in
            Alert(
                title: Text("No se pudo comprobar la suscripción"),
                message: Text(error.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
        .onAppear {
            focusAutomation.refreshStatus()
        }
        .onChange(of: scenePhase) { _ in
            focusAutomation.refreshStatus()
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

private struct FocusAutomationCard: View {
    @ObservedObject var focusManager: FocusAutomationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let actionTitle = actionTitle {
                if #available(iOS 15.0, *) {
                    Button(actionTitle) {
                        Task { await performPrimaryAction() }
                    }
                    .controlSize(.small)
                } else {
                    Button(actionTitle) {
                        Task { await performPrimaryAction() }
                    }
                    .buttonStyle(DefaultButtonStyle())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var title: String {
        switch focusManager.status {
        case .unsupported:
            return "Focus Filters not available"
        case .needsAuthorization:
            return "Authorize Focus Filters"
        case .denied:
            return "Focus Filters denied"
        case .needsConfiguration:
            return "Choose a Focus to silence notifications"
        case .ready(let name):
            return "\(name) will auto-activate"
        }
    }

    private var description: String {
        switch focusManager.status {
        case .unsupported:
            return "Update to the latest iOS version to silence notifications automatically during detox sessions."
        case .needsAuthorization:
            return "Allow Dopamine Detox to control Focus Filters so we can mute notifications when a session begins."
        case .denied:
            return "You previously denied Focus Filters access. Enable it in Settings to silence notifications automatically."
        case .needsConfiguration:
            return "Pick which Focus mode the app should enable each time you start a detox."
        case .ready(let name):
            return "We'll enable \(name) as soon as your detox starts and disable it when you finish."
        }
    }

    private var iconName: String {
        switch focusManager.status {
        case .ready:
            return "moon.zzz.fill"
        case .unsupported, .needsAuthorization, .needsConfiguration, .denied:
            return "moon.zzz"
        }
    }

    private var actionTitle: String? {
        switch focusManager.status {
        case .unsupported:
            return nil
        case .needsAuthorization:
            return "Enable Focus Filters"
        case .denied:
            return "Open Settings"
        case .needsConfiguration:
            return "Choose Focus"
        case .ready:
            return "Change Focus"
        }
    }

    private var useProminentButton: Bool {
        switch focusManager.status {
        case .ready:
            return false
        case .unsupported, .needsAuthorization, .needsConfiguration, .denied:
            return true
        }
    }

    private func performPrimaryAction() async {
        switch focusManager.status {
        case .unsupported:
            break
        case .needsAuthorization:
            await focusManager.requestAuthorizationIfNeeded()
        case .needsConfiguration, .ready:
            await focusManager.presentConfigurationPicker(from: activeWindowScene())
        case .denied:
            focusManager.openSettings()
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

private extension DetoxTimerView {
    func handleStartTapped() {
        guard !isCheckingAccess else { return }
        isCheckingAccess = true

        Task {
            let result = await viewModel.requiresPaywallBeforeStartingSession()

            await MainActor.run {
                isCheckingAccess = false

                if let message = result.errorMessage {
                    paywallError = PaywallError(message: message)
                }

                if result.requiresPaywall {
                    showingPaywall = true
                } else {
                    viewModel.startSession()
                }
            }
        }
    }
}

private struct PaywallError: Identifiable {
    let id = UUID()
    let message: String
}

