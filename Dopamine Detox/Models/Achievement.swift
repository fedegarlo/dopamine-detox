import Foundation

struct Achievement: Identifiable {
    enum MilestoneType {
        case hours(Int)
        case streak(Int)
    }

    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let milestone: MilestoneType
    var isUnlocked: Bool = false

    static func defaults() -> [Achievement] {
        [
            Achievement(title: "First Reset", description: "Complete a 1 hour detox session.", systemImage: "sparkles", milestone: .hours(1)),
            Achievement(title: "Deep Focus", description: "Log 10 detox hours in total.", systemImage: "brain.head.profile", milestone: .hours(10)),
            Achievement(title: "Consistency", description: "Maintain a 7 day streak.", systemImage: "flame", milestone: .streak(7))
        ]
    }
}
