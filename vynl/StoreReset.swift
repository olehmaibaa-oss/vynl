//
//  StoreReset.swift
//  vynl
//
//  Tech Spec §4: until the app held a real collection, a schema change reset
//  the store instead of migrating it. DR-2 (SCRUM-31) was the first such change
//  and, since TECH-1 (SCRUM-43), the last: `AppSchema.version` is frozen at 2,
//  so only pre-v2 stores are reset; v2+ goes through `VynlMigrationPlan`.
//
//  The reset is keyed on an explicit schema version, not on "the container
//  failed to open": a failure for any other reason still crashes loudly, so a
//  real migration bug can't hide behind it.
//
//  Kept for simulator-era v1 stores. Never bump `currentVersion` again: a
//  model change is a new SchemaV<n> + migration stage (AppSchema.swift).
//

import Foundation
import os

enum StoreReset {

    static let versionKey = "storeSchemaVersion"

    private static let log = Logger(subsystem: "dev.vynl", category: "store")

    /// Deletes the store when it was written by another schema version, then
    /// records `currentVersion`. Returns whether it deleted anything.
    ///
    /// A store with no recorded version predates versioning, so it is v1.
    @discardableResult
    static func resetIfSchemaChanged(storeURL: URL, flags: UserDefaults, currentVersion: Int,
                                     fileManager: FileManager = .default) -> Bool {
        let stored = flags.object(forKey: versionKey) as? Int ?? 1
        defer { flags.set(currentVersion, forKey: versionKey) }

        guard stored != currentVersion, fileManager.fileExists(atPath: storeURL.path) else {
            return false
        }

        log.notice("Schema v\(stored) → v\(currentVersion): resetting the store at \(storeURL.path, privacy: .public)")
        for url in files(of: storeURL) where fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                log.error("Could not delete \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        // A new store needs the vocabulary again.
        flags.removeObject(forKey: MoodVocabulary.seededFlag)
        return true
    }

    /// The SQLite store, its journal files, and the folder holding external-storage
    /// blobs (covers).
    static func files(of storeURL: URL) -> [URL] {
        let dir = storeURL.deletingLastPathComponent()
        let base = storeURL.deletingPathExtension().lastPathComponent
        return [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
            dir.appending(path: ".\(base)_SUPPORT"),
            dir.appending(path: "\(base)_SUPPORT"),
        ]
    }
}
