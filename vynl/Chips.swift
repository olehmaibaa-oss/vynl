//
//  Chips.swift
//  vynl
//
//  Design System chips: square, `chip` type (13pt bold), `size-chip` tall,
//  outline in `line-strong`. A selected chip is inverted (ink fill, bg text).
//  FlowLayout wraps them onto as many lines as needed.
//

import SwiftUI

/// Lays children out left to right, wrapping to a new line when the width runs out.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let last = rows.count - 1
            rows[last].width += (rows[last].indices.isEmpty ? 0 : spacing) + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

/// The text of a chip in the Design System `chip` style.
struct ChipLabel: View {
    let text: String
    var inverted = false

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .tracking(0.13)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(inverted ? Palette.onInvert : Palette.ink)
    }
}

extension View {
    /// Chip frame: 28pt tall, square, outlined (or inverted when on).
    func chipFrame(inverted: Bool = false) -> some View {
        padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(inverted ? Palette.invert : Color.clear)
            .overlay(Rectangle().stroke(inverted ? Palette.invert : Palette.lineStrong, lineWidth: 1))
    }
}
