//
//  CamelotKeyTests.swift
//  vynlTests
//
//  DR-2 (SCRUM-31): a track's key is a Camelot position; the classic name is derived.
//

import Testing
import SwiftData
@testable import vynl

@MainActor
struct CamelotKeyTests {

    // Scenario: Camelot key round-trips
    @Test func eightAIsAMinor() throws {
        let container = try ModelContainer(
            for: AppSchema.schema,
            configurations: [ModelConfiguration(schema: AppSchema.schema, isStoredInMemoryOnly: true)])
        let context = container.mainContext
        context.insert(Track(position: "A1", title: "Magneze", key: .k8A))
        try context.save()

        let track = try #require(try context.fetch(FetchDescriptor<Track>()).first)
        #expect(track.keyCode == "8A")
        #expect(track.key == .k8A)
        #expect(track.key?.classicName == "Am")
        #expect(track.key?.display == "8A · Am")
    }

    // Scenario: Every Camelot position maps to exactly one classic key
    @Test func twentyFourPositionsTwentyFourClassicKeys() {
        #expect(CamelotKey.allCases.count == 24)
        #expect(Set(CamelotKey.allCases.map(\.classicName)).count == 24)
        #expect(Set(CamelotKey.allCases.map(\.code)).count == 24)
    }

    @Test func ringsAndNumbers() {
        #expect(CamelotKey.k8A.isMinor && CamelotKey.k8A.number == 8)
        #expect(!CamelotKey.k12B.isMinor && CamelotKey.k12B.number == 12)
        #expect(CamelotKey.allCases.filter(\.isMinor).allSatisfy { $0.classicName.hasSuffix("m") })
        #expect(CamelotKey.allCases.filter { !$0.isMinor }.allSatisfy { !$0.classicName.hasSuffix("m") })
    }

    // The standard wheel: neighbours are a fifth apart, A and B of a number are relative keys.
    @Test(arguments: [
        ("1A", "Abm"), ("1B", "B"), ("4A", "Fm"), ("6B", "Bb"),
        ("8B", "C"), ("11A", "F#m"), ("12A", "Dbm"), ("12B", "E"),
    ])
    func knownMappings(code: String, classic: String) throws {
        #expect(try #require(CamelotKey(code: code)).classicName == classic)
    }

    @Test func parsingAcceptsCodesInAnyCaseAndClassicNames() {
        #expect(CamelotKey(parsing: " 8a ") == .k8A)
        #expect(CamelotKey(parsing: "Am") == .k8A)
        #expect(CamelotKey(parsing: "F#m") == .k11A)
        #expect(CamelotKey(parsing: "13A") == nil)
        #expect(CamelotKey(parsing: "H") == nil)
        #expect(CamelotKey(parsing: "") == nil)
    }

    @Test func noKeyStoresNothing() {
        let track = Track(position: "A1", title: "Magneze")
        #expect(track.keyCode == nil && track.key == nil)
    }

    // DR-6: the wheel's "compatible keys" — same number on the other ring, ±1 on the same ring.
    @Test func compatibleKeys() {
        #expect(CamelotKey.k8A.compatible == [.k8B, .k7A, .k9A])
        #expect(CamelotKey.k12B.compatible == [.k12A, .k11B, .k1B])
        #expect(CamelotKey.k1A.compatible == [.k1B, .k12A, .k2A])
        #expect(CamelotKey.allCases.allSatisfy { $0.compatible.count == 3 && !$0.compatible.contains($0) })
    }
}
