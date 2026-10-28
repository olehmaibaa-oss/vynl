//
//  SleeveView.swift
//  vynl
//
//  DR-5 / DR-7: the record sleeve, as drawn in Collection draft v0.
//  - A square cover, full bleed, never rounded or tinted: the photo, or the
//    Design System's generated sleeve (monochrome pattern from the seed).
//  - A round die-cut in the middle; through it shows the record's label in the
//    release's label colour (coverColor, or the placeholder's seed colour).
//  - Optional plaques (title over artist, top left, hanging 8pt off the edge),
//    used where the name sits on the sleeve (form slot, stack card).
//  RecordDisc is the record itself, for the release screen and the expanded stack.
//

import SwiftUI

struct SleeveView: View {
    let artist: String
    let title: String
    var cover: Data?
    var coverColor: String?
    var dieCut = true
    var plaques = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let hole = side * 0.153
            ZStack(alignment: .topLeading) {
                if dieCut {
                    // The label under the cut, a little larger than the hole.
                    LabelDisc(color: labelColor, side: hole * 2.35, showsText: false)
                        .frame(width: side, height: side)
                }
                art(side: side)
                    .frame(width: side, height: side)
                    .clipped()
                    .mask {
                        if dieCut {
                            Rectangle()
                                .overlay(Circle().frame(width: hole * 2, height: hole * 2).blendMode(.destinationOut))
                                .compositingGroup()
                        } else {
                            Rectangle()
                        }
                    }
                if dieCut {
                    // The cut's inner shadow.
                    Circle()
                        .stroke(Color.black.opacity(0.55), lineWidth: 3)
                        .blur(radius: 2)
                        .frame(width: hole * 2, height: hole * 2)
                        .clipShape(Circle())
                        .frame(width: side, height: side)
                }
                if plaques {
                    VStack(alignment: .leading, spacing: 3) {
                        Plaque(text: title, size: side >= 200 ? 30 : 17, weight: .black)
                        Plaque(text: artist, size: side >= 200 ? 16 : 12, weight: .bold)
                    }
                    .padding(.top, side * 0.047)
                    .offset(x: -8)
                    .padding(.trailing, 30)
                }
            }
            .frame(width: side, height: side)
            .shadow(color: .black.opacity(0.6), radius: side * 0.08, y: side * 0.05)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(artist), \(title)")
        // Tests tell a photo from a placeholder by value, never by pixels.
        .accessibilityValue(cover == nil ? "placeholder" : "image")
    }

    private var labelColor: Color {
        CoverArt.labelColor(artist: artist, title: title, coverColor: cover == nil ? nil : coverColor)
    }

    @ViewBuilder private func art(side: CGFloat) -> some View {
        if let cover, let image = UIImage(data: cover) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            GeneratedSleeve(seed: CoverArt.seed(artist: artist, title: title))
        }
    }
}

/// The Design System's generated sleeve: bit 0 of the seed picks the ground
/// (surface or ink), (seed >> 1) % 3 the pattern: groove rings from a corner,
/// bars, or a disc. Monochrome, so real covers stay the only colour in a grid.
struct GeneratedSleeve: View {
    let seed: UInt32

    var body: some View {
        let onInk = seed & 1 == 1
        let ground = onInk ? Palette.ink : Palette.surface
        let figure = onInk ? Palette.surface : Palette.ink
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                ground
                switch (seed >> 1) % 3 {
                case 0:
                    // Groove rings from a corner.
                    let corner = CGPoint(x: (seed >> 3) & 1 == 0 ? 0 : s, y: (seed >> 4) & 1 == 0 ? 0 : s)
                    ForEach(0..<9, id: \.self) { i in
                        Circle()
                            .stroke(figure.opacity(0.85), lineWidth: s * 0.018)
                            .frame(width: s * (0.3 + CGFloat(i) * 0.24), height: s * (0.3 + CGFloat(i) * 0.24))
                            .position(corner)
                    }
                case 1:
                    // Bars.
                    let bars = 3 + Int((seed >> 5) % 4)
                    HStack(spacing: s / CGFloat(bars * 2)) {
                        ForEach(0..<bars, id: \.self) { _ in figure.frame(width: s / CGFloat(bars * 2)) }
                    }
                    .padding(.horizontal, s / CGFloat(bars * 4))
                default:
                    // A disc, off centre.
                    Circle().fill(figure)
                        .frame(width: s * 0.62, height: s * 0.62)
                        .position(x: s * (0.35 + Double((seed >> 6) % 30) / 100), y: s * 0.62)
                }
            }
            .frame(width: s, height: s)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Design System Plaque: black label tape that reads over any cover.
struct Plaque: View {
    let text: String
    var size: CGFloat = 16
    var weight: Font.Weight = .bold
    var inverted = false

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight))
            .tracking(size >= 24 ? -0.6 : 0)
            .lineLimit(2)
            .foregroundStyle(inverted ? Palette.onInvert : Palette.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, size >= 24 ? 3 : 2)
            .background(inverted ? Palette.invert : Palette.bg)
    }
}

/// A record label: coloured circle with a spindle hole; on the record it also
/// carries the label name and the side.
struct LabelDisc: View {
    let color: Color
    let side: CGFloat
    var showsText = true
    var labelName: String = ""

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().fill(Palette.bg).frame(width: side * 0.08, height: side * 0.08)
            if showsText {
                VStack {
                    Text(labelName.uppercased())
                        .font(.system(size: max(side * 0.082, 6), weight: .bold).monospaced())
                        .tracking(1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Text("A")
                        .font(.system(size: max(side * 0.082, 6), weight: .bold).monospaced())
                }
                .foregroundStyle(Color.black.opacity(0.72))
                .padding(.vertical, side * 0.2)
                .padding(.horizontal, side * 0.15)
            }
        }
        .frame(width: side, height: side)
    }
}

/// The record, slid out of the sleeve: black grooved vinyl with its label.
struct RecordDisc: View {
    let labelColor: Color
    var labelName: String = ""

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                Circle().fill(Color(white: 0.04))
                ForEach(0..<14, id: \.self) { i in
                    Circle()
                        .stroke(Color(white: 0.09), lineWidth: 0.6)
                        .frame(width: s * (0.5 + CGFloat(i) * 0.034), height: s * (0.5 + CGFloat(i) * 0.034))
                }
                // A soft sheen across the grooves.
                Circle()
                    .fill(AngularGradient(colors: [.clear, .white.opacity(0.14), .clear, .clear, .white.opacity(0.08), .clear],
                                          center: .center))
                LabelDisc(color: labelColor, side: s * 0.355, labelName: labelName)
                    .rotationEffect(.degrees(75))
            }
            .frame(width: s, height: s)
            .shadow(color: .black.opacity(0.65), radius: 17, y: 16)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
