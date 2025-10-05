import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var dopamineIndex: Int
    @Published var hasCompletedOnboarding: Bool
    @Published var streak: Int
    @Published var totalFocusMinutes: Int
    @Published var activeSession: DetoxSession?
    @Published var pastSessions: [DetoxSession]
    @Published var completedSessionCount: Int
    @Published var journalEntries: [JournalEntry]
    @Published var achievements: [Achievement]

    private enum StorageKeys: String {
        case dopamineIndex
        case onboardingCompleted
        case streak
        case totalFocusMinutes
        case completedSessions
        case activeSession
        case pastSessions
    }

    init(userDefaults: UserDefaults = .standard) {
        let defaults = userDefaults
        let storedIndex = defaults.object(forKey: StorageKeys.dopamineIndex.rawValue) as? Int ?? 50
        let storedOnboarding = defaults.object(forKey: StorageKeys.onboardingCompleted.rawValue) as? Bool ?? false
        let storedStreak = defaults.object(forKey: StorageKeys.streak.rawValue) as? Int ?? 0
        let storedMinutes = defaults.object(forKey: StorageKeys.totalFocusMinutes.rawValue) as? Int ?? 0

        dopamineIndex = storedIndex
        hasCompletedOnboarding = storedOnboarding
        streak = storedStreak
        totalFocusMinutes = storedMinutes
        activeSession = nil
        if let storedSessionsData = defaults.data(forKey: StorageKeys.pastSessions.rawValue),
           let storedSessions = try? JSONDecoder().decode([DetoxSession].self, from: storedSessionsData) {
            pastSessions = storedSessions
        } else {
            pastSessions = []
        }
        completedSessionCount = defaults.object(forKey: StorageKeys.completedSessions.rawValue) as? Int ?? 0
        journalEntries = JournalEntry.sampleData
        achievements = Achievement.defaults()
        updateAchievements()

        // Restore persisted active session if any
        if let data = defaults.data(forKey: StorageKeys.activeSession.rawValue),
           let session = try? JSONDecoder().decode(DetoxSession.self, from: data) {
            if session.endsAt > Date() {
                activeSession = session
            } else {
                // Session finished while app was closed; count it as completed
                activeSession = nil
                recordSessionCompletion(session, aborted: false, userDefaults: defaults)
                defaults.removeObject(forKey: StorageKeys.activeSession.rawValue)
            }
        }
    }

    func markOnboardingComplete(score: Int, userDefaults: UserDefaults = .standard) {
        dopamineIndex = score
        hasCompletedOnboarding = true
        userDefaults.set(score, forKey: StorageKeys.dopamineIndex.rawValue)
        userDefaults.set(true, forKey: StorageKeys.onboardingCompleted.rawValue)
    }

    func updateActiveSession(_ session: DetoxSession?, userDefaults: UserDefaults = .standard) {
        activeSession = session
        if let session {
            if let data = try? JSONEncoder().encode(session) {
                userDefaults.set(data, forKey: StorageKeys.activeSession.rawValue)
            }
        } else {
            userDefaults.removeObject(forKey: StorageKeys.activeSession.rawValue)
        }
    }

    func recordSessionCompletion(_ session: DetoxSession, aborted: Bool, userDefaults: UserDefaults = .standard) {
        var finishedSession = session
        finishedSession.completedAt = aborted ? nil : Date()
        finishedSession.aborted = aborted
        pastSessions.append(finishedSession)

        if aborted {
            streak = 0
            userDefaults.set(streak, forKey: StorageKeys.streak.rawValue)
        } else {
            streak += 1
            totalFocusMinutes += Int(session.duration.rawValue / 60)
            completedSessionCount += 1
            userDefaults.set(streak, forKey: StorageKeys.streak.rawValue)
            userDefaults.set(totalFocusMinutes, forKey: StorageKeys.totalFocusMinutes.rawValue)
            userDefaults.set(completedSessionCount, forKey: StorageKeys.completedSessions.rawValue)
        }

        persistPastSessions(using: userDefaults)
        updateAchievements()
    }

    func addJournalEntry(_ entry: JournalEntry) {
        journalEntries.insert(entry, at: 0)
    }

    private func persistPastSessions(using userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(pastSessions) else { return }
        userDefaults.set(data, forKey: StorageKeys.pastSessions.rawValue)
    }

    private func updateAchievements() {
        let totalHours = totalFocusMinutes / 60
        achievements = achievements.map { achievement in
            var updated = achievement
            switch achievement.milestone {
            case .hours(let targetHours):
                updated.isUnlocked = totalHours >= targetHours
            case .streak(let targetStreak):
                updated.isUnlocked = streak >= targetStreak
            }
            return updated
        }
    }
}
