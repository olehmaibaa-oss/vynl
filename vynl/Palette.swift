//
//  Palette.swift
//  vynl
//
//  Colour tokens from the VYNL Design System. Each one is a Color Set in
//  Assets.xcassets/DesignSystem named exactly as the token. Views use these,
//  never a literal colour. Dark only: forced once in vynlApp.
//

import SwiftUI

enum Palette {
    static let bg = Color("bg")
    static let surface = Color("surface")
    static let surface2 = Color("surface-2")
    static let line = Color("line")
    static let lineStrong = Color("line-strong")
    static let ink = Color("ink")
    static let inkMuted = Color("ink-muted")
    static let inkDim = Color("ink-dim")
    static let invert = Color("invert")
    static let onInvert = Color("on-invert")
    static let onInvertMuted = Color("on-invert-muted")
    static let danger = Color("danger")
    static let focus = Color("focus")
    static let disc = Color("disc")
    static let discGroove = Color("disc-groove")
    static let onKey = Color("on-key")

    /// Fill for a Camelot key chip and its wheel segment, e.g. `key("8A")`. Keys only.
    static func key(_ camelot: String) -> Color {
        Color("key-\(camelot.lowercased())")
    }

    /// Every colour set name, for the test that checks the asset catalog.
    static let tokenNames: [String] = [
        "bg", "surface", "surface-2", "line", "line-strong",
        "ink", "ink-muted", "ink-dim", "invert", "on-invert", "on-invert-muted",
        "danger", "focus", "disc", "disc-groove", "on-key",
    ] + (1...12).flatMap { ["key-\($0)a", "key-\($0)b"] }
}

extension View {
    /// The `bg` ground behind a List or Form, instead of the system grouped background.
    func screenBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Palette.bg)
    }

    /// The `bg` ground behind a view that doesn't scroll (empty states, placeholders).
    func fillBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.bg)
    }
}
