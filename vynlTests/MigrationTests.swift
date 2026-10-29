//
//  MigrationTests.swift
//  vynlTests
//
//  TECH-1 (SCRUM-43): a store written before the migration plan existed (plain
//  Schema of the same models, as the PO's phone has today) opens through the
//  plan with everything in it. Every future SchemaV<n> adds a test here that
//  writes a store with the previous version and opens it with the plan.
//

import Foundation
import SwiftData
import Testing
@testable import vynl

@MainActor
struct MigrationTests {

    private let dir: URL
    private let storeURL: URL

    init() throws {
        dir = FileManager.default.temporaryDirectory.appending(path: "MigrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appending(path: "default.store")
    }

    /// A v2 store as the phone has it: the frozen v2 models, written either
    /// unversioned (pre-TECH-1 builds) or as SchemaV2 (TECH-1 builds).
    private func writeV2Store(versioned: Bool) throws {
        let schema = versioned ? Schema(versionedSchema: SchemaV2.self) : Schema(SchemaV2.models)
        let container = try ModelContainer(for: schema,
                                           configurations: [ModelConfiguration(schema: schema, url: storeURL)])
        let context = ModelContext(container)
        let genre = SchemaV2.Genre(name: "Dub Techno")
        let release = SchemaV2.Release(artist: "Sable Drift", title: "Undertow", genres: [genre],
                                       label: "Low Hum", year: 2019)
        release.cover = Data([0xFF, 0xD8, 0xFF])
        release.coverColor = "#E28B63"
        context.insert(release)
        let mood = SchemaV2.MoodTag(name: "Hypnotic", groupName: MoodGroup.darkAndDriving.rawValue)
        context.insert(mood)
        let track = SchemaV2.Track(position: "A2", title: "Salt Line", bpm: 128, keyCode: "9A")
        track.release = release
        track.moods = [mood]
        context.insert(track)
        try context.save()
    }

    private func expectMigratedData() throws {
        let container = try AppSchema.container(url: storeURL)
        let context = ModelContext(container)

        let releases = try context.fetch(FetchDescriptor<Release>())
        #expect(releases.count == 1)
        let release = try #require(releases.first)
        #expect(release.artist == "Sable Drift")
        #expect(release.label == "Low Hum")
        #expect(release.year == 2019)
        #expect(release.genreNames == ["Dub Techno"])
        #expect(release.cover == Data([0xFF, 0xD8, 0xFF]))
        #expect(release.coverColor == "#E28B63")
        #expect(release.labelImage == nil)

        let track = try #require(release.tracks.first)
        #expect(track.position == "A2")
        #expect(track.bpm == 128)
        #expect(track.key == .k9A)
        #expect(track.moods.map(\.name) == ["Hypnotic"])

        // The new attribute works after the migration.
        release.labelImage = Data([1, 2, 3])
        try context.save()
        #expect(try ModelContext(container).fetch(FetchDescriptor<Release>()).first?.labelImage == Data([1, 2, 3]))
    }

    @Test func anUnversionedV2StoreMigratesToV3() throws {
        try writeV2Store(versioned: false)
        try expectMigratedData()
    }

    @Test func aVersionedV2StoreMigratesToV3() throws {
        try writeV2Store(versioned: true)
        try expectMigratedData()
    }

    @Test func thePlanStartsAtTheCurrentSchema() {
        #expect(VynlMigrationPlan.schemas.last == AppSchema.Current.self)
        #expect(AppSchema.Current.versionIdentifier == Schema.Version(3, 0, 0))
        #expect(VynlMigrationPlan.stages.count == VynlMigrationPlan.schemas.count - 1)
    }

    @Test func aNewStoreOpensThroughThePlan() throws {
        let container = try AppSchema.container(url: storeURL)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<Release>()) == 0)
    }
}
