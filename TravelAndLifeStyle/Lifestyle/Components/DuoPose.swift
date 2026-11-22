//
//  DuoPose.swift
//  Lifestyle · iPhone Duo: what changes with the device's pose
//
//  The layouts themselves follow size classes and the split arrangement. This
//  file holds what is specific to the hinge: the hint on the cover display,
//  and a launch argument to show a pose on a simulator that can't be folded
//  by hand.
//

import SwiftUI

// MARK: - Open for more

/// On iPhone Duo's cover display, on a screen where the inner display shows
/// more: says what opening the device adds. It goes once the device has been
/// opened or the hint is closed, and comes back the next time the app starts.
struct OpenForMoreHint: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    /// What the inner display adds here: "See your picks beside the chat."
    let text: String

    /// The hinge says when the device is closed. Where it reports nothing,
    /// one column with a side bar is the cover display.
    private var isOnCoverDisplay: Bool {
        if store.pose != nil { return store.isOnCoverDisplay }
        return horizontalSizeClass == .compact && toolbarVerticalEdge != nil
    }

    var body: some View {
        if isOnCoverDisplay && !store.openHintIsDone {
            HStack(spacing: 10) {
                SymbolIcon(name: "rectangle.split.2x1", size: 16)
                    .foregroundStyle(Theme.Colors.purple)
                    .frame(width: Theme.Size.iconCircle, height: Theme.Size.iconCircle)
                    .background(Theme.Colors.tintPurple, in: Circle())

                VStack(alignment: .leading, spacing: 0) {
                    Text("Open for side by side")
                        .textStyle(.subheadEmphasis)
                    Text(text)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                Button {
                    withAnimation(Theme.Motion.select) { store.openHintIsDone = true }
                } label: {
                    SymbolIcon(name: "xmark", size: 12, weight: .bold)
                        .foregroundStyle(Theme.Colors.ink2)
                        .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Dismiss")
            }
            .padding(.leading, 10)
            .padding(.vertical, 4)
            .floatingGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .riseIn()
            .transition(.opacity)
        }
    }
}

// MARK: - Demo

/// `-lifestylePose closed|folded`: shows what a pose changes on a simulator
/// that is in another one.
/// - `closed`: the cover display's hint, on any compact-width device.
/// - `folded`: half folded. Side by side that is the book pose; stacked
///   (inner display in portrait, or iPad in portrait) it is tabletop.
enum DemoPose: String {
    case closed, folded

    static var launch: DemoPose? {
        UserDefaults.standard.string(forKey: "lifestylePose").flatMap(DemoPose.init)
    }
}

extension LifestyleStore {
    func show(_ pose: DemoPose) {
        switch pose {
        case .closed:
            poseOverride = .closed
        case .folded:
            poseOverride = .partiallyOpen
        }
    }
}

#Preview("Open for more") {
    let store = LifestyleStore.preview()
    store.poseOverride = .closed
    return VStack {
        OpenForMoreHint(text: "See your picks beside the chat.")
        Spacer()
    }
    .padding(16)
    .background(AmbientBackground())
    .environment(store)
}
