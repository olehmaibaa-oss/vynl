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

    /// The Camelot code, e.g. "8A" (DR-2). Stored as a plain string so E3 can
    /// filter on it in a predicate; read and write it through `key`.
    var keyCode: String?

    var release: Release?

    /// Many-to-many with MoodTag; the inverse and delete rule are declared on
    /// `MoodTag.tracks`. Deleting a track never deletes a mood.
    var moods: [MoodTag] = []

    init(position: String, title: String, bpm: Int? = nil, key: CamelotKey? = nil, release: Release? = nil) {
        self.position = position
        self.title = title
        self.bpm = bpm
        self.keyCode = key?.code
        self.release = release
    }

    var key: CamelotKey? {
        get { keyCode.flatMap(CamelotKey.init(rawValue:)) }
        set { keyCode = newValue?.code }
    }
}
