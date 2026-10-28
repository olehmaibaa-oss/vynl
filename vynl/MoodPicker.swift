//
//  MoodPicker.swift
//  vynl
//
//  E2-S6 (SCRUM-39): the Design System MoodPicker. The vocabulary in its five
//  groups (fixed order), chips A–Z inside each, multi-select, a selected chip
//  inverted. Works on a selection binding; the caller decides when to write it
//  (the track form: only on Save).
//

import SwiftUI
import SwiftData

struct MoodPicker: View {
    @Binding var selection: Set<PersistentIdentifier>

    @Query private var allMoods: [MoodTag]

    var body: some View {
        ForEach(MoodGroup.allCases) { group in
            let moods = allMoods.filter { $0.group == group }.sortedByName()
            if !moods.isEmpty {
                Section {
                    FlowLayout(spacing: 8) {
                        ForEach(moods) { mood in
                            chip(mood)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text(group.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Palette.inkMuted)
                        .accessibilityLabel(group.rawValue)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("trackForm.moodGroup")
                }
            }
        }
    }

    private func chip(_ mood: MoodTag) -> some View {
        let isOn = selection.contains(mood.persistentModelID)
        return Button {
            if isOn {
                selection.remove(mood.persistentModelID)
            } else {
                selection.insert(mood.persistentModelID)
            }
        } label: {
            ChipLabel(text: mood.name, inverted: isOn)
                .chipFrame(inverted: isOn)
                // Draws at 28pt, hit area padded towards 44pt (DS Chip).
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        // borderless: in a Form row a default button would fire for a tap
        // anywhere in the row, i.e. on whichever chip SwiftUI picks.
        .buttonStyle(.borderless)
        .accessibilityLabel(mood.name)
        .accessibilityIdentifier("trackForm.moodChip")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
