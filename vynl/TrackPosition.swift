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


/// SCRUM-64, the designer's "Track form: side tabs + number wheel" boards:
/// side tabs A–F with a track count, a five-row number wheel around the
/// picked number showing which track holds each spot, a caption, and Other…
/// for free text. Taken spots stay pickable (duplicates were always allowed).
struct PositionPicker: View {
    @Binding var position: String
    /// Position → title of the track already there (the edited track left out).
    let tracks: [String: String]
    /// The track title being typed, shown on the picked row.
    let title: String
    /// The edited track's own position ("Current position."), nil when adding.
    let editing: String?

    @State private var other = false
    @State private var dragSteps = 0
    @FocusState private var otherFocused: Bool

    private var parsed: (side: String, number: Int)? { TrackPosition.parse(position) }
    private var side: String { parsed?.side ?? "A" }
    private var number: Int { parsed?.number ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FieldLabel("Position")
                    .accessibilityLabel("Position, \(position.isEmpty ? "—" : position)")
                    .accessibilityIdentifier("trackForm.positionValue")
                Spacer()
                Button(other ? "Use picker" : "Other…") { toggleOther() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.inkMuted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("trackForm.otherPositionButton")
            }
            .frame(height: 28)

            if other {
                otherField
            } else {
                sideTabs
                wheel
                Text(caption.text)
                    .font(.system(size: 13))
                    .foregroundStyle(caption.strong ? Palette.inkMuted : Palette.inkDim)
                    .accessibilityIdentifier("trackForm.positionCaption")
            }
        }
        .onAppear {
            // An existing odd position opens in Other….
            if !position.isEmpty && parsed == nil { other = true }
        }
    }

    // MARK: - Sides

    private var sideTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(TrackPosition.sides.enumerated()), id: \.element) { i, s in
                let on = s == side
                let count = tracks.keys.filter { TrackPosition.parse($0)?.side == s }.count
                Button {
                    position = "\(s)\(nextFree(on: s))"
                } label: {
                    Text(s)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(alignment: .topTrailing) {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(on ? Palette.onInvertMuted : Palette.inkDim)
                                    .padding(.top, 4).padding(.trailing, 6)
                            }
                        }
                        .foregroundStyle(on ? Palette.onInvert : Palette.ink)
                        .background(on ? Palette.invert : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .leading) {
                    if i > 0 { Rectangle().fill(Palette.line).frame(width: 1) }
                }
                .accessibilityLabel(s)
                .accessibilityValue(count == 0 ? "" : count == 1 ? "1 track" : "\(count) tracks")
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier("trackForm.sideChip")
            }
        }
        .overlay(Rectangle().strokeBorder(Palette.line, lineWidth: 1))
    }

    /// The first free number on a side, 1 if the side is full.
    private func nextFree(on s: String) -> Int {
        (1...9).first { tracks["\(s)\($0)"] == nil } ?? 1
    }

    // MARK: - Number wheel

    private var wheel: some View {
        VStack(spacing: 0) {
            ForEach(-2...2, id: \.self) { d in
                row(number + d, distance: abs(d))
            }
        }
        .background(Palette.surface2)
        .contentShape(Rectangle())
        // Drag to turn the wheel, one row per 36 pt.
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { v in
                    let steps = Int((-v.translation.height / 36).rounded())
                    if steps != dragSteps {
                        let n = min(max(number + steps - dragSteps, 1), 9)
                        dragSteps = steps
                        position = "\(side)\(n)"
                    }
                }
                .onEnded { _ in dragSteps = 0 }
        )
    }

    @ViewBuilder
    private func row(_ n: Int, distance: Int) -> some View {
        if (1...9).contains(n) {
            let id = "\(side)\(n)"
            let owner = id == editing ? nil : tracks[id]
            let on = distance == 0
            let shownTitle = owner ?? (on ? (title.trimmingCharacters(in: .whitespaces).isEmpty ? "New track" : title) : "")
            Button {
                position = id
            } label: {
                HStack(spacing: 10) {
                    Text("\(n)")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .frame(width: 28, alignment: .leading)
                    Text(shownTitle)
                        .font(.system(size: 15, weight: on ? .bold : .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if on {
                        Text(owner != nil ? "TAKEN · \(id)" : id)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .tracking(0.5)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .foregroundStyle(on ? Palette.onInvert : owner != nil ? Palette.inkDim : Palette.ink)
                .background(on ? Palette.invert : Color.clear)
                .opacity(distance == 0 ? 1 : distance == 1 ? 0.8 : 0.45)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(n)")
            .accessibilityValue(owner != nil ? "taken" : "")
            .accessibilityHint(owner.map { "\(id), \($0)" } ?? "\(id), free")
            .accessibilityAddTraits(on ? .isSelected : [])
            .accessibilityIdentifier("trackForm.numberChip")
        } else {
            Color.clear.frame(height: 36).accessibilityHidden(true)
        }
    }

    private var caption: (text: String, strong: Bool) {
        let id = "\(side)\(number)"
        if let owner = tracks[id], id != editing {
            return ("\(id) already holds \(owner). Saving puts both tracks there.", true)
        }
        if id == editing { return ("Current position.", false) }
        if number == nextFree(on: side) { return ("Next free spot on side \(side).", false) }
        return ("Free spot.", false)
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
            if parsed == nil {
                position = TrackPosition.nextFree(after: Array(tracks.keys))
            }
        } else {
            // The designer's Other… starts from the picked spot, ready to edit.
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
