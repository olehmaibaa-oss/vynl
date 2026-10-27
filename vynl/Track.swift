//
//  Track.swift
//  vynl
//

import Foundation
import SwiftData

@Model
final class Track {
    var position: String
    var title: String
    var bpm: Int?
    var key: String?
    var release: Release?

    /// Many-to-many with MoodTag; the inverse and delete rule are declared on
    /// `MoodTag.tracks`. Deleting a track never deletes a mood.
    var moods: [MoodTag] = []

    init(position: String, title: String, bpm: Int? = nil, key: String? = nil, release: Release? = nil) {
        self.position = position
        self.title = title
        self.bpm = bpm
        self.key = key
        self.release = release
    }
}
