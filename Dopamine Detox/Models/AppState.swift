import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var dopamineIndex: Int
    @Published var hasCompletedOnboarding: Bool
    @Published var streak: Int
    @Published var totalFocusMinutes: Int
    @Published var activeSession: DetoxSession?
    @Published var pastSessions: [DetoxSession]
    @Published var journalEntries: [JournalEntry]
    @Published var achievements: [Achievement]

    private enum StorageKeys: String {
        case dopamineIndex
        case onboardingCompleted
        case streak
        case totalFocusMinutes
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
        pastSessions = []
        journalEntries = JournalEntry.sampleData
        achievements = Achievement.defaults()
    }

    func markOnboardingComplete(score: Int, userDefaults: UserDefaults = .standard) {
        dopamineIndex = score
        hasCompletedOnboarding = true
        userDefaults.set(score, forKey: StorageKeys.dopamineIndex.rawValue)
        userDefaults.set(true, forKey: StorageKeys.onboardingCompleted.rawValue)
    }

    func updateActiveSession(_ session: DetoxSession?) {
        activeSession = session
    }

    func recordSessionCompletion(_ session: DetoxSession, aborted: Bool, userDefaults: UserDefaults = .standard) {
        var finishedSession = session
        finishedSession.completedAt = aborted ? nil : Date()
        finishedSession.aborted = aborted
        pastSessions.append(finishedSession)

        if aborted {
            streak = 0
        } else {
            streak += 1
            totalFocusMinutes += Int(session.duration.rawValue / 60)
            userDefaults.set(streak, forKey: StorageKeys.streak.rawValue)
            userDefaults.set(totalFocusMinutes, forKey: StorageKeys.totalFocusMinutes.rawValue)
        }

        updateAchievements()
    }

    func addJournalEntry(_ entry: JournalEntry) {
        journalEntries.insert(entry, at: 0)
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
