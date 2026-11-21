//
//  SplitPane.swift
//  Lifestyle · padding for the two panes of a split arrangement
//
//  Content keeps a margin from each display edge, shrinking by whatever the
//  safe area already provides (a side bar, a bar, the camera). The panes meet
//  with a 16pt gap. Values come from the safe area at runtime, never from the device.
//

import SwiftUI

struct SplitPaneInsets: Equatable {
    enum Position {
        /// Leading when side by side, top when stacked.
        case first
        /// Trailing when side by side, bottom when stacked.
        case second
    }

    /// Safe-area insets around the arrangement.
    var safeArea: EdgeInsets
    /// Partially folded: the leading margin mirrors the side bar's, so the panes match.
    var mirrorsSideBar = false

    static let margin: CGFloat = 20
    static let halfGap: CGFloat = 8

    private func outer(_ inset: CGFloat) -> CGFloat { max(Self.margin - inset, 0) }

    func padding(for position: Position, axis: Axis?) -> EdgeInsets {
        var leading = outer(safeArea.leading)
        var trailing = outer(safeArea.trailing)
        if mirrorsSideBar {
            // Whichever edge has no side bar borrows the other's inset.
            leading = max(leading, safeArea.trailing - safeArea.leading)
            trailing = max(trailing, safeArea.leading - safeArea.trailing)
        }
        var insets = EdgeInsets(top: outer(safeArea.top), leading: leading,
                                bottom: outer(safeArea.bottom), trailing: trailing)
        switch (axis ?? .horizontal, position) {
        case (.horizontal, .first): insets.trailing = Self.halfGap
        case (.horizontal, .second): insets.leading = Self.halfGap
        case (.vertical, .first): insets.bottom = Self.halfGap
        case (.vertical, .second): insets.top = Self.halfGap
        }
        return insets
    }
}

/// Applies a pane's padding once the split axis is known.
private struct SplitPanePadding: ViewModifier {
    @Environment(\.splitArrangementAxis) private var axis
    let insets: SplitPaneInsets
    let position: SplitPaneInsets.Position

    func body(content: Content) -> some View {
        content.padding(insets.padding(for: position, axis: axis))
    }
}

extension View {
    func splitPanePadding(_ insets: SplitPaneInsets, position: SplitPaneInsets.Position) -> some View {
        modifier(SplitPanePadding(insets: insets, position: position))
    }
}
