import AppIntents
import Foundation

@available(iOS 17.0, *)
struct ShowCalmWallIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostrar muro de calma"
    static var description = IntentDescription("Abre Dotox para mostrar el muro de calma antes de continuar con otra app.")
    static var openAppWhenRun: Bool = true

    @Dependency(\.openURL) private var openURL

    @Parameter(title: "Nombre de la app", default: "Instagram")
    var appName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Mostrar muro de calma antes de abrir \(\.$appName)")
    }

    func perform() async throws -> some IntentResult {
        guard let url = AppConfiguration.makeDetoxInterventionURL(appName: appName) else {
            throw ShowCalmWallIntentError.invalidConfiguration
        }

        try await openURL(url)
        return .result()
    }
}

@available(iOS 17.0, *)
struct DotoxAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCalmWallIntent(),
            phrases: [
                "Mostrar muro de calma en \(.appName)",
                "Abrir Dotox antes de usar \(.appName)",
                "Quiero calma antes de usar \(.appName)"
            ],
            shortTitle: "Muro de calma",
            systemImageName: "brain.head.profile"
        )
    }
}

@available(iOS 17.0, *)
enum ShowCalmWallIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidConfiguration

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidConfiguration:
            return "No se pudo crear el enlace del muro de calma. Revisa los datos introducidos."
        }
    }
}
