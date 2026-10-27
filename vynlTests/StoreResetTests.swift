//
//  StoreResetTests.swift
//  vynlTests
//
//  DR-2 (SCRUM-31), scenario "The store resets on the schema change". Runs on a
//  real on-disk store in a temp folder, never the app's own.
//

import Foundation
import Testing
import SwiftData
@testable import vynl

@MainActor
struct StoreResetTests {

    private let dir: URL
    private let storeURL: URL
    private let flags: UserDefaults

    init() throws {
        dir = FileManager.default.temporaryDirectory.appending(path: "StoreResetTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appending(path: "default.store")
        flags = UserDefaults(suiteName: "StoreResetTests-\(UUID().uuidString)")!
    }

    private func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    /// A v1-era store as far as the reset can tell: files on disk, no recorded version,
    /// and a "seeded" flag from the old vocabulary. The bytes are not a valid v2 store.
    private func writeOldStore() throws {
        try Data("v1 sqlite".utf8).write(to: storeURL)
        try Data().write(to: URL(fileURLWithPath: storeURL.path + "-wal"))
        try Data().write(to: URL(fileURLWithPath: storeURL.path + "-shm"))
        try FileManager.default.createDirectory(at: dir.appending(path: ".default_SUPPORT"),
                                                withIntermediateDirectories: true)
        flags.set(true, forKey: MoodVocabulary.seededFlag)
    }

    @Test func anUnversionedStoreIsResetAndTheAppStartsClean() throws {
        try writeOldStore()

        let didReset = StoreReset.resetIfSchemaChanged(storeURL: storeURL, flags: flags, currentVersion: 2)

        #expect(didReset)
        #expect(!exists(storeURL))
        #expect(!exists(URL(fileURLWithPath: storeURL.path + "-wal")))
        #expect(!exists(dir.appending(path: ".default_SUPPORT")))
        #expect(flags.integer(forKey: StoreReset.versionKey) == 2)

        // Then the launch path: open v2 on that URL and seed. No crash, empty
        // collection, the seeded vocabulary back.
        let container = try ModelContainer(
            for: AppSchema.schema, configurations: [ModelConfiguration(schema: AppSchema.schema, url: storeURL)])
        let context = ModelContext(container)
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try context.fetchCount(FetchDescriptor<Release>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MoodTag>()) == MoodVocabulary.defaults.count)
    }

    @Test func withoutTheResetTheOldStoreDoesNotOpen() throws {
        // Proves the reset is what makes the launch work, not a lenient loader.
        try writeOldStore()
        #expect(throws: (any Error).self) {
            _ = try ModelContainer(
                for: AppSchema.schema, configurations: [ModelConfiguration(schema: AppSchema.schema, url: storeURL)])
        }
    }

    @Test func aStoreOnTheCurrentVersionIsKept() throws {
        try writeOldStore()
        flags.set(2, forKey: StoreReset.versionKey)

        #expect(!StoreReset.resetIfSchemaChanged(storeURL: storeURL, flags: flags, currentVersion: 2))
        #expect(exists(storeURL))
        #expect(flags.bool(forKey: MoodVocabulary.seededFlag))
    }

    @Test func aFreshInstallHasNothingToResetAndRecordsTheVersion() {
        #expect(!StoreReset.resetIfSchemaChanged(storeURL: storeURL, flags: flags, currentVersion: 2))
        #expect(flags.integer(forKey: StoreReset.versionKey) == 2)
    }

    @Test func theResetHappensOnce() throws {
        try writeOldStore()
        #expect(StoreReset.resetIfSchemaChanged(storeURL: storeURL, flags: flags, currentVersion: 2))
        try Data("v2 store".utf8).write(to: storeURL)
        #expect(!StoreReset.resetIfSchemaChanged(storeURL: storeURL, flags: flags, currentVersion: 2))
        #expect(exists(storeURL))
    }
}
