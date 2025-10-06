import OSLog
import RevenueCat
import RevenueCatUI
import SwiftUI
import UIKit

struct DetoxTimerView: View {
    @StateObject private var viewModel: DetoxTimerViewModel
    @State private var isCheckingAccess = false
    @State private var paywallPresentation: PaywallPresentation?
    @State private var paywallError: PaywallError?
    @State private var paywallLogs: [PaywallLogEntry] = []
    @State private var isPaywallLogExpanded = true
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

            if !paywallLogs.isEmpty {
                PaywallLogPanel(entries: paywallLogs, isExpanded: $isPaywallLogExpanded)
                    .padding(.horizontal)
            }

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
                .onAppear {
                    paywallLogger.info("PaywallView appeared with offering \(presentation.offering.identifier, privacy: .public)")
                    showPaywallLog(level: .info, message: "Paywall mostrado con la oferta \(presentation.offering.identifier)")
                }
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
            paywallLogger.info("Checking paywall requirements before starting session")
            showPaywallLog(level: .info, message: "Comprobando requisitos de acceso antes de iniciar la sesión")

            let result = await viewModel.requiresPaywallBeforeStartingSession()

            paywallLogger.info(
                "requiresPaywallBeforeStartingSession returned requiresPaywall=\(result.requiresPaywall, privacy: .public) error=\(result.errorMessage ?? \"nil\", privacy: .public)"
            )
            showPaywallLog(
                level: .info,
                message: "Resultado de la comprobación: requierePaywall=\(result.requiresPaywall ? \"sí\" : \"no\") error=\(result.errorMessage ?? \"ninguno\")"
            )

            await MainActor.run {
                isCheckingAccess = false

                if let message = result.errorMessage {
                    paywallLogger.error("Paywall requirement check produced error message: \(message, privacy: .public)")
                    paywallError = PaywallError(message: message)
                    appendPaywallLog(level: .error, message: "Error al comprobar el acceso: \(message)")
                }
            }

            if result.requiresPaywall {
                await presentPaywall()
            } else {
                await MainActor.run {
                    viewModel.startSession()
                    appendPaywallLog(level: .success, message: "No se requiere paywall. Iniciando la sesión de detox")
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
            paywallLogger.info("Attempting to present paywall by fetching offerings")
            await appendPaywallLog(level: .info, message: "Buscando ofertas disponibles en RevenueCat…")

            // RevenueCat handles caching internally; offerings() will fetch if needed.
            let offerings = try await Purchases.shared.offerings()
            let currentIdentifier = offerings.current?.identifier ?? "nil"
            let availableIdentifiers = offerings.all.values.map { $0.identifier }.joined(separator: ", ")

            paywallLogger.info(
                "Offerings fetched. Current=\(currentIdentifier, privacy: .public) available=[\(availableIdentifiers, privacy: .public)]"
            )
            await appendPaywallLog(
                level: .info,
                message: "Ofertas recibidas. Actual=\(currentIdentifier) disponibles=[\(availableIdentifiers.isEmpty ? \"ninguna\" : availableIdentifiers)]"
            )
            guard let offering = offerings.current ?? offerings.all.values.first else {
                paywallLogger.warning("No offering available when attempting to present paywall")
                await MainActor.run {
                    paywallError = PaywallError(
                        message: "No hay una oferta disponible en este momento. Inténtalo más tarde."
                    )
                    appendPaywallLog(
                        level: .warning,
                        message: "RevenueCat no devolvió ninguna oferta para mostrar"
                    )
                }
                return
            }

            await MainActor.run {
                paywallLogger.info("Presenting paywall with offering \(offering.identifier, privacy: .public)")
                paywallPresentation = PaywallPresentation(offering: offering)
                appendPaywallLog(level: .success, message: "Mostrando la oferta \(offering.identifier)")
            }
        } catch {
            paywallLogger.error("Failed to load offerings: \(error.localizedDescription, privacy: .public)")
            await MainActor.run {
                paywallError = PaywallError(
                    message: "No pudimos cargar la suscripción en este momento. Vuelve a intentarlo más tarde."
                )
                appendPaywallLog(
                    level: .error,
                    message: "Error al cargar las ofertas: \(error.localizedDescription)"
                )
            }
        }
    }
}

private struct PaywallPresentation: Identifiable {
    let id = UUID()
    let offering: Offering
}

private let paywallLogger = Logger(subsystem: "com.dopamine-detox.app", category: "Paywall")

private enum PaywallLogLevel {
    case info
    case success
    case warning
    case error

    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.octagon"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

private struct PaywallLogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: PaywallLogLevel
    let message: String
}

private struct PaywallLogPanel: View {
    let entries: [PaywallLogEntry]
    @Binding var isExpanded: Bool

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(entries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: entry.level.icon)
                                    .foregroundStyle(entry.level.tint)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Self.timeFormatter.string(from: entry.timestamp))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(entry.message)
                                        .font(.footnote.monospaced())
                                        .foregroundStyle(.primary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .id(entry.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 220)
                .onChange(of: entries.count) { _ in
                    if let id = entries.last?.id {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
        } label: {
            Label("Registro de Paywall", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.default, value: entries.count)
    }
}

private extension DetoxTimerView {
    func showPaywallLog(level: PaywallLogLevel, message: String) {
        Task { @MainActor in
            appendPaywallLog(level: level, message: message)
        }
    }

    @MainActor
    func appendPaywallLog(level: PaywallLogLevel, message: String) {
        let maxEntries = 50
        if paywallLogs.count >= maxEntries {
            paywallLogs.removeFirst(paywallLogs.count - maxEntries + 1)
        }

        paywallLogs.append(PaywallLogEntry(level: level, message: message))
    }
}
