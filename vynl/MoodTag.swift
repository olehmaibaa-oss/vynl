//
//  MoodTag.swift
//  vynl
//

import Foundation
import SwiftData

/// The five fixed mood groups (DR-2), in display order.
enum MoodGroup: String, CaseIterable, Codable, Identifiable {
    case darkAndDriving = "Dark & Driving"
    case brightAndEmotional = "Bright & Emotional"
    case atmospheric = "Atmospheric"
    case groovy = "Groovy"
    case dub = "Dub"

    var id: String { rawValue }
}

/// A mood from the fixed vocabulary ("Hypnotic", "Spacey / Cosmic", ...). Moods
/// are created once and reused across tracks, so filters (E3) stay clean.
///
/// Names are stored as typed, only trimmed (DR-2; v1 lowercased them). Uniqueness
/// is case-insensitive and enforced by `MoodVocabulary.isNameTaken`, not by
/// `@Attribute(.unique)` — a unique attribute makes SwiftData upsert on collision,
/// which would silently merge a rename into an existing mood instead of rejecting it.
@Model
final class MoodTag {
    var name: String

    /// The group's raw value. Stored as a plain string so a filter can use it in a
    /// predicate; read and write it through `group`.
    var groupName: String

    @Relationship(deleteRule: .nullify, inverse: \Track.moods)
    var tracks: [Track] = []

    init(name: String, group: MoodGroup) {
        self.name = MoodTag.clean(name)
        self.groupName = group.rawValue
    }

    var group: MoodGroup {
        get { MoodGroup(rawValue: groupName) ?? .darkAndDriving }
        set { groupName = newValue.rawValue }
    }

    /// Trimmed, case kept.
    static func clean(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array where Element == MoodTag {
    /// A–Z, ignoring case ("acid" and "Atmospheric" sort together).
    func sortedByName() -> [MoodTag] {
        sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
