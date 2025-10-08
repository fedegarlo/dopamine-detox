import Combine
import Foundation
import RevenueCat

@MainActor
final class DetoxTimerViewModel: ObservableObject {
    @Published var selectedDuration: DetoxDuration
    @Published var remainingTime: TimeInterval
    @Published var isRunning: Bool
    @Published var showCelebration: Bool = false

    private var timer: AnyCancellable?
    private unowned let appState: AppState
    init(appState: AppState) {
        self.appState = appState
        if let active = appState.activeSession {
            selectedDuration = active.duration
            let remaining = active.endsAt.timeIntervalSinceNow
            remainingTime = max(remaining, 0)
            isRunning = remaining > 0

            // Resume timer if session is still active
            if isRunning {
                startTimer()
            }
        } else {
            let defaultDuration: DetoxDuration = .oneHour
            selectedDuration = defaultDuration
            remainingTime = defaultDuration.rawValue
            isRunning = false
        }
    }

    var formattedRemaining: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = remainingTime >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remainingTime) ?? "--"
    }

    var progress: Double {
        guard isRunning || appState.activeSession != nil else { return 0 }
        let duration = appState.activeSession?.duration.rawValue ?? selectedDuration.rawValue
        guard duration > 0 else { return 0 }
        return 1 - (remainingTime / duration)
    }

    var currentStreakDescription: String {
        let days = appState.streak
        let suffix = days == 1 ? "día" : "días"
        return "\(days) \(suffix) de racha"
    }

    var totalFocusDescription: String {
        let minutes = appState.totalFocusMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let suffix = hours == 1 ? "hora" : "horas"
            return "\(hours) \(suffix) enfocadas"
        } else {
            return "\(minutes) min enfocados"
        }
    }

    var completedSessionsDescription: String {
        let sessions = appState.completedSessionCount
        let suffix = sessions == 1 ? "sesión completada" : "sesiones completadas"
        return "\(sessions) \(suffix)"
    }

    func startSession() {
        let session = DetoxSession(startedAt: Date(), duration: selectedDuration)
        appState.updateActiveSession(session)
        remainingTime = selectedDuration.rawValue
        isRunning = true
        showCelebration = false
        startTimer()
    }

    func dismissCelebration() {
        showCelebration = false
    }

    func requiresPaywallBeforeStartingSession() async -> (requiresPaywall: Bool, errorMessage: String?) {
        let completedSessions = appState.completedSessionCount
        guard completedSessions >= 1 else {
            return (false, nil)
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let hasActiveEntitlement = customerInfo.entitlements.active.isEmpty == false
            return (!hasActiveEntitlement, nil)
        } catch {
            return (
                true,
                "No pudimos verificar tu suscripción en este momento. Revisa tu conexión e inténtalo de nuevo."
            )
        }
    }

    func cancelSession() {
        guard let session = appState.activeSession else { return }
        stopTimer()
        isRunning = false
        appState.recordSessionCompletion(session, aborted: true)
        appState.updateActiveSession(nil)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                tick()
            }
    }

    private func tick() {
        guard let session = appState.activeSession else {
            stopTimer()
            isRunning = false
            return
        }

        let remaining = session.endsAt.timeIntervalSinceNow
        if remaining <= 0 {
            remainingTime = 0
            finishSession()
        } else {
            remainingTime = remaining
        }
    }

    private func finishSession() {
        stopTimer()
        guard let session = appState.activeSession else { return }
        isRunning = false
        remainingTime = 0
        showCelebration = true
        appState.recordSessionCompletion(session, aborted: false)
        appState.updateActiveSession(nil)
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
