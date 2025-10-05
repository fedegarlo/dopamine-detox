import Foundation
import Combine

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
        } else {
            selectedDuration = .oneHour
            remainingTime = selectedDuration.rawValue
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
        guard remainingTime > 1 else {
            finishSession()
            return
        }
        remainingTime -= 1
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
