import RevenueCat
import SwiftUI

@main
struct Dopamine_DetoxApp: App {
    @StateObject private var appState = AppState()

    init() {
        Purchases.configure(withAPIKey: "appl_uhABinYKmAgGdqElwYoFRqkBTon")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
