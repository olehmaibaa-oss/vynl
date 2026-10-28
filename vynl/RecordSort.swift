//
//  RecordSort.swift
//  vynl
//
//  DR-8 (SCRUM-37): the collection's order, shared by grid and stack and
//  remembered (`collectionSort`). Equal keys fall back to artist A–Z, then
//  title, so the order is always deterministic. Year is oldest first, records
//  without a year last. Recently added = `dateAdded`, newest first.
//

import Foundation

enum RecordSort: String, CaseIterable, Identifiable {
    case artistAZ, artistZA, title, year, recentlyAdded

    static let storageKey = "collectionSort"
    static let `default` = RecordSort.artistAZ

    var id: String { rawValue }

    /// The option's name: chip label, filter bar summary, accessibility value.
    var name: String {
        switch self {
        case .artistAZ: "Artist A–Z"
        case .artistZA: "Artist Z–A"
        case .title: "Title"
        case .year: "Year"
        case .recentlyAdded: "Recently added"
        }
    }

    func sorted(_ releases: [Release]) -> [Release] {
        releases.sorted(by: areInIncreasingOrder)
    }

    func areInIncreasingOrder(_ a: Release, _ b: Release) -> Bool {
        switch self {
        case .artistAZ:
            break
        case .artistZA:
            let c = Self.compare(a.artist, b.artist)
            if c != .orderedSame { return c == .orderedDescending }
        case .title:
            let c = Self.compare(a.title, b.title)
            if c != .orderedSame { return c == .orderedAscending }
        case .year:
            switch (a.year, b.year) {
            case let (x?, y?) where x != y: return x < y
            case (_?, nil): return true
            case (nil, _?): return false
            default: break
            }
        case .recentlyAdded:
            if a.dateAdded != b.dateAdded { return a.dateAdded > b.dateAdded }
        }
        return Self.artistThenTitle(a, b)
    }

    private static func artistThenTitle(_ a: Release, _ b: Release) -> Bool {
        let c = compare(a.artist, b.artist)
        if c != .orderedSame { return c == .orderedAscending }
        return compare(a.title, b.title) == .orderedAscending
    }

    private static func compare(_ a: String, _ b: String) -> ComparisonResult {
        a.localizedStandardCompare(b)
    }
}
