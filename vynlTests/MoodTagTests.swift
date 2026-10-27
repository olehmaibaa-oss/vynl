//
//  MoodTagTests.swift
//  vynlTests
//
//  E2-S1 (SCRUM-20): MoodTag model, many-to-many with Track, seeded vocabulary.
//  Each test gets its own in-memory store and its own UserDefaults suite, so the
//  "seeded" flag never leaks between tests or from the host app.
//

import Foundation
import Testing
import SwiftData
@testable import vynl

@MainActor
struct MoodTagTests {

    private let container: ModelContainer
    private let flags: UserDefaults
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: AppSchema.schema,
            configurations: [ModelConfiguration(schema: AppSchema.schema, isStoredInMemoryOnly: true)])
        flags = UserDefaults(suiteName: "MoodTagTests-\(UUID().uuidString)")!
    }

    private func moodNames() throws -> [String] {
        try context.fetch(FetchDescriptor<MoodTag>()).map(\.name).sorted()
    }

    private func mood(_ name: String) throws -> MoodTag {
        try #require(try context.fetch(FetchDescriptor<MoodTag>()).first { $0.name == name })
    }

    private func track(_ position: String, moods: [MoodTag] = []) -> Track {
        let track = Track(position: position, title: "Track \(position)")
        context.insert(track)
        track.moods = moods
        return track
    }

    // MARK: - Seeding

    @Test func freshStoreGetsTheDefaultVocabulary() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        #expect(try moodNames() == MoodVocabulary.defaults.sorted())
    }

    @Test func seedingTwiceCreatesNoDuplicates() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        #expect(try moodNames().count == MoodVocabulary.defaults.count)
    }

    @Test func aDeletedDefaultIsNotResurrected() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        context.delete(try mood("industrial"))
        try context.save()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try !moodNames().contains("industrial"))
    }

    @Test func deletingEveryMoodDoesNotReseed() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        try context.delete(model: MoodTag.self)
        try context.save()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try moodNames().isEmpty)
    }

    // MARK: - Names

    @Test func namesAreStoredTrimmedAndLowercased() {
        #expect(MoodTag(name: "  Hypnotic \n").name == "hypnotic")
    }

    @Test func nameTakenIsCaseAndWhitespaceInsensitive() throws {
        context.insert(MoodTag(name: "hypnotic"))
        #expect(try MoodVocabulary.isNameTaken("Hypnotic ", in: context))
        #expect(try !MoodVocabulary.isNameTaken("tribal", in: context))
    }

    @Test func aMoodDoesNotCollideWithItselfWhenRenamed() throws {
        let dubby = MoodTag(name: "dubby")
        context.insert(dubby)
        #expect(try !MoodVocabulary.isNameTaken("Dubby", in: context, excluding: dubby))
    }

    // MARK: - Relationships

    @Test func trackAndMoodAreManyToMany() throws {
        let deep = MoodTag(name: "deep"), dark = MoodTag(name: "dark")
        context.insert(deep); context.insert(dark)
        let a1 = track("A1", moods: [deep, dark])
        let a2 = track("A2", moods: [deep])
        try context.save()

        #expect(Set(a1.moods.map(\.name)) == ["deep", "dark"])
        #expect(a2.moods.map(\.name) == ["deep"])
        #expect(Set(deep.tracks.map(\.position)) == ["A1", "A2"])
        #expect(dark.tracks.map(\.position) == ["A1"])
    }

    @Test func deletingAMoodKeepsTheTrack() throws {
        let dark = MoodTag(name: "dark")
        context.insert(dark)
        let a1 = track("A1", moods: [dark])
        try context.save()

        context.delete(dark)
        try context.save()

        let tracks = try context.fetch(FetchDescriptor<Track>())
        #expect(tracks.map(\.position) == ["A1"])
        #expect(a1.moods.isEmpty)
    }

    @Test func deletingATrackKeepsTheMood() throws {
        let dark = MoodTag(name: "dark")
        context.insert(dark)
        let a1 = track("A1", moods: [dark])
        try context.save()

        context.delete(a1)
        try context.save()

        #expect(try moodNames() == ["dark"])
        #expect(dark.tracks.isEmpty)
    }
}
