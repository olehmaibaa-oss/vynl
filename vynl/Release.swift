//
//  Release.swift
//  vynl
//

import Foundation
import SwiftData

enum ReleaseStatus: String, Codable {
    case owned
    case sold
}

@Model
final class Release {
    var artist: String
    var title: String
    var genre: String
    var label: String?
    var year: Int?
    var status: ReleaseStatus

    @Relationship(deleteRule: .cascade, inverse: \Track.release)
    var tracks: [Track] = []

    init(artist: String, title: String, genre: String, label: String? = nil, year: Int? = nil, status: ReleaseStatus = .owned) {
        self.artist = artist
        self.title = title
        self.genre = genre
        self.label = label
        self.year = year
        self.status = status
    }
}
