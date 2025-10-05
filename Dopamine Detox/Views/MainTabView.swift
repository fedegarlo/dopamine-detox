import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DetoxTimerView(appState: appState)
                .tabItem {
                    Label("Detox", systemImage: "hourglass")
                }

            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            JournalView(appState: appState)
                .tabItem {
                    Label("Journal", systemImage: "square.and.pencil")
                }

            AICoachView()
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }

            AchievementsView()
                .tabItem {
                    Label("Wins", systemImage: "rosette")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
