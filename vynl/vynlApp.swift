//
//  vynlApp.swift
//  vynl
//

import SwiftUI
import SwiftData

@main
struct vynlApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = AppSchema.schema
        let isUITesting = CommandLine.arguments.contains("-uitesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // An in-memory UI-test store is new on every launch, so its "seeded"
            // flag must be too — otherwise a persisted flag from an earlier run
            // would leave the fresh store without the default moods.
            let flags = isUITesting ? UserDefaults(suiteName: "uitesting-\(UUID().uuidString)")! : .standard
            try MoodVocabulary.seedIfNeeded(in: ModelContext(container), flags: flags)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Dark only (DR-1): forced once here, so sheets and alerts follow.
                .preferredColorScheme(.dark)
                .tint(Palette.ink)
        }
        .modelContainer(sharedModelContainer)
    }
}
