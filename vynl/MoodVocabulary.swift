//
//  MoodVocabulary.swift
//  vynl
//

import Foundation
import SwiftData

/// The mood vocabulary's rules: what it starts with, and what a valid name is.
enum MoodVocabulary {

    /// The starting vocabulary (E2-S5, SCRUM-38): the PRD's 30 moods in 5 groups,
    /// in the PRD's spelling.
    static let defaults: [(name: String, group: MoodGroup)] =
        [("Dark", .darkAndDriving), ("Hypnotic", .darkAndDriving), ("Minimal", .darkAndDriving),
         ("Driving", .darkAndDriving), ("Mysterious", .darkAndDriving), ("Ominous", .darkAndDriving),
         ("Aggressive", .darkAndDriving), ("Raw", .darkAndDriving), ("Industrial", .darkAndDriving),
         ("Euphoric", .brightAndEmotional), ("Uplifting", .brightAndEmotional),
         ("Melancholic", .brightAndEmotional), ("Emotional", .brightAndEmotional),
         ("Nostalgic", .brightAndEmotional), ("Epic", .brightAndEmotional),
         ("Deep", .atmospheric), ("Atmospheric", .atmospheric), ("Dreamy", .atmospheric),
         ("Ethereal", .atmospheric), ("Spacey / Cosmic", .atmospheric),
         ("Trippy / Psychedelic", .atmospheric), ("Chill / Laid back", .atmospheric),
         ("Groovy", .groovy), ("Funky", .groovy), ("Bouncy", .groovy), ("Sexy / Sensual", .groovy),
         ("Tribal", .groovy), ("Playful", .groovy), ("Energetic", .groovy),
         ("Dubby", .dub)]

    static let seededFlag = "moodVocabularySeeded"

    /// Which starting vocabulary this store has: 1 = the 8 lowercase v1 moods,
    /// 2 = the PRD's 30. Absent with `seededFlag` set means 1.
    static let seedVersionKey = "moodVocabularySeedVersion"
    static let seedVersion = 2

    /// Seeds the defaults once per store, and brings a v1 vocabulary up to v2.
    /// "Once" is tracked with flags rather than inferred from an empty table, so a
    /// user who deletes every mood doesn't get the defaults back on the next launch.
    static func seedIfNeeded(in context: ModelContext, flags: UserDefaults) throws {
        if !flags.bool(forKey: seededFlag) {
            for seed in defaults where try !isNameTaken(seed.name, in: context) {
                context.insert(MoodTag(name: seed.name, group: seed.group))
            }
        } else if flags.integer(forKey: seedVersionKey) < seedVersion {
            try upgradeFromV1(in: context)
        } else {
            return
        }
        try context.save()
        flags.set(true, forKey: seededFlag)
        flags.set(seedVersion, forKey: seedVersionKey)
    }

    /// v1 → v2: a mood that matches a PRD mood (ignoring case) takes the PRD
    /// spelling and group, tags kept; missing PRD moods are added; moods the person
    /// made themselves are left alone. A PRD mood they deleted comes back once,
    /// with this upgrade.
    static func upgradeFromV1(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<MoodTag>())
        for seed in defaults {
            if let mood = existing.first(where: { $0.name.caseInsensitiveCompare(seed.name) == .orderedSame }) {
                mood.name = seed.name
                mood.group = seed.group
            } else {
                context.insert(MoodTag(name: seed.name, group: seed.group))
            }
        }
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
