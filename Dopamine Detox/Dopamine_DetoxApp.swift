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
                    handle(url: url)
                }
        }
    }
}

private extension Dopamine_DetoxApp {
    func handle(url: URL) {
        guard url.scheme?.lowercased() == AppConfiguration.detoxInterventionScheme else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = components?.host?.lowercased()

        guard host == AppConfiguration.detoxInterventionHost else { return }

        let appName = components?.queryItems?.first(where: { $0.name == "app" })?.value ?? ""
        let redirectValue = components?.queryItems?.first(where: { $0.name == "redirect" })?.value
        let redirectURL: URL?
        if let redirectValue, !redirectValue.isEmpty {
            let decoded = redirectValue.removingPercentEncoding ?? redirectValue
            redirectURL = URL(string: decoded)
        } else {
            redirectURL = nil
        }

        Task { @MainActor in
            appState.presentIntervention(appName: appName, redirectURL: redirectURL)
        }
    }
}
