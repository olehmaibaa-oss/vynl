//
//  SectionTitle.swift
//  vynl
//
//  The Design System's section title: uppercase `screen-title` (SF Pro black, 40pt)
//  followed by the heavy rule in ink. Used for CRATES (DR-3). Collection draws no
//  visible title since Collection draft v0.
//

import SwiftUI

struct SectionTitle: View {
    let text: String

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text.uppercased())
                .font(.system(size: size, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(Palette.ink)
                .frame(height: 3)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Keeps `navigationTitle` for VoiceOver and the back button, but draws no
    /// title in the bar (Collection, Crates: their title is content, not chrome).
    func hiddenNavigationTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("").accessibilityHidden(true)
                }
            }
    }
}
