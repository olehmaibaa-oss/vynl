//
//  GenrePicker.swift
//  vynl
//
//  DR-4 (SCRUM-33): the release form's genres. Chips for the chosen genres, a
//  field to type one, suggestions from genres already in the collection, and an
//  "Add" row for a new one. Works on names only; the form turns them into Genre
//  models on Save, so a cancelled form never leaves genres behind.
//

import SwiftUI
import SwiftData

struct GenrePicker: View {
    @Binding var names: [String]

    @Query private var existing: [Genre]
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    private var typed: String { input.trimmingCharacters(in: .whitespaces) }

    /// Existing genres containing what's typed, A–Z, minus the ones already chosen.
    private var suggestions: [String] {
        guard !typed.isEmpty else { return [] }
        return existing.map(\.name)
            .filter { $0.localizedCaseInsensitiveContains(typed) && !isChosen($0) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .prefix(5)
            .map { $0 }
    }

    /// "Add" is offered only when nothing in the collection already has this name.
    private var canAddNew: Bool {
        !typed.isEmpty
            && !existing.contains { $0.name.caseInsensitiveCompare(typed) == .orderedSame }
            && !isChosen(typed)
    }

    var body: some View {
        if !names.isEmpty {
            FlowLayout {
                ForEach(names, id: \.self) { name in
                    chip(name)
                }
            }
            .padding(.vertical, 4)
        }

        TextField("Add a genre", text: $input)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($inputFocused)
            .submitLabel(.done)
            .onSubmit { add(typed) }
            .accessibilityIdentifier("addRelease.genreInput")

        ForEach(suggestions, id: \.self) { name in
            Button {
                add(name)
            } label: {
                Text(name).foregroundStyle(Palette.ink)
            }
            .accessibilityIdentifier("addRelease.genreSuggestion")
        }

        if canAddNew {
            Button {
                add(typed)
            } label: {
                Label("Add \"\(typed)\"", systemImage: "plus")
                    .foregroundStyle(Palette.ink)
            }
            .accessibilityIdentifier("addRelease.genreAddNewButton")
        }
    }

    private func chip(_ name: String) -> some View {
        HStack(spacing: 6) {
            ChipLabel(text: name)
                .accessibilityIdentifier("addRelease.genreChip")
                .accessibilityLabel(name)
            Button {
                names.removeAll { $0 == name }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            // In a Form row, a default-style button would fire for a tap
            // anywhere in the row; borderless keeps each chip's x separate.
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(name)")
            .accessibilityIdentifier("addRelease.genreRemoveButton")
        }
        .padding(.leading, 10)
        .frame(minHeight: 28)
        .overlay(Rectangle().stroke(Palette.lineStrong, lineWidth: 1))
    }

    private func isChosen(_ name: String) -> Bool {
        names.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Adds in the collection's spelling when the genre exists ("dub techno" →
    /// "Dub Techno"); ignores blanks and repeats.
    private func add(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let spelled = existing.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.name ?? name
        if !isChosen(spelled) { names.append(spelled) }
        input = ""
        inputFocused = true
    }
}
