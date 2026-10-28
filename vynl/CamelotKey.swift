//
//  CamelotKey.swift
//  vynl
//
//  DR-2 (SCRUM-31): a track's key is one of the 24 Camelot positions. Only the
//  Camelot code is stored ("8A"); the classic name ("Am") is derived, never stored.
//  Shown as "8A · Am". A = minor (inner ring), B = major (outer ring).
//

import Foundation

enum CamelotKey: String, CaseIterable, Codable, Identifiable {
    case k1A = "1A", k1B = "1B", k2A = "2A", k2B = "2B", k3A = "3A", k3B = "3B"
    case k4A = "4A", k4B = "4B", k5A = "5A", k5B = "5B", k6A = "6A", k6B = "6B"
    case k7A = "7A", k7B = "7B", k8A = "8A", k8B = "8B", k9A = "9A", k9B = "9B"
    case k10A = "10A", k10B = "10B", k11A = "11A", k11B = "11B", k12A = "12A", k12B = "12B"

    var id: String { rawValue }

    /// The stored form, e.g. "8A".
    var code: String { rawValue }

    /// Position on the wheel, 1–12.
    var number: Int { Int(rawValue.dropLast())! }

    /// A ring (minor) or B ring (major).
    var isMinor: Bool { rawValue.hasSuffix("A") }

    var classicName: String {
        switch self {
        case .k1A: "Abm"; case .k1B: "B"
        case .k2A: "Ebm"; case .k2B: "F#"
        case .k3A: "Bbm"; case .k3B: "Db"
        case .k4A: "Fm"; case .k4B: "Ab"
        case .k5A: "Cm"; case .k5B: "Eb"
        case .k6A: "Gm"; case .k6B: "Bb"
        case .k7A: "Dm"; case .k7B: "F"
        case .k8A: "Am"; case .k8B: "C"
        case .k9A: "Em"; case .k9B: "G"
        case .k10A: "Bm"; case .k10B: "D"
        case .k11A: "F#m"; case .k11B: "A"
        case .k12A: "Dbm"; case .k12B: "E"
        }
    }

    /// "8A · Am"
    var display: String { "\(code) · \(classicName)" }

    /// A Camelot code in any case ("8a", " 8A ").
    init?(code: String) {
        self.init(rawValue: code.trimmingCharacters(in: .whitespaces).uppercased())
    }

    /// A Camelot code or a classic name ("8A", "Am"). The track form uses the
    /// wheel since DR-6; kept for importing keys written as text (Discogs, post-MVP).
    init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let key = CamelotKey(code: trimmed) {
            self = key
        } else if let key = CamelotKey.allCases.first(where: { $0.classicName == trimmed }) {
            self = key
        } else {
            return nil
        }
    }
}
