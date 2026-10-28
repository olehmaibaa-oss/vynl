//
//  CratesPlaceholderView.swift
//  vynl
//
//  Stand-in for the Crates zone until E4. The tab exists now so the app's
//  navigation shape matches the Tech Spec; its content arrives with E4.
//

import SwiftUI

struct CratesPlaceholderView: View {
    // DR-3: the section title is content (Design System SectionTitle), so the bar
    // draws none. No "+" here until E4: no disabled or placeholder control.
    var body: some View {
        VStack(spacing: 0) {
            SectionTitle(text: "Crates")
                .padding(.top, 8)
            ContentUnavailableView {
                Label("Crates are on the way", systemImage: "archivebox")
            } description: {
                Text("Pick records for a gig and mark the tracks you'll play.")
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("crates.placeholder")
        }
        .fillBackground()
        .hiddenNavigationTitle()
    }
}

#Preview {
    NavigationStack {
        CratesPlaceholderView()
            .navigationTitle("Crates")
    }
}
