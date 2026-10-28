//
//  FilterBar.swift
//  vynl
//
//  DR-8 (SCRUM-37), entry point decided 28.10: the filter bar above the tab bar
//  opens the filter sheet; its top section is Sort. Two lines in the bar: the
//  filter summary ("All records" until E3 brings filters) and
//  "N RECORDS · ARTIST A–Z". The rest of the sheet (BPM, key, mood, genre,
//  reset) is E3.
//

import SwiftUI

struct FilterBar: View {
    let count: Int
    let sort: RecordSort
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.inkMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("All records")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text("\(count) \(count == 1 ? "record" : "records") · \(sort.name)".uppercased())
                        .font(.system(size: 11, weight: .bold).monospaced())
                        .tracking(0.6)
                        .foregroundStyle(Palette.inkMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.inkMuted)
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(Palette.surface)
            .overlay(Rectangle().stroke(Palette.lineStrong, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("All records")
        .accessibilityValue("\(count) \(count == 1 ? "record" : "records"), \(sort.name)")
        .accessibilityHint("Opens sort and filters")
        .accessibilityIdentifier("filter.bar")
    }
}

/// The filter sheet; today only its Sort section. The choice applies on Apply,
/// a swipe down discards it.
struct FilterSheet: View {
    @Binding var sort: RecordSort
    @Environment(\.dismiss) private var dismiss
    @State private var pending: RecordSort

    init(sort: Binding<RecordSort>) {
        _sort = sort
        _pending = State(initialValue: sort.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SORT")
                .font(.system(size: 12, weight: .bold).monospaced())
                .tracking(0.8)
                .foregroundStyle(Palette.inkMuted)
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(RecordSort.allCases) { option in
                    let isOn = option == pending
                    Button {
                        pending = option
                    } label: {
                        ChipLabel(text: option.name, inverted: isOn).chipFrame(inverted: isOn)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(option.name)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("sort.option")
                }
            }
            Spacer(minLength: 0)
            Button("Apply") {
                sort = pending
                dismiss()
            }
            .buttonStyle(.vynlPrimary)
            .accessibilityIdentifier("filterSheet.applyButton")
        }
        .padding(16)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.bg)
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
}
