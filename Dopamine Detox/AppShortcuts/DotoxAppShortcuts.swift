import AppIntents
import Foundation
import SwiftUI

struct ShowCalmWallIntent: AppIntent {
    static var title: LocalizedStringResource = "Mostrar muro de calma"
    static var description = IntentDescription("Activa el muro de calma antes de usar otra app")
    
    @Parameter(title: "App", default: "Instagram")
    var appName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Mostrar muro de calma antes de abrir \(\.$appName)")
    }
    
    func perform() async throws -> some IntentResult {
        // La URL se manejará en el AppDelegate/SceneDelegate cuando la app se abra
        return .result()
    }
}

struct DotoxShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCalmWallIntent(),
            phrases: ["Muéstrame el muro de calma antes de abrir ${applicationName}"],
            shortTitle: "Muro de calma",
            systemImageName: "brain.head.profile"
        )
    }
}
