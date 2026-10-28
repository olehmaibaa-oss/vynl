//
//  MoodFormView.swift
//  vynl
//
//  Add or rename a mood. Names are kept as typed, only trimmed (DR-2), and must be
//  unique within the vocabulary — compared case-insensitively. Adding needs a
//  group (E2-S5); renaming keeps the mood's group (moving between groups is not
//  in the PRD).
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
    @State private var group: MoodGroup?

    /// Trimmed, case kept (DR-2).
    private var normalized: String { MoodTag.clean(name) }

    private var isDuplicate: Bool {
        guard !normalized.isEmpty else { return false }
        return (try? MoodVocabulary.isNameTaken(name, in: modelContext, excluding: target.mood)) ?? false
    }

    private var canSave: Bool {
        !normalized.isEmpty && !isDuplicate && (target.mood != nil || group != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mood", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("moodForm.nameField")
                } footer: {
                    if isDuplicate {
                        Text("\"\(normalized)\" already exists.")
                            .foregroundStyle(Palette.danger)
                            .accessibilityIdentifier("moodForm.duplicateError")
                    }
                }
                if target.mood == nil {
                    Section("Group") {
                        groupPicker
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
            guard let group else { return }
            modelContext.insert(MoodTag(name: normalized, group: group))
        case .rename(let mood):
            mood.name = normalized
        }
        dismiss()
    }

    /// Five chips, one pick; the chosen one is inverted (Design System: inversion = "on").
    private var groupPicker: some View {
        FlowLayout(spacing: 8) {
            ForEach(MoodGroup.allCases) { option in
                let isOn = group == option
                Button {
                    group = option
                } label: {
                    ChipLabel(text: option.rawValue, inverted: isOn)
                        .chipFrame(inverted: isOn)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(option.rawValue)
                .accessibilityIdentifier("moodForm.groupOption")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("moodForm.groupPicker")
        .padding(.vertical, 4)
    }
}
