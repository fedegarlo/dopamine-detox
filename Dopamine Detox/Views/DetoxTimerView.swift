import RevenueCat
import RevenueCatUI
import SwiftUI
import UIKit

struct DetoxTimerView: View {
    @StateObject private var viewModel: DetoxTimerViewModel
    @State private var isCheckingAccess = false
    @State private var paywallPresentation: PaywallPresentation?
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
                CelebrationOverlay(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.showCelebration)
        .sheet(item: $paywallPresentation) { presentation in
            PaywallView(offering: presentation.offering, displayCloseButton: true)
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

private struct CelebrationOverlay: View {
    @ObservedObject var viewModel: DetoxTimerViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.9)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color("AccentColor"))
                        .symbolEffect(.bounce)

                    VStack(spacing: 8) {
                        Text("¡Sesión completada!")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("Tu progreso se ha actualizado correctamente.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        CelebrationMetricRow(icon: "flame.fill", text: viewModel.currentStreakDescription)
                        CelebrationMetricRow(icon: "hourglass", text: viewModel.totalFocusDescription)
                        CelebrationMetricRow(icon: "checkmark.circle", text: viewModel.completedSessionsDescription)
                    }

                    Button {
                        viewModel.dismissCelebration()
                    } label: {
                        Text("Ver mi progreso")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: 360)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(radius: 16)
                .padding(.horizontal)
                .onAppear {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

                Spacer()
            }
        }
    }
}

private struct CelebrationMetricRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentColor"))
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    DetoxTimerView(appState: AppState())
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
            }

            if result.requiresPaywall {
                await presentPaywall()
            } else {
                await MainActor.run {
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

private extension DetoxTimerView {
    func presentPaywall() async {
        do {
            // RevenueCat handles caching internally; offerings() will fetch if needed.
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current ?? offerings.all.values.first else {
                await MainActor.run {
                    paywallError = PaywallError(
                        message: "No hay una oferta disponible en este momento. Inténtalo más tarde."
                    )
                }
                return
            }

            await MainActor.run {
                paywallPresentation = PaywallPresentation(offering: offering)
            }
        } catch {
            await MainActor.run {
                paywallError = PaywallError(
                    message: "No pudimos cargar la suscripción en este momento. Vuelve a intentarlo más tarde."
                )
            }
        }
    }
}

private struct PaywallPresentation: Identifiable {
    let id = UUID()
    let offering: Offering
}
