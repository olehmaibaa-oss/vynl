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
//  RecordDisc is the record itself, for the release screen and the record sheet.
//

import SwiftUI

struct SleeveView: View {
    let artist: String
    let title: String
    var cover: Data?
    var coverColor: String?
    var labelImage: Data? = nil
    var dieCut = true
    var plaques = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            // A real label (COV-1) is cut at CoverArt.labelRatio of the square, so
            // the hole opens to exactly that circle and the label sits 1:1 with
            // the photo around it. Otherwise the drawn label, a little larger
            // than the hole (PO, 29.10: the hole was smaller than the photo's label).
            let realLabel = cover != nil && labelImage != nil
            let hole = realLabel ? side * CoverArt.labelRatio / 2 : side * 0.153
            ZStack(alignment: .topLeading) {
                if dieCut {
                    LabelDisc(color: labelColor, side: realLabel ? hole * 2 : hole * 2.35, showsText: false,
                              image: realLabel ? labelImage : nil)
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
        // COV-1: "image+label" when the photo also gave the real label.
        .accessibilityValue(cover == nil ? "placeholder" : (labelImage == nil ? "image" : "image+label"))
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
/// (surface or ink), (seed >> 1) % 4 the pattern. No circles: the die-cut is
/// the only circle on a sleeve, anything round around it reads as a second
/// record (design review 28.10). Monochrome, so real covers stay the only
/// colour in a grid.
struct GeneratedSleeve: View {
    let seed: UInt32

    enum Pattern: Int, CaseIterable { case bars, lines, diagonal, split }

    static func pattern(for seed: UInt32) -> Pattern {
        Pattern(rawValue: Int((seed >> 1) % 4))!
    }

    var body: some View {
        let onInk = seed & 1 == 1
        let ground = onInk ? Palette.ink : Palette.surface
        let figure = onInk ? Palette.surface : Palette.ink
        let pattern = Self.pattern(for: seed)
        let variant = Int((seed >> 5) % 4)
        Canvas { ctx, size in
            let s = size.width
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ground))
            var path = Path()
            switch pattern {
            case .bars:
                // Vertical bars, as many gaps as bars, half a gap at the edges.
                let bars = 3 + variant
                let w = s / CGFloat(bars * 2)
                for i in 0..<bars {
                    path.addRect(CGRect(x: w / 2 + CGFloat(i) * 2 * w, y: 0, width: w, height: s))
                }
            case .lines:
                // Thin horizontal lines, a tighter rhythm than the bars.
                let lines = 12 + variant * 2
                let step = s / CGFloat(lines)
                for i in 0..<lines {
                    path.addRect(CGRect(x: 0, y: step * (CGFloat(i) + 0.3), width: s, height: step * 0.28))
                }
            case .diagonal:
                // 45° stripes, bottom-left to top-right.
                let stripes = 5 + variant
                let step = 2 * s / CGFloat(stripes)
                let w = step / 2
                for i in -(stripes / 2 + 1)...stripes {
                    let x = CGFloat(i) * step
                    path.move(to: CGPoint(x: x, y: s))
                    path.addLine(to: CGPoint(x: x + w, y: s))
                    path.addLine(to: CGPoint(x: x + w + s, y: 0))
                    path.addLine(to: CGPoint(x: x + s, y: 0))
                    path.closeSubpath()
                }
            case .split:
                // Two flat fields, the hard edge off centre (38/62), either side.
                let edge = s * (variant % 2 == 0 ? 0.38 : 0.62)
                path.addRect(variant % 2 == 0
                             ? CGRect(x: 0, y: 0, width: edge, height: s)
                             : CGRect(x: edge, y: 0, width: s - edge, height: s))
            }
            ctx.fill(path, with: .color(figure))
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
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
    /// COV-1: the real label from the photo. Drawn clipped to the circle, with
    /// our spindle hole, inner shadow and sheen on top for the same volume as
    /// the generated labels. No printed text over a real label.
    var image: Data? = nil

    var body: some View {
        ZStack {
            if let image, let ui = UIImage(data: image) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipShape(Circle())
                // Volume: a darker rim and a soft sheen, like the drawn labels.
                Circle()
                    .fill(RadialGradient(colors: [.clear, .clear, .black.opacity(0.28)],
                                         center: .center, startRadius: 0, endRadius: side / 2))
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.16), .clear, .clear],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            } else {
                Circle().fill(color)
            }
            Circle().fill(Palette.bg).frame(width: side * 0.08, height: side * 0.08)
            if showsText && image == nil {
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
    /// COV-1: the real label from the photo, if any.
    var labelImage: Data? = nil

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
                LabelDisc(color: labelColor, side: s * 0.355, labelName: labelName, image: labelImage)
                    .rotationEffect(.degrees(75))
            }
            .frame(width: s, height: s)
            .shadow(color: .black.opacity(0.65), radius: 17, y: 16)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
