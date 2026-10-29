//
//  VynlButton.swift
//  vynl
//
//  Design System Button and EmptyState. Square, never a capsule: VYNL content
//  draws its own controls; only system chrome (toolbar, tab bar, alerts) keeps
//  its system shape.
//

import SwiftUI

enum VynlButtonVariant {
    /// Inverted: ink fill, bg text. One per screen or sheet.
    case primary
    /// Outlined in line-strong, ink text.
    case secondary
    /// Text only, in danger: destructive actions, which confirm first.
    case destructive
}

struct VynlButtonStyle: ButtonStyle {
    var variant: VynlButtonVariant = .primary
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, variant == .destructive ? 0 : 24)
            .frame(maxWidth: fullWidth && variant != .destructive ? .infinity : nil,
                   minHeight: variant == .primary ? 52 : 48)
            .background(background(pressed: configuration.isPressed))
            .overlay {
                if variant == .secondary {
                    Rectangle().strokeBorder(Palette.lineStrong, lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch variant {
        case .primary: Palette.onInvert
        case .secondary: Palette.ink
        case .destructive: Palette.danger
        }
    }

    /// Pressed moves one layer lighter, never darker.
    @ViewBuilder private func background(pressed: Bool) -> some View {
        switch variant {
        case .primary: pressed ? Palette.inkMuted : Palette.invert
        case .secondary: pressed ? Palette.surface2 : Color.clear
        case .destructive: Color.clear
        }
    }
}

extension ButtonStyle where Self == VynlButtonStyle {
    static var vynlPrimary: VynlButtonStyle { VynlButtonStyle(variant: .primary) }
    static var vynlSecondary: VynlButtonStyle { VynlButtonStyle(variant: .secondary) }
    static var vynlDestructive: VynlButtonStyle { VynlButtonStyle(variant: .destructive) }
}

/// Design System EmptyState as drawn on the canvas ("Collection · empty",
/// "Collection · no matches", 28.10): centred, an illustration, an optional mono
/// kicker, a 28pt heavy title, one muted sentence, full-width actions.
struct VynlEmptyState<Illustration: View, Actions: View>: View {
    var kicker: String? = nil
    let title: String
    let message: String
    @ViewBuilder var illustration: () -> Illustration
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 16) {
            illustration()
                .padding(.bottom, 16)
                .accessibilityHidden(true)
            if let kicker {
                Text(kicker.uppercased())
                    .font(.system(size: 12, weight: .bold).monospaced())
                    .tracking(1)
                    .foregroundStyle(Palette.inkDim)
            }
            Text(title)
                .font(.system(size: 28, weight: .heavy))
                .tracking(-0.3)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.system(size: 15))
                .lineSpacing(3)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) { actions() }
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        // A little above the middle, as on the canvas.
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The empty collection's picture: an empty die-cut sleeve outline with a faint
/// grooved record behind it, peeking out to the right.
struct EmptySleeveArt: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // The record: outline in `line`, grooves every 6pt at 35%.
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var r: CGFloat = 6
                while r < size.width / 2 - 2 {
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                               with: .color(Palette.line.opacity(0.35)), lineWidth: 1)
                    r += 6
                }
                ctx.stroke(Path(ellipseIn: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)),
                           with: .color(Palette.line), lineWidth: 2)
            }
            .frame(width: 184, height: 184)
            .offset(x: 72, y: 8)

            // The sleeve: background fill with the hole punched out, outlined.
            ZStack {
                Rectangle()
                    .fill(Palette.bg)
                    .overlay(Rectangle().strokeBorder(Palette.lineStrong, lineWidth: 2))
                    .mask {
                        Rectangle()
                            .overlay(Circle().frame(width: 60, height: 60).blendMode(.destinationOut))
                            .compositingGroup()
                    }
                    .shadow(color: .black.opacity(0.6), radius: 18, y: 18)
                Circle()
                    .strokeBorder(Palette.lineStrong, lineWidth: 2)
                    .frame(width: 64, height: 64)
            }
            .frame(width: 200, height: 200)
        }
        .frame(width: 200, height: 200, alignment: .topLeading)
    }
}
