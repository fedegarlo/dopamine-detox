import Foundation
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
                .onOpenURL { url in
                    Task { @MainActor in
                        handle(url: url)
                    }
                }
        }
    }
}

@MainActor
private extension Dopamine_DetoxApp {
    func handle(url: URL) {
        guard url.scheme?.lowercased() == AppConfiguration.detoxInterventionScheme else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        guard components.host?.lowercased() == AppConfiguration.detoxInterventionHost else { return }

        let appName = components.queryItems?.first(where: { $0.name == "app" })?.value ?? ""

        let redirectURL: URL?
        if let redirectValue = components.queryItems?.first(where: { $0.name == "redirect" })?.value,
           !redirectValue.isEmpty {
            let decoded = redirectValue.removingPercentEncoding ?? redirectValue
            redirectURL = URL(string: decoded)
        } else {
            redirectURL = nil
        }

        appState.presentIntervention(appName: appName, redirectURL: redirectURL)
    }
}
