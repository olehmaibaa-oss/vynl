//
//  GenreTests.swift
//  vynlTests
//
//  DR-2 (SCRUM-31): Genre, many-to-many with Release; Release.dateAdded.
//

import Foundation
import Testing
import SwiftData
@testable import vynl

@MainActor
struct GenreTests {

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: AppSchema.schema,
            configurations: [ModelConfiguration(schema: AppSchema.schema, isStoredInMemoryOnly: true)])
    }

    private func genreCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Genre>())
    }

    private func release(_ artist: String, genres: [Genre]) -> Release {
        let release = Release(artist: artist, title: "Title")
        context.insert(release)
        release.genres = genres
        return release
    }

    // Scenario: Genres are unique regardless of case
    @Test func sameNameInAnotherCaseReusesTheFirstSpelling() throws {
        let dubTechno = try GenreVocabulary.findOrCreate("Dub Techno", in: context)
        try context.save()

        let again = try GenreVocabulary.findOrCreate("  dub techno ", in: context)
        let surgeon = release("Surgeon", genres: [again])
        try context.save()

        #expect(try genreCount() == 1)
        #expect(again === dubTechno)
        #expect(surgeon.genreNames == ["Dub Techno"])
    }

    // Scenario: A release can have several genres
    @Test func aReleaseCanHaveSeveralGenres() throws {
        let techno = try GenreVocabulary.findOrCreate("Techno", in: context)
        let dubTechno = try GenreVocabulary.findOrCreate("Dub Techno", in: context)
        let surgeon = release("Surgeon", genres: [techno, dubTechno])
        try context.save()

        #expect(surgeon.genreNames == ["Dub Techno", "Techno"])
        #expect(techno.releases.map(\.artist) == ["Surgeon"])
        #expect(dubTechno.releases.map(\.artist) == ["Surgeon"])
    }

    // Scenario: Deleting a release keeps its genres
    @Test func deletingAReleaseKeepsItsGenre() throws {
        let techno = try GenreVocabulary.findOrCreate("Techno", in: context)
        let surgeon = release("Surgeon", genres: [techno])
        _ = release("Regis", genres: [techno])
        try context.save()

        context.delete(surgeon)
        try context.save()

        #expect(try genreCount() == 1)
        #expect(techno.releases.map(\.artist) == ["Regis"])
    }

    @Test func aCommaListResolvesToDistinctGenres() throws {
        _ = try GenreVocabulary.findOrCreate("Techno", in: context)
        let genres = try GenreVocabulary.resolve(list: "techno, Dub Techno, , TECHNO", in: context)

        #expect(genres.map(\.name) == ["Techno", "Dub Techno"])
        #expect(try genreCount() == 2)
    }

    // Scenario: dateAdded is set on insert
    @Test func dateAddedIsTheCreationTime() throws {
        let before = Date.now
        let surgeon = release("Surgeon", genres: [])
        try context.save()
        let after = Date.now

        #expect(surgeon.dateAdded >= before && surgeon.dateAdded <= after)
    }

    @Test func coverFieldsStartEmpty() {
        let surgeon = Release(artist: "Surgeon", title: "Title")
        #expect(surgeon.cover == nil)
        #expect(surgeon.coverColor == nil)
    }

    @Test func coverDataPersists() throws {
        let surgeon = release("Surgeon", genres: [])
        surgeon.cover = Data([0xFF, 0xD8, 0xFF])
        surgeon.coverColor = "#E5848C"
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Release>()).first)
        #expect(fetched.cover == Data([0xFF, 0xD8, 0xFF]))
        #expect(fetched.coverColor == "#E5848C")
    }
}
