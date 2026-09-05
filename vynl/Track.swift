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

    init(position: String, title: String, bpm: Int? = nil, key: String? = nil, release: Release? = nil) {
        self.position = position
        self.title = title
        self.bpm = bpm
        self.key = key
        self.release = release
    }
}
