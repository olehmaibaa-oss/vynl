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

/// Side chips, number chips and "Other…" for free text. Taken positions on the
/// release are muted but still pickable (duplicates were always allowed).
struct PositionPicker: View {
    @Binding var position: String
    let taken: Set<String>
    @State private var other = false
    @FocusState private var otherFocused: Bool

    private var parsed: (side: String, number: Int)? { TrackPosition.parse(position) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Position")
                Spacer()
                Text(position.isEmpty ? "—" : position)
                    .font(.system(size: 15, weight: .bold).monospaced())
                    .foregroundStyle(position.isEmpty ? Palette.inkDim : Palette.ink)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("trackForm.positionValue")

            if other {
                TextField("e.g. AA, C2a, 12", text: $position)
                    .textInputAutocapitalization(.characters)
                    .focused($otherFocused)
                    .accessibilityIdentifier("trackForm.positionField")
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(TrackPosition.sides, id: \.self) { side in
                        chip(side, on: parsed?.side == side, muted: false) {
                            position = "\(side)\(parsed?.number ?? 1)"
                        }
                        .accessibilityIdentifier("trackForm.sideChip")
                    }
                }
                FlowLayout(spacing: 6) {
                    ForEach(TrackPosition.numbers, id: \.self) { n in
                        let side = parsed?.side ?? "A"
                        let isTaken = taken.contains("\(side)\(n)")
                        chip("\(n)", on: parsed?.number == n, muted: isTaken) {
                            position = "\(side)\(n)"
                        }
                        .accessibilityValue(isTaken ? "taken" : "")
                        .accessibilityIdentifier("trackForm.numberChip")
                    }
                }
            }

            Button(other ? "Pick side and number" : "Other…") {
                other.toggle()
                if other {
                    position = ""
                    otherFocused = true
                } else if parsed == nil {
                    position = TrackPosition.nextFree(after: Array(taken))
                }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Palette.inkMuted)
            .accessibilityIdentifier("trackForm.otherPositionButton")
        }
        .padding(.vertical, 4)
        .onAppear {
            // An existing odd position opens in Other….
            if !position.isEmpty && parsed == nil { other = true }
        }
    }

    private func chip(_ text: String, on: Bool, muted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ChipLabel(text: text, inverted: on)
                .frame(minWidth: 18)
                .chipFrame(inverted: on)
                .opacity(muted && !on ? 0.4 : 1)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(text)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
