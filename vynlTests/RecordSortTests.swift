//
//  RecordSortTests.swift
//  vynlTests
//
//  DR-8 (SCRUM-37): every order, ties and missing years.
//

import Foundation
import SwiftData
import Testing
@testable import vynl

@MainActor
struct RecordSortTests {

    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: AppSchema.schema,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func release(_ artist: String, _ title: String = "T", year: Int? = nil, added: Double = 0) -> Release {
        let r = Release(artist: artist, title: title, year: year,
                        dateAdded: Date(timeIntervalSince1970: added))
        container.mainContext.insert(r)
        return r
    }

    /// Surgeon 1998 added first, Regis 2001 second, Abdulla Rashim 2012 last (the story's AC).
    private func acReleases() -> [Release] {
        [release("Surgeon", year: 1998, added: 1),
         release("Regis", year: 2001, added: 2),
         release("Abdulla Rashim", year: 2012, added: 3)]
    }

    @Test(arguments: [
        (RecordSort.artistAZ, ["Abdulla Rashim", "Regis", "Surgeon"]),
        (RecordSort.artistZA, ["Surgeon", "Regis", "Abdulla Rashim"]),
        (RecordSort.year, ["Surgeon", "Regis", "Abdulla Rashim"]),
        (RecordSort.recentlyAdded, ["Abdulla Rashim", "Regis", "Surgeon"]),
    ])
    func ordersFromTheStory(order: RecordSort, artists: [String]) {
        #expect(order.sorted(acReleases()).map(\.artist) == artists)
    }

    @Test func titleIsAToZ() {
        let rs = [release("A", "Zero"), release("B", "Atom"), release("C", "Mantra")]
        #expect(RecordSort.title.sorted(rs).map(\.title) == ["Atom", "Mantra", "Zero"])
    }

    @Test func noYearSortsLast() {
        let rs = [release("Aaa", year: nil), release("Zzz", year: 1998)]
        #expect(RecordSort.year.sorted(rs).map(\.artist) == ["Zzz", "Aaa"])
    }

    @Test func tiesFallBackToArtistAToZ() {
        let rs = [release("Surgeon", "X", year: 2000), release("Regis", "Y", year: 2000),
                  release("Mira", "Atom"), release("Kovac", "Atom")]
        #expect(RecordSort.year.sorted(rs).map(\.artist) == ["Regis", "Surgeon", "Kovac", "Mira"])
        #expect(RecordSort.title.sorted(rs).map(\.artist) == ["Kovac", "Mira", "Surgeon", "Regis"])
    }

    @Test func artistIgnoresCase() {
        let rs = [release("regis"), release("Abdulla")]
        #expect(RecordSort.artistAZ.sorted(rs).map(\.artist) == ["Abdulla", "regis"])
    }

    @Test func defaultIsArtistAToZ() {
        #expect(RecordSort.default == .artistAZ)
    }
}
