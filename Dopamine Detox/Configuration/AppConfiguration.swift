import Foundation

enum AppConfiguration {
    static let detoxInterventionScheme = "dopaminedetox"
    static let detoxInterventionHost = "intervention"

    static func makeDetoxInterventionURL(appName: String, redirectTarget: String) -> URL? {
        var components = URLComponents()
        components.scheme = detoxInterventionScheme
        components.host = detoxInterventionHost

        var items: [URLQueryItem] = []

        let trimmedAppName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAppName.isEmpty {
            items.append(URLQueryItem(name: "app", value: trimmedAppName))
        }

        let trimmedRedirectTarget = redirectTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRedirectTarget.isEmpty {
            items.append(URLQueryItem(name: "redirect", value: trimmedRedirectTarget))
        }

        components.queryItems = items.isEmpty ? nil : items

        return components.url
    }
}
