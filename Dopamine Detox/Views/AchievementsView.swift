import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Celebrations")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Earn gentle badges as you regain focus. No pressure — just acknowledgements of real progress.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 24)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(appState.achievements) { achievement in
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: achievement.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(achievement.isUnlocked ? .accent : .secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(achievement.title)
                                .font(.headline)
                            Text(achievement.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack {
                                if achievement.isUnlocked {
                                    Label("Unlocked", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Label("In progress", systemImage: "hourglass")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .frame(height: 180)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AppState())
}
