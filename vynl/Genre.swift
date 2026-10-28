//
//  Genre.swift
//  vynl
//
//  DR-2 (SCRUM-31): the collection's genre vocabulary. A release has several
//  genres; a genre lists its releases. Unique case-insensitively, and the first
//  spelling wins: "dub techno" never creates a second "Dub Techno".
//
//  Uniqueness lives in GenreVocabulary, not @Attribute(.unique), for the same
//  reason as MoodTag: unique makes SwiftData upsert instead of reject.
//

import Foundation
import SwiftData

@Model
final class Genre {
    var name: String

    /// Deleting a genre unlinks it from its releases; deleting a release keeps the genre.
    @Relationship(deleteRule: .nullify, inverse: \Release.genres)
    var releases: [Release] = []

    init(name: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GenreVocabulary {

    /// The genre with this name, compared trimmed and case-insensitively.
    static func existing(_ raw: String, in context: ModelContext) throws -> Genre? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // The vocabulary is small; comparing in memory keeps the case rule in one
        // place instead of in a predicate SwiftData may not translate.
        return try context.fetch(FetchDescriptor<Genre>())
            .first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// The existing genre in its first spelling, or a new one.
    static func findOrCreate(_ raw: String, in context: ModelContext) throws -> Genre {
        if let genre = try existing(raw, in: context) { return genre }
        let genre = Genre(name: raw)
        context.insert(genre)
        return genre
    }

    /// The form's chosen names as Genre models, existing ones reused; blanks and
    /// repeats (in any case) are dropped.
    static func resolve(names: [String], in context: ModelContext) throws -> [Genre] {
        var result: [Genre] = []
        for raw in names {
            let name = raw.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            let genre = try findOrCreate(name, in: context)
            if !result.contains(where: { $0 === genre }) { result.append(genre) }
        }
        return result
    }
}
