//
//  CascadeDeleteTests.swift
//  vynlTests
//
//  Cascade delete on Release → Track is only observable at the model level in E1:
//  orphaned tracks (release == nil) render nowhere in the UI, so an Appium test
//  can't tell a working cascade from a broken one. These tests can.
//

import Testing
import SwiftData
@testable import vynl

@MainActor
struct CascadeDeleteTests {

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        let schema = Schema([Release.self, Track.self])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    }

    private func release(_ artist: String, tracks positions: [String]) -> Release {
        let release = Release(artist: artist, title: "Title", genre: "Techno")
        context.insert(release)
        for position in positions {
            context.insert(Track(position: position, title: "Track \(position)", release: release))
        }
        return release
    }

    private func trackCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Track>())
    }

    @Test func deletingAReleaseDeletesItsTracks() throws {
        let surgeon = release("Surgeon", tracks: ["A1", "A2"])
        try context.save()
        #expect(try trackCount() == 2)

        context.delete(surgeon)
        try context.save()

        #expect(try trackCount() == 0)
    }

    @Test func deletingAReleaseLeavesOtherReleasesTracksAlone() throws {
        let surgeon = release("Surgeon", tracks: ["A1", "A2"])
        _ = release("Regis", tracks: ["B1"])
        try context.save()

        context.delete(surgeon)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Track>())
        #expect(remaining.map(\.position) == ["B1"])
        #expect(remaining.first?.release?.artist == "Regis")
    }
}
