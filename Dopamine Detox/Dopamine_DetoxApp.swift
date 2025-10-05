//
//  Dopamine_DetoxApp.swift
//  Dopamine Detox
//
//  Created by Federico Garcia Lorca on 10/5/25.
//

import SwiftUI
import SwiftData

@main
struct Dopamine_DetoxApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
