//
//  AppSchema.swift
//  vynl
//
//  TECH-1 (SCRUM-43): the schema is versioned and opened through a migration
//  plan, because the app now holds real collections (Tech Spec §4). Rules for
//  every model change from here on:
//
//  1. Freeze the current models: copy them into `SchemaV<n>` as nested types
//     (a VersionedSchema must keep describing the old shape forever).
//  2. Add `SchemaV<n+1>` with the live models, append it to
//     `VynlMigrationPlan.schemas`, and add a stage (`.lightweight` for added
//     optional fields / new entities, `.custom` when data has to move).
//  3. Point `AppSchema.current` at the new version.
//  4. Add a migration test that writes a store with the old schema and opens
//     it with the plan (see MigrationTests).
//
//  Stores from before v2 (simulator-era builds) are still reset by StoreReset;
//  a v2+ store is never reset again.
//

import Foundation
import SwiftData

/// Schema v3: COV-1 (SCRUM-57) adds `Release.labelImage`. The live models.
/// v2 is frozen in SchemaV2.swift.
enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Release.self, Track.self, MoodTag.self, Genre.self]
    }
}

/// Every schema the app has shipped with real data, oldest first, and how to
/// get from one to the next.
enum VynlMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV2.self, SchemaV3.self] }

    /// v2 → v3: one new optional attribute (labelImage), so lightweight.
    static let v2toV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)

    static var stages: [MigrationStage] { [v2toV3] }
}

/// Every persisted model, in one place, so the app and the unit tests can't
/// drift onto different schemas.
enum AppSchema {
    /// The live versioned schema.
    typealias Current = SchemaV3

    /// The last schema version that resets instead of migrating (StoreReset).
    /// Frozen at 2: newer versions go through `VynlMigrationPlan`.
    static let version = 2

    static var models: [any PersistentModel.Type] { Current.models }

    static var schema: Schema { Schema(versionedSchema: Current.self) }

    /// Where the on-device store lives (SwiftData's default location, made explicit
    /// so StoreReset and the container agree on it).
    static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    /// The on-disk container, opened through the migration plan.
    static func container(url: URL) throws -> ModelContainer {
        try ModelContainer(for: schema, migrationPlan: VynlMigrationPlan.self,
                           configurations: [ModelConfiguration(schema: schema, url: url)])
    }
}
