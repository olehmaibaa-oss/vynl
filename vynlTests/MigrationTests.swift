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

    /// A store as the pre-TECH-1 build wrote it: unversioned Schema of the models.
    private func writeUnversionedV2Store() throws {
        let schema = Schema([Release.self, Track.self, MoodTag.self, Genre.self])
        let container = try ModelContainer(for: schema,
                                           configurations: [ModelConfiguration(schema: schema, url: storeURL)])
        let context = ModelContext(container)
        let genre = Genre(name: "Dub Techno")
        let release = Release(artist: "Sable Drift", title: "Undertow", genres: [genre], label: "Low Hum", year: 2019)
        release.cover = Data([0xFF, 0xD8, 0xFF])
        release.coverColor = "#E28B63"
        context.insert(release)
        let mood = MoodTag(name: "Hypnotic", group: .darkAndDriving)
        context.insert(mood)
        let track = Track(position: "A2", title: "Salt Line", bpm: 128, key: .k9A)
        track.release = release
        track.moods = [mood]
        context.insert(track)
        try context.save()
    }

    @Test func anExistingV2StoreOpensThroughThePlanWithItsData() throws {
        try writeUnversionedV2Store()

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

        let track = try #require(release.tracks.first)
        #expect(track.position == "A2")
        #expect(track.bpm == 128)
        #expect(track.key == .k9A)
        #expect(track.moods.map(\.name) == ["Hypnotic"])
    }

    @Test func thePlanStartsAtTheCurrentSchema() {
        #expect(VynlMigrationPlan.schemas.last == AppSchema.Current.self)
        #expect(AppSchema.Current.versionIdentifier == Schema.Version(2, 0, 0))
    }

    @Test func aNewStoreOpensThroughThePlan() throws {
        let container = try AppSchema.container(url: storeURL)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<Release>()) == 0)
    }
}
