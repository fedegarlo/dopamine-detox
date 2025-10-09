import Foundation

enum AppConfiguration {
    /// Custom URL scheme declared in Info.plist under `URL types` so the system knows
    /// the Dopamine Detox app can be opened with links that start with
    /// `dopaminedetox://`.
    static let detoxInterventionScheme = "dopaminedetox"

    /// Host used for the intervention deep link. Combined with the scheme above it
    /// builds `dopaminedetox://intervention` which the app handles in
    /// `Dopamine_DetoxApp.handle(url:)` to present the calm wall.
    static let detoxInterventionHost = "intervention"

    static func makeDetoxInterventionURL(appName: String) -> URL? {
        var components = URLComponents()
        components.scheme = detoxInterventionScheme
        components.host = detoxInterventionHost

        var items: [URLQueryItem] = []

        let trimmedAppName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAppName.isEmpty {
            items.append(URLQueryItem(name: "app", value: trimmedAppName))
        }

        components.queryItems = items.isEmpty ? nil : items

        return components.url
    }
}
