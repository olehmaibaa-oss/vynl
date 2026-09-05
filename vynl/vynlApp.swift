//
//  vynlApp.swift
//  vynl
//

import SwiftUI
import SwiftData

@main
struct vynlApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Release.self,
            Track.self,
        ])
        let isUITesting = CommandLine.arguments.contains("-uitesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

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
