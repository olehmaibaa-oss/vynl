//
//  SleeveTests.swift
//  vynlTests
//
//  Design review 28.10: four circle-free placeholder patterns picked by
//  (seed >> 1) % 4, and the stack's tracks badge never reads "0 tracks".
//

import Testing
@testable import vynl

struct SleeveTests {

    @Test func patternComesFromSeedBitsOneAndTwo() {
        #expect(GeneratedSleeve.pattern(for: 0b000) == .bars)
        #expect(GeneratedSleeve.pattern(for: 0b011) == .lines)
        #expect(GeneratedSleeve.pattern(for: 0b100) == .diagonal)
        #expect(GeneratedSleeve.pattern(for: 0b111) == .split)
    }

    @Test func realTitlesReachEveryPattern() {
        let seeds = (0..<64).map { CoverArt.seed(artist: "Artist \($0)", title: "Title \($0)") }
        #expect(Set(seeds.map(GeneratedSleeve.pattern(for:))) == Set(GeneratedSleeve.Pattern.allCases))
    }

    @Test(arguments: [(0, "No tracks"), (1, "1 track"), (12, "12 tracks")])
    func tracksBadge(count: Int, text: String) {
        #expect(CollectionStackView.tracksBadge(count) == text)
    }
}
