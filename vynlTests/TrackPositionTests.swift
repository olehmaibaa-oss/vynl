//
//  TrackPositionTests.swift
//  vynlTests
//
//  TRK-1 (SCRUM-60): parsing "A2" and the next free position.
//

import Testing
@testable import vynl

struct TrackPositionTests {

    @Test(arguments: [("A2", "A", 2), ("b1", "B", 1), (" F9 ", "F", 9)])
    func parsesSideAndNumber(raw: String, side: String, number: Int) throws {
        let p = try #require(TrackPosition.parse(raw))
        #expect(p.side == side && p.number == number)
    }

    @Test(arguments: ["AA", "C2a", "12", "G1", "A0", ""])
    func oddPositionsAreOther(raw: String) {
        #expect(TrackPosition.parse(raw) == nil)
    }

    @Test(arguments: [
        ([String](), "A1"),
        (["A1", "A2"], "A3"),
        (["B1"], "B2"),
        (["A1", "A2", "B1"], "B2"),
        (["A9"], "B1"),
        (["AA", "C2a"], "A1"),
        (["F9"], "F9"),
    ])
    func nextFree(after positions: [String], expected: String) {
        #expect(TrackPosition.nextFree(after: positions) == expected)
    }
}
