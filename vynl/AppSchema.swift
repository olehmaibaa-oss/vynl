//
//  AppSchema.swift
//  vynl
//

import SwiftData

/// Every persisted model, in one place, so the app and the unit tests can't
/// drift onto different schemas.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Release.self,
        Track.self,
        MoodTag.self,
    ]

    static var schema: Schema { Schema(models) }
}
