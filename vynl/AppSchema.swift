//
//  AppSchema.swift
//  vynl
//

import Foundation
import SwiftData

/// Every persisted model, in one place, so the app and the unit tests can't
/// drift onto different schemas.
enum AppSchema {
    /// Bump on every model change; a different version on disk resets the store
    /// (StoreReset) until migrations replace that.
    /// v1: E1 + E2-S1. v2: DR-2 (Genre, cover, coverColor, dateAdded, Camelot key, mood groups).
    static let version = 2

    static let models: [any PersistentModel.Type] = [
        Release.self,
        Track.self,
        MoodTag.self,
        Genre.self,
    ]

    static var schema: Schema { Schema(models) }

    /// Where the on-device store lives (SwiftData's default location, made explicit
    /// so StoreReset and the container agree on it).
    static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }
}
