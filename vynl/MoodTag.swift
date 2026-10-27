//
//  MoodTag.swift
//  vynl
//

import Foundation
import SwiftData

/// A mood from the fixed vocabulary ("hypnotic", "driving", ...). Moods are
/// created once and reused across tracks, so filters (E3) stay clean.
///
/// Names are stored normalised: trimmed and lowercased. Uniqueness is enforced
/// by `MoodVocabulary.isNameTaken`, not by `@Attribute(.unique)` — a unique
/// attribute makes SwiftData upsert on collision, which would silently merge a
/// rename into an existing mood instead of rejecting it.
@Model
final class MoodTag {
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \Track.moods)
    var tracks: [Track] = []

    init(name: String) {
        self.name = MoodTag.normalize(name)
    }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
