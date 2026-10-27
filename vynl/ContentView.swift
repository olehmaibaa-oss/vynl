//
//  ContentView.swift
//  vynl
//

import SwiftUI

/// App shell: two equal zones in a tab bar, each with its own navigation stack,
/// so drilling into a release in Collection survives a trip to Crates and back.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Collection", systemImage: "opticaldisc") {
                NavigationStack {
                    CollectionView()
                        .navigationTitle("Collection")
                }
            }
            Tab("Crates", systemImage: "archivebox") {
                NavigationStack {
                    CratesPlaceholderView()
                        .navigationTitle("Crates")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
