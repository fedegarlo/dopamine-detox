import Foundation

enum DetoxDuration: TimeInterval, CaseIterable, Identifiable {
    case oneHour = 3_600
    case threeHours = 10_800
    case oneDay = 86_400
    case threeDays = 259_200
    case sevenDays = 604_800

    var id: TimeInterval { rawValue }

    var label: String {
        switch self {
        case .oneHour: "1h"
        case .threeHours: "3h"
        case .oneDay: "1d"
        case .threeDays: "3d"
        case .sevenDays: "7d"
        }
    }

    var description: String {
        switch self {
        case .oneHour: "Quick reset to clear your mind."
        case .threeHours: "Deep focus block for meaningful work."
        case .oneDay: "Full day cleanse from digital noise."
        case .threeDays: "Recalibrate your habits over a long weekend."
        case .sevenDays: "Transformational break to rebuild focus."
        }
    }
}

struct DetoxSession: Identifiable {
    let id = UUID()
    let startedAt: Date
    let duration: DetoxDuration
    var completedAt: Date?
    var aborted: Bool = false

    var endsAt: Date {
        startedAt.addingTimeInterval(duration.rawValue)
    }

    var isCompleted: Bool {
        completedAt != nil && !aborted
    }

    func progress(at referenceDate: Date = .now) -> Double {
        guard referenceDate >= startedAt else { return 0 }
        let elapsed = referenceDate.timeIntervalSince(startedAt)
        let progress = min(max(elapsed / duration.rawValue, 0), 1)
        return progress
    }
}
