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
        let modelConfiguration: ModelConfiguration

        if isUITesting {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // Tests start in grid and artist A–Z, unless a relaunch checks that the
            // mode and sort are remembered.
            if !CommandLine.arguments.contains("-uitesting-keepMode") {
                UserDefaults.standard.set(CollectionMode.grid.rawValue, forKey: CollectionMode.storageKey)
                UserDefaults.standard.set(RecordSort.default.rawValue, forKey: RecordSort.storageKey)
            }
        } else {
            // A pre-v2 store (simulator-era builds) is reset; v2+ migrates (TECH-1).
            StoreReset.resetIfSchemaChanged(storeURL: AppSchema.storeURL, flags: .standard,
                                            currentVersion: AppSchema.version)
            try? FileManager.default.createDirectory(at: URL.applicationSupportDirectory,
                                                     withIntermediateDirectories: true)
            modelConfiguration = ModelConfiguration(schema: schema, url: AppSchema.storeURL)
        }

        do {
            // On disk: through the migration plan, so a schema change never wipes a
            // real collection (TECH-1, SCRUM-43).
            let container = isUITesting
                ? try ModelContainer(for: schema, configurations: [modelConfiguration])
                : try ModelContainer(for: schema, migrationPlan: VynlMigrationPlan.self,
                                     configurations: [modelConfiguration])
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
