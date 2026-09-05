//
//  ContentView.swift
//  vynl
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CollectionView()
                .navigationTitle("Collection")
        }
    }
}

#Preview {
    ContentView()
}
