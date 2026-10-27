//
//  PaletteTests.swift
//  vynlTests
//
//  DR-1 (SCRUM-30): every Design System colour token is a Color Set in the app's
//  asset catalog. A missing set renders as clear at run time with no build error,
//  so this is the only thing that catches a typo in a token name.
//

import Testing
import UIKit
@testable import vynl

struct PaletteTests {

    // vynlTests runs hosted in the app, so the main bundle holds the asset catalog.
    private let bundle = Bundle.main

    @Test("Every token resolves to a colour set", arguments: Palette.tokenNames)
    func tokenResolves(_ name: String) {
        #expect(UIColor(named: name, in: bundle, compatibleWith: nil) != nil, "missing colour set \(name)")
    }

    @Test func fortyTokens() {
        // 16 semantic + 24 Camelot keys, as in the Design System's tokens.json
        // (preview-only glass / scrim excluded).
        #expect(Palette.tokenNames.count == 40)
        #expect(Set(Palette.tokenNames).count == 40)
    }

    @Test func aliasesMatchTheirTarget() {
        func rgba(_ name: String) -> [CGFloat] {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(named: name, in: bundle, compatibleWith: nil)!.getRed(&r, green: &g, blue: &b, alpha: &a)
            return [r, g, b, a]
        }
        #expect(rgba("invert") == rgba("ink"))
        #expect(rgba("focus") == rgba("ink"))
        #expect(rgba("on-invert") == rgba("bg"))
        #expect(rgba("on-key") == rgba("bg"))
    }

    @Test func keyHelperBuildsTheSetName() {
        #expect(UIColor(named: "key-8a", in: bundle, compatibleWith: nil) != nil)
        #expect(Palette.key("8A") == Palette.key("8a"))
    }
}
