//
//  MoodTagTests.swift
//  vynlTests
//
//  E2-S1 (SCRUM-20), updated in DR-2 (SCRUM-31): MoodTag model, many-to-many with Track, seeded vocabulary.
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
        #expect(try moodNames() == MoodVocabulary.defaults.map(\.name).sorted())
    }

    @Test func seedingTwiceCreatesNoDuplicates() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        #expect(try moodNames().count == MoodVocabulary.defaults.count)
    }

    @Test func aDeletedDefaultIsNotResurrected() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        context.delete(try mood("Industrial"))
        try context.save()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try !moodNames().contains("Industrial"))
    }

    @Test func deletingEveryMoodDoesNotReseed() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        try context.delete(model: MoodTag.self)
        try context.save()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try moodNames().isEmpty)
    }

    // MARK: - Names

    // DR-2: v1 lowercased names; v2 keeps them as typed, only trimmed.
    @Test func namesAreStoredAsTypedAndTrimmed() {
        #expect(MoodTag(name: "  Spacey / Cosmic \n", group: .atmospheric).name == "Spacey / Cosmic")
    }

    @Test func nameTakenIgnoresCaseBothWays() throws {
        context.insert(MoodTag(name: "Hypnotic", group: .darkAndDriving))
        #expect(try MoodVocabulary.isNameTaken("hypnotic", in: context))
        #expect(try MoodVocabulary.isNameTaken("HYPNOTIC", in: context))
    }

    // MARK: - Groups

    @Test func aMoodKeepsItsGroup() throws {
        let acid = MoodTag(name: "Acid", group: .groovy)
        context.insert(acid)
        try context.save()
        let fetched = try #require(try context.fetch(FetchDescriptor<MoodTag>()).first)
        #expect(fetched.group == .groovy)
        #expect(fetched.groupName == "Groovy")
    }

    // MARK: - E2-S5: the PRD vocabulary

    @Test func theSeededVocabularyIsThePRDs30() throws {
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        let moods = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(moods.count == 30)
        #expect(try mood("Industrial").group == .darkAndDriving)
        #expect(try mood("Dubby").group == .dub)
        #expect(try mood("Spacey / Cosmic").group == .atmospheric)
        let perGroup = MoodGroup.allCases.map { g in moods.filter { $0.group == g }.count }
        #expect(perGroup == [9, 6, 7, 7, 1])
    }

    /// A store seeded with the 8 lowercase v1 moods, one of them tagging a track,
    /// plus a mood the person made themselves.
    private func seedV1() throws -> Track {
        for name in ["hypnotic", "driving", "dark", "minimal", "industrial", "atmospheric", "deep", "dubby"] {
            context.insert(MoodTag(name: name, group: .darkAndDriving))
        }
        context.insert(MoodTag(name: "Acid", group: .darkAndDriving))
        let a1 = track("A1", moods: [try mood("dubby")])
        try context.save()
        flags.set(true, forKey: MoodVocabulary.seededFlag)   // v1 never wrote a seed version
        return a1
    }

    @Test func aV1VocabularyIsUpgradedInPlace() throws {
        let a1 = try seedV1()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        let moods = try context.fetch(FetchDescriptor<MoodTag>())
        #expect(moods.count == 31)                                   // 30 PRD + Acid
        #expect(!moods.contains { $0.name == "dubby" })              // respelled, not duplicated
        #expect(try mood("Dubby").group == .dub)
        #expect(a1.moods.map(\.name) == ["Dubby"])                   // the tag survived the respelling
        #expect(try mood("Acid").group == .darkAndDriving)           // the person's own mood untouched
        #expect(flags.integer(forKey: MoodVocabulary.seedVersionKey) == MoodVocabulary.seedVersion)
    }

    @Test func theUpgradeRunsOnce() throws {
        _ = try seedV1()
        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)
        context.delete(try mood("Raw"))
        try context.save()

        try MoodVocabulary.seedIfNeeded(in: context, flags: flags)

        #expect(try !moodNames().contains("Raw"))
    }

    @Test func groupsAreTheFiveFromTheSpecInOrder() {
        #expect(MoodGroup.allCases.map(\.rawValue)
                == ["Dark & Driving", "Bright & Emotional", "Atmospheric", "Groovy", "Dub"])
    }

    @Test func nameTakenIsCaseAndWhitespaceInsensitive() throws {
        context.insert(MoodTag(name: "hypnotic", group: .darkAndDriving))
        #expect(try MoodVocabulary.isNameTaken("Hypnotic ", in: context))
        #expect(try !MoodVocabulary.isNameTaken("tribal", in: context))
    }

    @Test func aMoodDoesNotCollideWithItselfWhenRenamed() throws {
        let dubby = MoodTag(name: "dubby", group: .darkAndDriving)
        context.insert(dubby)
        #expect(try !MoodVocabulary.isNameTaken("Dubby", in: context, excluding: dubby))
    }

    // MARK: - Relationships

    @Test func trackAndMoodAreManyToMany() throws {
        let deep = MoodTag(name: "deep", group: .darkAndDriving), dark = MoodTag(name: "dark", group: .darkAndDriving)
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
        let dark = MoodTag(name: "dark", group: .darkAndDriving)
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
        let dark = MoodTag(name: "dark", group: .darkAndDriving)
        context.insert(dark)
        let a1 = track("A1", moods: [dark])
        try context.save()

        context.delete(a1)
        try context.save()

        #expect(try moodNames() == ["dark"])
        #expect(dark.tracks.isEmpty)
    }
}
