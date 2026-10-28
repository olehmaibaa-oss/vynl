//
//  MoodVocabularyView.swift
//  vynl
//
//  E2-S2 / E2-S5: the mood vocabulary, reached through the gear on the Collection
//  screen. Grouped in the five fixed groups (in MoodGroup order), A–Z inside each.
//  Add (into a chosen group), rename (tap a row), delete (swipe).
//

import SwiftUI
import SwiftData

struct MoodVocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMoods: [MoodTag]

    @State private var formTarget: MoodFormTarget?

    /// A group's moods A–Z ignoring case; names are stored as typed (DR-2).
    private func moods(in group: MoodGroup) -> [MoodTag] {
        allMoods.filter { $0.group == group }.sortedByName()
    }

    var body: some View {
        List {
            ForEach(MoodGroup.allCases) { group in
                let moods = moods(in: group)
                if !moods.isEmpty {
                    Section {
                        ForEach(moods) { mood in
                            Button {
                                formTarget = .rename(mood)
                            } label: {
                                Text(mood.name)
                                    .foregroundStyle(Palette.ink)
                            }
                            .accessibilityIdentifier("moods.row")
                        }
                        .onDelete { offsets in delete(offsets, from: moods) }
                    } header: {
                        // Design System: group headers are `meta`, uppercase, ink-muted.
                        Text(group.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Palette.inkMuted)
                            .accessibilityLabel(group.rawValue)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("moods.group")
                    }
                }
            }
        }
        .screenBackground()
        .accessibilityIdentifier("moods.list")
        .overlay {
            if allMoods.isEmpty {
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
                .accessibilityLabel("Add mood")
                .accessibilityIdentifier("moods.addButton")
            }
        }
        .sheet(item: $formTarget) { target in
            MoodFormView(target: target)
        }
    }

    /// Removes the mood from every track it tagged (nullify); never deletes a track.
    private func delete(_ offsets: IndexSet, from moods: [MoodTag]) {
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
