//
//  MoodVocabulary.swift
//  vynl
//

import Foundation
import SwiftData

/// The mood vocabulary's rules: what it starts with, and what a valid name is.
enum MoodVocabulary {

    static let defaults = [
        "hypnotic", "driving", "atmospheric", "deep",
        "dark", "minimal", "dubby", "industrial",
    ]

    static let seededFlag = "moodVocabularySeeded"

    /// Seeds the defaults once per store. "Once" is tracked with a flag rather
    /// than inferred from an empty table, so a user who deletes every mood
    /// doesn't get the defaults back on the next launch.
    static func seedIfNeeded(in context: ModelContext, flags: UserDefaults) throws {
        guard !flags.bool(forKey: seededFlag) else { return }
        for name in defaults where try !isNameTaken(name, in: context) {
            context.insert(MoodTag(name: name))
        }
        try context.save()
        flags.set(true, forKey: seededFlag)
    }

    /// Whether another mood already uses this name, compared normalised
    /// (trimmed, case-insensitive). Pass `excluding` when renaming, so a mood
    /// doesn't collide with itself.
    static func isNameTaken(_ raw: String, in context: ModelContext, excluding: MoodTag? = nil) throws -> Bool {
        let name = MoodTag.normalize(raw)
        let matches = try context.fetch(FetchDescriptor<MoodTag>(predicate: #Predicate { $0.name == name }))
        return matches.contains { $0.persistentModelID != excluding?.persistentModelID }
    }
}
