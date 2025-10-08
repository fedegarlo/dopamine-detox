import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
        .sheet(item: $appState.pendingIntervention) { intervention in
            DetoxInterventionWall(intervention: intervention) {
                appState.clearIntervention()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
