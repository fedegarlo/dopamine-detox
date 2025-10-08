import Foundation

enum AppConfiguration {
    static let detoxInterventionScheme = "dopaminedetox"
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
