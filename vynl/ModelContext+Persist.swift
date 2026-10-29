//
//  ModelContext+Persist.swift
//  vynl
//
//  TECH-1 (SCRUM-43): every user change is written to disk right away.
//  SwiftData's autosave alone left a new release only in memory: killed a few
//  seconds after Save (an app update, Xcode re-run, a crash), it was gone.
//

import Foundation
import SwiftData
import os

extension ModelContext {
    private static let log = Logger(subsystem: "dev.vynl", category: "store")

    /// Saves pending changes; a failure is logged, never silently dropped.
    func persist() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            Self.log.error("Save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
