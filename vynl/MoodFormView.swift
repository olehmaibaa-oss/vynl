//
//  MoodFormView.swift
//  vynl
//
//  Add or rename a mood. Names are normalised (trimmed, lowercased) and must be
//  unique within the vocabulary — compared case-insensitively.
//

import SwiftUI
import SwiftData

enum MoodFormTarget: Identifiable {
    case add
    case rename(MoodTag)

    var id: String {
        switch self {
        case .add: return "add"
        case .rename(let mood): return "rename-\(mood.persistentModelID.hashValue)"
        }
    }

    var mood: MoodTag? {
        if case .rename(let mood) = self { return mood }
        return nil
    }
}

struct MoodFormView: View {
    let target: MoodFormTarget

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    private var normalized: String { MoodTag.normalize(name) }

    private var isDuplicate: Bool {
        guard !normalized.isEmpty else { return false }
        return (try? MoodVocabulary.isNameTaken(name, in: modelContext, excluding: target.mood)) ?? false
    }

    private var canSave: Bool { !normalized.isEmpty && !isDuplicate }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mood", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("moodForm.nameField")
                } footer: {
                    if isDuplicate {
                        Text("\"\(normalized)\" already exists.")
                            .foregroundStyle(Palette.danger)
                            .accessibilityIdentifier("moodForm.duplicateError")
                    }
                }
            }
            .screenBackground()
            .navigationTitle(target.mood == nil ? "Add Mood" : "Rename Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("moodForm.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("moodForm.saveButton")
                }
            }
            .onAppear {
                if let mood = target.mood {
                    name = mood.name
                }
            }
        }
    }

    private func save() {
        // Re-check at save time: the button's disabled state is UI, not a guard.
        guard canSave else { return }
        switch target {
        case .add:
            modelContext.insert(MoodTag(name: normalized))
        case .rename(let mood):
            mood.name = normalized
        }
        dismiss()
    }
}
