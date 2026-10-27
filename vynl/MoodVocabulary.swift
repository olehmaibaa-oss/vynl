//
//  MoodVocabulary.swift
//  vynl
//

import Foundation
import SwiftData

/// The mood vocabulary's rules: what it starts with, and what a valid name is.
enum MoodVocabulary {

    /// The v1 seeds, now with their PRD group. E2-S5 (SCRUM-38) replaces this with
    /// the PRD's 30 moods in their PRD spelling; until then the names stay as v1
    /// had them, so the mood screens and their tests don't change in DR-2.
    static let defaults: [(name: String, group: MoodGroup)] = [
        ("hypnotic", .darkAndDriving), ("driving", .darkAndDriving),
        ("dark", .darkAndDriving), ("minimal", .darkAndDriving),
        ("industrial", .darkAndDriving),
        ("atmospheric", .atmospheric), ("deep", .atmospheric),
        ("dubby", .dub),
    ]

    /// Group for a mood added from the vocabulary screen until E2-S5 adds the
    /// group picker there.
    static let defaultGroupForNewMoods: MoodGroup = .darkAndDriving

    static let seededFlag = "moodVocabularySeeded"

    /// Seeds the defaults once per store. "Once" is tracked with a flag rather
    /// than inferred from an empty table, so a user who deletes every mood
    /// doesn't get the defaults back on the next launch.
    static func seedIfNeeded(in context: ModelContext, flags: UserDefaults) throws {
        guard !flags.bool(forKey: seededFlag) else { return }
        for seed in defaults where try !isNameTaken(seed.name, in: context) {
            context.insert(MoodTag(name: seed.name, group: seed.group))
        }
        try context.save()
        flags.set(true, forKey: seededFlag)
    }

    /// Whether another mood already uses this name, compared trimmed and
    /// case-insensitively. Pass `excluding` when renaming, so a mood doesn't
    /// collide with itself.
    static func isNameTaken(_ raw: String, in context: ModelContext, excluding: MoodTag? = nil) throws -> Bool {
        let name = MoodTag.clean(raw)
        // A few dozen moods at most; comparing in memory keeps the case rule in
        // one place instead of in a predicate SwiftData may not translate.
        return try context.fetch(FetchDescriptor<MoodTag>()).contains {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
                && $0.persistentModelID != excluding?.persistentModelID
        }
    }
}
