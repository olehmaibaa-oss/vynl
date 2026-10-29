//
//  SchemaV2.swift
//  vynl
//
//  Schema v2, frozen (COV-1 / SCRUM-57). The shape the PO's phone stored from
//  DR-2 until labelImage arrived: nested copies of the models as they were, so
//  the migration plan can still read a v2 store. Stored properties and
//  relationships only; never edit these, add a new SchemaV<n> instead.
//

import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Release.self, Track.self, MoodTag.self, Genre.self]
    }

    @Model
    final class Release {
        var artist: String
        var title: String
        var label: String?
        var year: Int?
        var status: ReleaseStatus
        var genres: [Genre] = []
        @Attribute(.externalStorage) var cover: Data?
        var coverColor: String?
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
    }

    @Model
    final class Track {
        var position: String
        var title: String
        var bpm: Int?
        var keyCode: String?
        var release: Release?
        var moods: [MoodTag] = []

        init(position: String, title: String, bpm: Int? = nil, keyCode: String? = nil, release: Release? = nil) {
            self.position = position
            self.title = title
            self.bpm = bpm
            self.keyCode = keyCode
            self.release = release
        }
    }

    @Model
    final class MoodTag {
        var name: String
        var groupName: String
        @Relationship(deleteRule: .nullify, inverse: \Track.moods)
        var tracks: [Track] = []

        init(name: String, groupName: String) {
            self.name = name
            self.groupName = groupName
        }
    }

    @Model
    final class Genre {
        var name: String
        @Relationship(deleteRule: .nullify, inverse: \Release.genres)
        var releases: [Release] = []

        init(name: String) {
            self.name = name
        }
    }
}
