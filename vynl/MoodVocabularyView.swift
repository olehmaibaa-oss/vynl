//
//  MoodVocabularyView.swift
//  vynl
//
//  E2-S2: the mood vocabulary, reached through the gear on the Collection screen.
//  List A–Z, add, rename (tap a row), delete (swipe).
//

import SwiftUI
import SwiftData

struct MoodVocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodTag.name) private var moods: [MoodTag]

    @State private var formTarget: MoodFormTarget?

    var body: some View {
        List {
            ForEach(moods) { mood in
                Button {
                    formTarget = .rename(mood)
                } label: {
                    Text(mood.name)
                        .foregroundStyle(.primary)
                }
                .accessibilityIdentifier("moods.row")
            }
            .onDelete(perform: deleteMoods)
        }
        .accessibilityIdentifier("moods.list")
        .overlay {
            if moods.isEmpty {
                ContentUnavailableView("No moods", systemImage: "tag",
                                       description: Text("Add the moods you tag tracks with."))
            }
        }
        .navigationTitle("Moods")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    formTarget = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("moods.addButton")
            }
        }
        .sheet(item: $formTarget) { target in
            MoodFormView(target: target)
        }
    }

    /// Removes the mood from every track it tagged (nullify); never deletes a track.
    private func deleteMoods(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(moods[index])
        }
    }
}

#Preview {
    NavigationStack {
        MoodVocabularyView()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
