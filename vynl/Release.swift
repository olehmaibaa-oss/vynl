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
    var label: String?
    var year: Int?
    var status: ReleaseStatus

    /// Several genres (DR-2). The inverse and delete rule are on `Genre.releases`.
    var genres: [Genre] = []

    /// The cover photo, stored next to the store rather than inside it. Nil means
    /// a generated placeholder, which is computed and never stored.
    @Attribute(.externalStorage) var cover: Data?

    /// "#RRGGBB": the cover colour that contrasts most with the cover's average,
    /// among colours covering at least ~5% of it. Set when a cover is saved (DR-5),
    /// cleared when it is removed; placeholders derive theirs from their seed.
    var coverColor: String?

    /// Set on insert, never edited. For the "recently added" sort.
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \Track.release)
    var tracks: [Track] = []

    init(artist: String, title: String, genres: [Genre] = [], label: String? = nil,
         year: Int? = nil, status: ReleaseStatus = .owned, dateAdded: Date = .now) {
        self.artist = artist
        self.title = title
        self.label = label
        self.year = year
        self.status = status
        self.dateAdded = dateAdded
        self.genres = genres
    }

    /// Genre names A–Z.
    var genreNames: [String] {
        genres.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}
