//
//  LandingComponents.swift
//  Lifestyle · profile banner, tabs, Book now
//

import SwiftUI

// MARK: - Profile banner

/// Shown only when the customer has no travel profile. Opens profile setup (Day 5).
struct ProfileBanner: View {
    var onCreate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Personalize your experience")
                    .textStyle(.subheadEmphasis)
                Text("Create your travel profile.")
                    .textStyle(.footnote, color: Theme.Colors.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button("Create profile", action: onCreate)
                .buttonStyle(OutlineButtonStyle())
        }
        .padding(.vertical, 10)
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .cardSurface()
    }
}

// MARK: - Tabs

/// Underline tabs: Travel, Entertainment, Dining, Exclusives. Switchable at any time.
struct CategoryTabBar: View {
    let tabs: [CategoryTab]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 22) {
                ForEach(tabs) { tab in
                    let isSelected = tab.id == selection
                    Button {
                        withAnimation(Theme.Motion.select) { selection = tab.id }
                    } label: {
                        Text(tab.label)
                            .textStyle(isSelected ? .bodyEmphasis : .body,
                                       color: isSelected ? Theme.Colors.ink : Theme.Colors.ink2)
                            .lineLimit(1)
                            .frame(minHeight: Theme.Size.touch)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(isSelected ? Theme.Colors.ink : .clear)
                                    .frame(height: Theme.Size.tabUnderline)
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(height: Theme.Size.border)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Categories")
    }
}

// MARK: - Book now

/// Six tiles that stay on the page, outside the tabs.
struct BookNowSection: View {
    let tiles: [BookNowTile]
    var tileHeight: CGFloat
    var onSelect: (BookNowTile) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Book now")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles) { tile in
                    Button { onSelect(tile) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            SymbolIcon(name: tile.sfSymbolHint, size: 16)
                                .foregroundStyle(tile.tint.foreground)
                                .frame(width: Theme.Size.iconCircle, height: Theme.Size.iconCircle)
                                .background(tile.tint.fill, in: Circle())
                            Spacer(minLength: 0)
                            Text(tile.label)
                                .textStyle(.subheadEmphasis)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: tileHeight, alignment: .leading)
                        .cardSurface(radius: Theme.Radius.tile)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }
}

extension BookNowTile {
    /// Icon colours per tile, from the designs.
    var tint: (fill: Color, foreground: Color) {
        switch id {
        case "hotels": (Theme.Colors.tintRed, Theme.Colors.red)
        case "flights": (Theme.Colors.tintPurple, Theme.Colors.purple)
        case "cars": (Theme.Colors.tintGreen, Theme.Colors.green)
        case "experiences": (Theme.Colors.tintYellow, Theme.Colors.amber)
        case "events": (Theme.Colors.tintMagenta, Theme.Colors.magenta)
        default: (Theme.Colors.tintNeutral, Theme.Colors.ink2)
        }
    }
}

// MARK: - Shared bits

/// Purple text link with a chevron: "See all", "Plan with Concierge", "View rooms".
struct LinkLabel: View {
    let title: String
    var chevronSize: CGFloat = 11

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                .lineLimit(1)
            SymbolIcon(name: "chevron.right", size: chevronSize, weight: .bold)
                .foregroundStyle(Theme.Colors.purple)
        }
    }
}

/// Icon in a tinted circle, used by empty, error and coming-soon cards.
struct NoteIcon<Icon: View>: View {
    var fill: Color
    var foreground: Color
    @ViewBuilder var icon: Icon

    var body: some View {
        icon
            .foregroundStyle(foreground)
            .frame(width: Theme.Size.noteIcon, height: Theme.Size.noteIcon)
            .background(fill, in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview("Landing components") {
    @Previewable @State var tab = "travel"
    let content = LifestyleContent.sample
    return ScrollView {
        VStack(spacing: 12) {
            ProfileBanner {}
            CategoryTabBar(tabs: content.tabs, selection: $tab)
            BookNowSection(tiles: content.bookNowTiles, tileHeight: 92) { _ in }
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
