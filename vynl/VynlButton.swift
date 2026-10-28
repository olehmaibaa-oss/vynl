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

/// Design System EmptyState: a rule, one line, one sentence, one action.
/// Replaces ContentUnavailableView so the empty screen keeps the VYNL type.
struct VynlEmptyState<Actions: View>: View {
    var kicker: String? = nil
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(Palette.ink).frame(height: 3).accessibilityHidden(true)
            if let kicker {
                Text(kicker.uppercased())
                    .font(.system(size: 12, weight: .bold).monospaced())
                    .tracking(1)
                    .foregroundStyle(Palette.inkMuted)
            }
            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) { actions() }
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.bg)
    }
}
