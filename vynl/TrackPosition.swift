//
//  TrackPosition.swift
//  vynl
//
//  TRK-1 (SCRUM-60): a track's position picked as side + number instead of
//  typed. Stored as before (`Track.position`, "A2"); anything that isn't one
//  side letter A–F and one digit 1–9 is "other" and stays free text.
//

import SwiftUI

enum TrackPosition {
    static let sides = ["A", "B", "C", "D", "E", "F"]
    static let numbers = Array(1...9)

    /// "A2" → ("A", 2); nil for anything else ("AA", "C2a", "12").
    static func parse(_ raw: String) -> (side: String, number: Int)? {
        let s = raw.trimmingCharacters(in: .whitespaces).uppercased()
        guard s.count == 2, let side = s.first.map(String.init), sides.contains(side),
              let number = Int(String(s.last!)), numbers.contains(number) else { return nil }
        return (side, number)
    }

    /// The next free position after the release's tracks: one past the highest
    /// number on the latest side used ("A1", "A2" → "A3"; "B1" → "B2"; none →
    /// "A1"). After 9 it moves to the next side.
    static func nextFree(after positions: [String]) -> String {
        let parsed = positions.compactMap(parse)
        guard let lastSide = parsed.map(\.side).max() else { return "A1" }
        let highest = parsed.filter { $0.side == lastSide }.map(\.number).max() ?? 0
        if highest < 9 { return "\(lastSide)\(highest + 1)" }
        if let i = sides.firstIndex(of: lastSide), i + 1 < sides.count { return "\(sides[i + 1])1" }
        return "\(lastSide)9"
    }
}


/// SCRUM-64, PO's pick (30.10, "option A" over the designer's wheel): a big
/// readout of the position, a bar of sides A–F and a bar of numbers 1–9.
/// Numbers already used on this side can't be picked (greyed, with a dot);
/// duplicates only through Other…, which takes free text.
struct PositionPicker: View {
    @Binding var position: String
    /// Position → title of the track already there (the edited track left out).
    let tracks: [String: String]
    /// The edited track's own position, nil when adding.
    let editing: String?

    @State private var other = false
    @FocusState private var otherFocused: Bool

    private var parsed: (side: String, number: Int)? { TrackPosition.parse(position) }
    private var side: String { parsed?.side ?? "A" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FieldLabel("Position")
                Spacer()
                Button(other ? "Use picker" : "Other") { toggleOther() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .underline()
                    .foregroundStyle(Palette.inkMuted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("trackForm.otherPositionButton")
            }
            .frame(height: 20)

            if other {
                otherField
            } else {
                HStack(alignment: .center, spacing: 14) {
                    Text(position.isEmpty ? "—" : position)
                        .font(.system(size: 34, weight: .black))
                        .monospacedDigit()
                        .frame(minWidth: 64, alignment: .leading)
                    Text(hint)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.inkMuted)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Position, \(position.isEmpty ? "—" : position)")
                .accessibilityIdentifier("trackForm.positionValue")

                bar(TrackPosition.sides, id: "trackForm.sideChip",
                    state: { s in (parsed?.side == s, false) },
                    pick: { s in position = "\(s)\(nextFree(on: s))" })

                bar(TrackPosition.numbers.map(String.init), id: "trackForm.numberChip",
                    state: { n in (parsed?.number == Int(n), isTaken("\(side)\(n)")) },
                    pick: { n in position = "\(side)\(n)" })
            }
        }
        .onAppear {
            // An existing odd position opens in Other….
            if !position.isEmpty && parsed == nil { other = true }
        }
    }

    private func isTaken(_ id: String) -> Bool { id != editing && tracks[id] != nil }

    /// The first free number on a side, 1 if the side is full.
    private func nextFree(on s: String) -> Int {
        (1...9).first { !isTaken("\(s)\($0)") } ?? 1
    }

    private var hint: String {
        guard let p = parsed else { return "" }
        if "\(p.side)\(p.number)" == editing { return "Current position" }
        if p.number == nextFree(on: p.side) { return "Next free on side \(p.side)" }
        return "Free spot"
    }

    /// A row of equal square cells with 1 pt `line` gaps; the picked cell
    /// inverts, a taken one is greyed on `surface-2` with a dot and disabled.
    private func bar(_ items: [String], id: String,
                     state: @escaping (String) -> (on: Bool, taken: Bool),
                     pick: @escaping (String) -> Void) -> some View {
        HStack(spacing: 1) {
            ForEach(items, id: \.self) { item in
                let st = state(item)
                Button { pick(item) } label: {
                    Text(item)
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(st.on ? Palette.onInvert : st.taken ? Palette.inkDim.opacity(0.55) : Palette.ink)
                        .background(st.on ? Palette.invert : st.taken ? Palette.surface2 : Palette.bg)
                        .overlay(alignment: .bottom) {
                            if st.taken {
                                Rectangle().fill(Palette.inkDim).frame(width: 4, height: 4).padding(.bottom, 4)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(st.taken)
                .accessibilityLabel(item)
                .accessibilityValue(st.taken ? "taken" : "")
                .accessibilityAddTraits(st.on ? .isSelected : [])
                .accessibilityIdentifier(id)
            }
        }
        .padding(1)
        .background(Palette.line)
    }

    // MARK: - Other…

    private var otherField: some View {
        let filled = !position.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(alignment: .leading, spacing: 8) {
            TextField("AA, C2a, 12…", text: $position)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($otherFocused)
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(Palette.surface2)
                .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 1.5))
                .accessibilityIdentifier("trackForm.positionField")
            Text(filled ? "For anything that isn’t side + number: AA, C2a, or 1–12."
                        : "Type a position or switch back to the picker.")
                .font(.system(size: 13))
                .foregroundStyle(filled ? Palette.inkDim : Palette.danger)
        }
    }

    private func toggleOther() {
        if other {
            other = false
            if parsed == nil || isTaken(position.uppercased()) {
                position = TrackPosition.nextFree(after: Array(tracks.keys))
            }
        } else {
            other = true
            otherFocused = true
        }
    }
}

/// The DS field label: uppercase, monospaced, `meta` size, ink-muted.
struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .tracking(1)
            .foregroundStyle(Palette.inkMuted)
    }
}
