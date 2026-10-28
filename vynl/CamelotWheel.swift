//
//  CamelotWheel.swift
//  vynl
//
//  DR-6 (SCRUM-35): the Design System CamelotWheel and KeyChip.
//  B ring outside, A ring inside, number n at n o'clock, 30° per segment.
//  With a key picked: it gets an ink outline, the centre shows "8A" over "Am",
//  its compatible keys (same number on the other ring, one step either way on the
//  same ring) keep their colour, everything else turns surface-2.
//

import SwiftUI

extension CamelotKey {
    /// The harmonic neighbours: same number on the other ring, ±1 on the same ring.
    var compatible: Set<CamelotKey> {
        let ring = isMinor ? "A" : "B"
        let other = isMinor ? "B" : "A"
        let prev = number == 1 ? 12 : number - 1
        let next = number == 12 ? 1 : number + 1
        return Set(["\(number)\(other)", "\(prev)\(ring)", "\(next)\(ring)"].compactMap(CamelotKey.init(rawValue:)))
    }
}

/// A key on its Camelot colour, "8A · Am". No key renders a dash.
struct KeyChip: View {
    let key: CamelotKey?

    var body: some View {
        if let key {
            Text(key.display)
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Palette.onKey)
                .padding(.horizontal, 8)
                .frame(minHeight: 24)
                .background(Palette.key(key.code))
        } else {
            Text("—").foregroundStyle(Palette.inkDim)
        }
    }
}

struct CamelotWheel: View {
    @Binding var selection: CamelotKey?
    var onPick: (CamelotKey) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outer = side / 2
            let mid = outer * 0.68
            let inner = outer * 0.38

            ZStack {
                ForEach(CamelotKey.allCases) { key in
                    let radii = key.isMinor ? (inner, mid) : (mid, outer)
                    segment(key, center: center, radii: radii)
                }
                hub(center: center, radius: inner)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Pieces

    private func segment(_ key: CamelotKey, center: CGPoint, radii: (CGFloat, CGFloat)) -> some View {
        let path = Self.sector(for: key, center: center, inner: radii.0, outer: radii.1)
        let box = path.boundingRect
        let local = path.offsetBy(dx: -box.minX, dy: -box.minY)
        let anchor = Self.point(on: key, center: center, radius: (radii.0 + radii.1) / 2)
        let isSelected = selection == key

        return Button {
            selection = key
            onPick(key)
        } label: {
            ZStack {
                local.fill(fill(for: key))
                // 2pt separators in the sheet's surface.
                local.stroke(Palette.surface, lineWidth: 2)
                if isSelected {
                    // Full 4pt ink outline (DS CamelotWheel), kept inside the
                    // segment: an 8pt stroke clipped to the sector's own shape.
                    local.stroke(Palette.ink, lineWidth: 8).clipShape(local)
                }
                Text(key.code)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(isDimmed(key) ? Palette.inkDim : Palette.onKey)
                    .position(x: anchor.x - box.minX, y: anchor.y - box.minY)
            }
            .frame(width: box.width, height: box.height)
            .contentShape(local)
        }
        .buttonStyle(.plain)
        // The picked segment is drawn last, so its neighbours never paint over
        // its outline (design review 28.10).
        .zIndex(isSelected ? 1 : 0)
        // Each segment is its own element with its own frame (the sector's box),
        // and taps land on the sector's middle, not the box's.
        .position(x: box.midX, y: box.midY)
        .accessibilityLabel(key.display)
        .accessibilityIdentifier("camelot.segment")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityActivationPoint(CGPoint(x: anchor.x - box.minX, y: anchor.y - box.minY))
    }

    private func hub(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            Circle().fill(Palette.surface)
            if let selection {
                VStack(spacing: 0) {
                    Text(selection.code)
                        .font(.system(size: 30, weight: .black))
                        .monospacedDigit()
                    Text(selection.classicName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.inkMuted)
                }
                .foregroundStyle(Palette.ink)
            }
        }
        .frame(width: radius * 2 - 4, height: radius * 2 - 4)
        .position(center)
        .accessibilityHidden(true)
    }

    private func isDimmed(_ key: CamelotKey) -> Bool {
        guard let selection else { return false }
        return key != selection && !selection.compatible.contains(key)
    }

    private func fill(for key: CamelotKey) -> Color {
        isDimmed(key) ? Palette.surface2 : Palette.key(key.code)
    }

    // MARK: - Geometry

    /// Angle of a key's centre, clockwise from 12 o'clock: n o'clock = n × 30°.
    private static func angle(of key: CamelotKey) -> Angle {
        .degrees(Double(key.number % 12) * 30 - 90)
    }

    private static func point(on key: CamelotKey, center: CGPoint, radius: CGFloat) -> CGPoint {
        let a = angle(of: key).radians
        return CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
    }

    private static func sector(for key: CamelotKey, center: CGPoint, inner: CGFloat, outer: CGFloat) -> Path {
        let mid = angle(of: key)
        let start = mid - .degrees(15), end = mid + .degrees(15)
        var p = Path()
        p.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        p.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        p.closeSubpath()
        return p
    }
}

/// The key picker screen, pushed from the track form (the form is already a sheet,
/// and the Design System allows one sheet at a time).
struct CamelotPickerView: View {
    @Binding var selection: CamelotKey?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            CamelotWheel(selection: $selection) { _ in dismiss() }
                .padding(.horizontal, 16)
            Text("Compatible keys keep their colour.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
            Spacer()
        }
        .padding(.top, 24)
        .fillBackground()
        .navigationTitle("Key")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selection != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        selection = nil
                        dismiss()
                    }
                    .accessibilityIdentifier("camelot.clearButton")
                }
            }
        }
    }
}
