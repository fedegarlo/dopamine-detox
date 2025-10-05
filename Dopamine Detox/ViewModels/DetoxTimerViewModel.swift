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
    private let focusAutomationManager: FocusAutomationManager

    init(appState: AppState, focusAutomationManager: FocusAutomationManager = .shared) {
        self.appState = appState
        self.focusAutomationManager = focusAutomationManager
        if let active = appState.activeSession {
            selectedDuration = active.duration
            let remaining = active.endsAt.timeIntervalSinceNow
            remainingTime = max(remaining, 0)
            isRunning = remaining > 0
            
            // Resume timer and Focus if session is still active
            if isRunning {
                startTimer()
                focusAutomationManager.beginDetoxSession()
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

    func startSession() {
        let session = DetoxSession(startedAt: Date(), duration: selectedDuration)
        appState.updateActiveSession(session)
        remainingTime = selectedDuration.rawValue
        isRunning = true
        showCelebration = false
        startTimer()
        focusAutomationManager.beginDetoxSession()
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
        focusAutomationManager.endDetoxSession()
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
        focusAutomationManager.endDetoxSession()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
