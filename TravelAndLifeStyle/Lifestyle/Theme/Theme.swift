//
//  Theme.swift
//  Lifestyle · design tokens
//
//  Every colour, type style, radius and material used by the Lifestyle feature
//  lives here (Day 1 spec, section 3). Views never use raw hex values.
//

import SwiftUI
import CoreText
import UIKit

enum Theme {

    // MARK: - Colours

    enum Colors {
        static let ink = Color(hex: 0x141414)          // primary text
        static let ink2 = Color(hex: 0x3B3331)         // secondary text, icons
        static let muted = Color(hex: 0x665E5C)        // tertiary text, placeholders
        static let background = Color(hex: 0xF4F0ED)   // page
        static let red = Color(hex: 0xD71E28)          // primary CTA, brand tile
        static let purple = Color(hex: 0x5A469B)       // links, Concierge, secondary CTA
        static let purplePressed = Color(hex: 0x46348D)
        static let purple2 = Color(hex: 0x6048AD)      // selected chips, focus
        static let yellow = Color(hex: 0xFFCD41)       // points coin
        static let green = Color(hex: 0x026F43)        // booked status
        static let mint = Color(hex: 0xE5FAF3)
        static let magenta = Color(hex: 0xC440A4)      // Events tile
        static let amber = Color(hex: 0x5C3A00)        // text on yellow
        static let white = Color.white

        static let hairline = ink.opacity(0.10)
        static let heroScrim = ink.opacity(0.26)

        // Ambient background
        static let backgroundTop = Color(hex: 0xF7F3F0)
        static let backgroundBottom = Color(hex: 0xF0EAE5)
        static let facetLight = white.opacity(0.85)
        static let facetShade = Color(hex: 0xE3DBD4).opacity(0.80)
        static let glowYellow = yellow.opacity(0.50)
        static let glowRed = red.opacity(0.20)
        static let glowPurple = purple2.opacity(0.34)
        static let glowMagenta = Color(hex: 0x962B7E).opacity(0.20)

        // Surfaces. Cards, panels and tags are glass: a blur of what is behind
        // them, a white tint, and an edge that catches the light.
        static let cardFill = white.opacity(0.56)
        static let cardBorder = white.opacity(0.95)
        static let cardShadow = ink2.opacity(0.10)
        /// Edge of a glass surface, from the lit top leading corner round to the far one.
        static let glassEdge: [Color] = [white, white.opacity(0.35), white.opacity(0.80)]
        /// Light falling across the top of a glass surface.
        static let glassSheen: [Color] = [white.opacity(0.42), white.opacity(0)]
        static let glassFill = white.opacity(0.66)
        /// Over a bright image, where more of it can show through.
        static let glassFillLight = white.opacity(0.42)
        static let glassShadow = ink2.opacity(0.18)
        static let frostFill = white.opacity(0.62)
        static let frostFillLight = white.opacity(0.46)
        /// Read from a distance (tabletop): closer to solid.
        static let frostFillStrong = white.opacity(0.78)
        static let frostShadow = ink.opacity(0.18)
        static let panelFill = white.opacity(0.70)
        static let panelShadow = ink2.opacity(0.10)
        static let imageTagFill = white.opacity(0.52)
        static let sheen = white.opacity(0.75)

        // Controls
        static let chipFill = white.opacity(0.78)
        static let chipBorder = ink2.opacity(0.30)
        static let chipSelectedFill = purple2.opacity(0.12)
        static let promptChipFill = white.opacity(0.82)
        static let outlineButtonFill = white.opacity(0.75)
        static let reasonFill = purple.opacity(0.08)
        static let purpleShadow = purple.opacity(0.26)
        static let redShadow = red.opacity(0.28)
        static let bubbleShadow = purple.opacity(0.22)

        // Fargo assistant icon (from the retail app)
        static let fargoPurple = Color(hex: 0x69428E)   // top trailing, measured from the app
        static let fargoMagenta = Color(hex: 0x962B7E)  // bottom leading
        static let fargoViolet = Color(hex: 0x7F3787)   // between the two
        static let fargoShadow = fargoPurple.opacity(0.28)
        /// The light around the Fargo Concierge box: purple into magenta, with one warm glint.
        static let aura: [Color] = [purple2, magenta, yellow, magenta, purple2, fargoPurple, purple2]

        // Tints behind icons
        static let tintRed = red.opacity(0.10)
        static let tintPurple = purple.opacity(0.12)
        static let tintGreen = green.opacity(0.10)
        static let tintNeutral = ink2.opacity(0.08)
        static let tintYellow = yellow.opacity(0.40)
        static let tintMagenta = magenta.opacity(0.12)
        static let tintAmber = yellow.opacity(0.45)
        static let statusIdleFill = ink2.opacity(0.06)

        // Day 2 · booking flow
        static let star = Color(hex: 0xB07A00)
        static let progressTrack = ink2.opacity(0.14)
        static let stepperFill = ink2.opacity(0.08)
        static let segmentTrack = ink2.opacity(0.09)
        static let segmentShadow = ink2.opacity(0.16)
        static let segmentDisabled = ink2.opacity(0.40)
        static let hotelCardFill = white.opacity(0.82)
        static let radioIdle = ink2.opacity(0.5)
        static let disabledFill = ink2.opacity(0.10)
        static let disabledText = ink2.opacity(0.55)
        static let sliderTrack = ink2.opacity(0.15)
        static let splitTrack = purple.opacity(0.15)
        static let dashedSlot = purple2.opacity(0.35)
        static let pageDotIdle = white.opacity(0.6)
        static let spinnerTrack = purple2.opacity(0.25)
        static let waitRing = ink2.opacity(0.25)
        static let scrim = ink.opacity(0.28)
        static let busyVeil = background.opacity(0.55)
        static let noticeFill = Color(hex: 0xFFF9E6).opacity(0.90)
        static let noticeBorder = yellow.opacity(0.7)
        static let noticeIcon = yellow.opacity(0.5)
        static let successFill = mint.opacity(0.92)
        static let successBorder = green.opacity(0.2)
        static let dangerFill = Color(hex: 0xFFF0F0).opacity(0.92)
        static let dangerBorder = red.opacity(0.25)
        static let dangerIcon = red.opacity(0.12)
        static let confirmShadow = green.opacity(0.3)
        static let sheetFill = white.opacity(0.82)

        // Day 3 · reserve a table
        static let slotSelectedShadow = purple2.opacity(0.30)
        static let slotFill = white.opacity(0.86)
        static let slotSoldOutFill = ink2.opacity(0.06)
        static let slotSoldOutText = ink2.opacity(0.45)
        static let lowStock = Color(hex: 0x8A5A00)     // "2 tables left"
        static let fieldFill = white.opacity(0.85)
        static let slotBorder = ink2.opacity(0.24)
        static let fieldBorder = ink2.opacity(0.30)
        static let checkboxBorder = ink2.opacity(0.50)

        // Day 4 · itinerary (opaque tints, so the rail doesn't show through)
        static let railPurple = Color(hex: 0xECE8F5)
        static let railRed = Color(hex: 0xFBE4E5)
        static let railAmber = Color(hex: 0xFFEDBE)
        static let railNeutral = Color(hex: 0xEDEAE8)
        static let railHalo = backgroundTop.opacity(0.9)
        static let railLine = ink2.opacity(0.14)
        static let indicatorIdleText = ink2.opacity(0.45)
        static let indicatorIdleNote = ink2.opacity(0.50)
        static let heroFade = ink.opacity(0.35)

        // Day 5 · travel profile
        static let becauseFill = purple.opacity(0.10)
        static let lockedFill = ink2.opacity(0.07)
        static let savingFill = ink2.opacity(0.08)

        // Skeletons
        static let shimmerBase = ink2.opacity(0.07)
        static let shimmerPeak = ink2.opacity(0.17)

        // Card art (Autograph Journey placeholder)
        static let cardArt: [Color] = [Color(hex: 0x2B2D42), Color(hex: 0x4A3F6B), Color(hex: 0x1C1B2E)]
        static let cardChip: [Color] = [Color(hex: 0xE9D9A6), Color(hex: 0xBFA25E)]
        static let cardStripe = white.opacity(0.5)
    }

    // MARK: - Radii

    enum Radius {
        static let card: CGFloat = 20
        static let tile: CGFloat = 18
        static let heroPane: CGFloat = 24
        static let heroBleed: CGFloat = 32
        static let thumbnail: CGFloat = 12
        static let thumbnailLarge: CGFloat = 14
        static let statusTile: CGFloat = 12
        static let bubble: CGFloat = 20
        static let bubbleTail: CGFloat = 6
        static let groupCard: CGFloat = 22
        static let note: CGFloat = 18
        static let cardArt: CGFloat = 6
    }

    // MARK: - Sizes

    enum Size {
        static let touch: CGFloat = 44
        static let pill: CGFloat = 44
        /// System bar button and its margin, for content that shares the bar's row.
        static let barButton: CGFloat = 44
        static let barMargin: CGFloat = 16
        static let searchBox: CGFloat = 56
        static let conciergeBox: CGFloat = 54
        static let primaryButton: CGFloat = 48
        static let logoTile: CGFloat = 30
        static let coinLarge: CGFloat = 28
        static let coin: CGFloat = 26
        static let iconCircle: CGFloat = 36
        static let noteIcon: CGFloat = 44
        static let avatar: CGFloat = 28
        static let planThumbnail: CGFloat = 56
        static let pickThumbnail: CGFloat = 72
        static let statusTile: CGFloat = 52
        static let imageTag: CGFloat = 26
        static let tabUnderline: CGFloat = 3
        static let border: CGFloat = 1
        static let controlBorder: CGFloat = 1.5
    }

    // MARK: - Motion

    enum Motion {
        static let rise = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.8)
        static let riseOffset: CGFloat = 12
        static let riseOpacity: Double = 0.55
        static let stagger: Double = 0.15
        static let select = Animation.easeInOut(duration: 0.25)
        static let press = Animation.easeOut(duration: 0.2)
        static let pressScale: CGFloat = 0.97
        static let sheenPeriod: Double = 6
        static let shimmerPeriod: Double = 1.5
        static let driftPeriods: [Double] = [14, 18, 23, 27]
        /// Fargo Concierge box: degrees per second its ring turns, and where it starts.
        static let auraSpeed: Double = 40
        static let auraStart: Double = 205
        /// How long the question and each example request stay, and how one gives way to the next.
        static let questionPeriod: Double = 4.2
        static let examplePeriod: Double = 2.6
        static let example = Animation.smooth(duration: 0.6)
    }
}

// MARK: - Gradients

extension Theme {
    /// The edge of a glass surface: bright where the light lands, fainter across from it.
    static let glassEdge = LinearGradient(colors: Colors.glassEdge, startPoint: .topLeading, endPoint: .bottomTrailing)
    /// Light across the top of a glass surface, gone by its middle.
    static let glassSheen = LinearGradient(colors: Colors.glassSheen, startPoint: .top, endPoint: .center)
}

// MARK: - Typography

extension Theme {

    /// "Wells Fargo Sans" in the retail app; the designs fall back to Source Sans 3,
    /// which ships with this POC. Add the brand font files to the bundle and list
    /// their PostScript names first in `families` to switch over.
    enum Fonts {
        struct Family {
            let regular: String
            let semibold: String
        }

        static let families: [Family] = [
            Family(regular: "WellsFargoSans-Regular", semibold: "WellsFargoSans-SemiBold"),
            Family(regular: "SourceSans3-Regular", semibold: "SourceSans3-Semibold"),
        ]

        private static let bundledFiles = ["SourceSans3-Regular", "SourceSans3-Semibold"]

        /// Registers the bundled fonts once and picks the first family that resolves.
        private static let resolved: Family? = {
            for file in bundledFiles {
                if let url = Bundle.main.url(forResource: file, withExtension: "ttf") {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
            return families.first { UIFont(name: $0.regular, size: 12) != nil && UIFont(name: $0.semibold, size: 12) != nil }
        }()

        static func font(size: CGFloat, semibold: Bool, relativeTo style: Font.TextStyle) -> Font {
            guard let family = resolved else {
                return .system(size: size, weight: semibold ? .semibold : .regular)
            }
            return .custom(semibold ? family.semibold : family.regular, size: size, relativeTo: style)
        }
    }

    struct TextStyle {
        let size: CGFloat
        let lineHeight: CGFloat
        let semibold: Bool
        let relativeTo: Font.TextStyle
        var tracking: CGFloat = 0

        var font: Font { Fonts.font(size: size, semibold: semibold, relativeTo: relativeTo) }

        static let largeTitle = TextStyle(size: 30, lineHeight: 36, semibold: false, relativeTo: .largeTitle)
        static let title1 = TextStyle(size: 26, lineHeight: 32, semibold: false, relativeTo: .title)
        static let section = TextStyle(size: 20, lineHeight: 25, semibold: true, relativeTo: .title3)
        static let cardTitle = TextStyle(size: 19, lineHeight: 24, semibold: true, relativeTo: .title3)
        static let headline = TextStyle(size: 17, lineHeight: 22, semibold: true, relativeTo: .headline)
        static let body = TextStyle(size: 16, lineHeight: 22, semibold: false, relativeTo: .body)
        static let bodyEmphasis = TextStyle(size: 16, lineHeight: 22, semibold: true, relativeTo: .body)
        static let subhead = TextStyle(size: 15, lineHeight: 20, semibold: false, relativeTo: .subheadline)
        static let subheadEmphasis = TextStyle(size: 15, lineHeight: 20, semibold: true, relativeTo: .subheadline)
        static let footnote = TextStyle(size: 13, lineHeight: 18, semibold: false, relativeTo: .footnote)
        static let footnoteEmphasis = TextStyle(size: 13, lineHeight: 18, semibold: true, relativeTo: .footnote)
        /// Caps label, tracking 0.08em.
        static let caps = TextStyle(size: 12, lineHeight: 16, semibold: true, relativeTo: .caption, tracking: 0.96)
        /// Caps label, tracking 0.06em.
        static let capsTight = TextStyle(size: 12, lineHeight: 16, semibold: true, relativeTo: .caption, tracking: 0.72)
        static let statusLabel = TextStyle(size: 12, lineHeight: 16, semibold: true, relativeTo: .caption)
        static let title2 = TextStyle(size: 22, lineHeight: 28, semibold: true, relativeTo: .title2)
        /// Tabletop: the time of what's next, read from across a table.
        static let display = TextStyle(size: 52, lineHeight: 56, semibold: true, relativeTo: .largeTitle)
        /// Confirmation number, tracking 0.02em.
        static let code = TextStyle(size: 19, lineHeight: 24, semibold: true, relativeTo: .title3, tracking: 0.38)
        /// Trip title beside a confirmation.
        static let paneTitle = TextStyle(size: 22, lineHeight: 28, semibold: false, relativeTo: .title2)
        /// Stay / Dining indicator label.
        static let indicator = TextStyle(size: 14, lineHeight: 18, semibold: true, relativeTo: .footnote)
        /// Small chip text: "Your airline".
        static let chipSmall = TextStyle(size: 12, lineHeight: 16, semibold: true, relativeTo: .caption)
        /// Itinerary day header, tracking 0.04em.
        static let dayHeader = TextStyle(size: 13, lineHeight: 18, semibold: true, relativeTo: .footnote, tracking: 0.52)
    }
}

extension View {
    /// Applies a Lifestyle type style (font, line height, tracking) and an optional colour.
    func textStyle(_ style: Theme.TextStyle, color: Color = Theme.Colors.ink) -> some View {
        self
            .font(style.font)
            .lineHeight(.multiple(factor: style.lineHeight / style.size))
            .tracking(style.tracking)
            .foregroundStyle(color)
    }
}

// MARK: - Materials

extension View {

    /// Glass card: blurred backdrop, white tint, lit edge, soft shadow.
    func cardSurface(radius: CGFloat = Theme.Radius.card) -> some View {
        cardSurface(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Glass card in any shape (chat bubbles have one tighter corner).
    func cardSurface(in shape: some InsettableShape) -> some View {
        self
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay { shape.fill(Theme.Colors.cardFill) }
                    .overlay { shape.fill(Theme.glassSheen) }
            }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Theme.glassEdge, lineWidth: Theme.Size.border) }
            .contentShape(shape)
            // Outside the clip, so the card lifts off the page.
            .background {
                shape
                    .fill(Theme.Colors.cardShadow)
                    .blur(radius: 9)
                    .offset(y: 6)
                    .padding(.horizontal, 6)
            }
    }

    /// Softer panel used for the trip brief on the open display.
    func panelSurface(radius: CGFloat = Theme.Radius.card) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay { shape.fill(Theme.Colors.panelFill) }
                    .shadow(color: Theme.Colors.panelShadow, radius: 15, x: 0, y: 10)
            }
            .overlay { shape.strokeBorder(Theme.glassEdge, lineWidth: Theme.Size.border) }
    }

    /// Floating control (header pills, search, composer): Liquid Glass.
    func floatingGlass(in shape: some Shape = Capsule(), tint: Color = Theme.Colors.glassFill,
                       interactive: Bool = false) -> some View {
        self
            .glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
    }

    /// Frost panel over imagery (hero value panel).
    func frostSurface(radius: CGFloat = Theme.Radius.card, tint: Color = Theme.Colors.frostFill) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay { shape.fill(tint) }
                    .overlay { shape.fill(Theme.glassSheen) }
                    .shadow(color: Theme.Colors.frostShadow, radius: 12, x: 0, y: 8)
            }
            .overlay { shape.strokeBorder(Theme.glassEdge, lineWidth: Theme.Size.border) }
            .clipShape(shape)
    }

    /// A small glass tag over an image: a date, a menu, a price.
    func glassTag(in shape: some InsettableShape = Capsule()) -> some View {
        self
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay { shape.fill(Theme.Colors.imageTagFill) }
            }
            .overlay { shape.strokeBorder(Theme.glassEdge, lineWidth: Theme.Size.border) }
    }
}

// MARK: - Button styles

/// Press feedback shared by cards, chips and tiles: scale to 0.97.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? Theme.Motion.pressScale : 1)
            .animation(Theme.Motion.press, value: configuration.isPressed)
    }
}

/// Outline purple pill: "Create profile", "Try again".
struct OutlineButtonStyle: ButtonStyle {
    var horizontalPadding: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.subheadEmphasis, color: configuration.isPressed ? Theme.Colors.purplePressed : Theme.Colors.purple)
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: Theme.Size.touch)
            .background(Theme.Colors.outlineButtonFill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(
                    configuration.isPressed ? Theme.Colors.purplePressed : Theme.Colors.purple,
                    lineWidth: Theme.Size.controlBorder)
            }
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? Theme.Motion.pressScale : 1)
            .animation(Theme.Motion.press, value: configuration.isPressed)
    }
}

/// Filled pill: purple "Show my picks", red "View rooms", "Continue". Greys out when disabled.
struct FilledButtonStyle: ButtonStyle {
    enum Kind { case purple, red }

    var kind: Kind = .purple
    var compact = false
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        FilledButtonLabel(configuration: configuration, kind: kind, compact: compact, fullWidth: fullWidth)
    }

    private struct FilledButtonLabel: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration
        let kind: Kind
        let compact: Bool
        let fullWidth: Bool

        var body: some View {
            let fill: Color = !isEnabled
                ? Theme.Colors.disabledFill
                : kind == .purple
                    ? (configuration.isPressed ? Theme.Colors.purplePressed : Theme.Colors.purple)
                    : Theme.Colors.red
            let shadow: Color = !isEnabled
                ? .clear
                : (kind == .purple ? Theme.Colors.purpleShadow : Theme.Colors.redShadow)
            configuration.label
                .textStyle(compact ? .subheadEmphasis : .headline,
                           color: isEnabled ? Theme.Colors.white : Theme.Colors.disabledText)
                .lineLimit(1)
                .padding(.horizontal, compact ? 16 : 22)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(minHeight: compact ? Theme.Size.touch : Theme.Size.primaryButton)
                .background {
                    Capsule()
                        .fill(fill)
                        .shadow(color: shadow, radius: 10, x: 0, y: 8)
                }
                .contentShape(Capsule())
                .scaleEffect(configuration.isPressed ? Theme.Motion.pressScale : 1)
                .animation(Theme.Motion.press, value: configuration.isPressed)
        }
    }
}

// MARK: - Hex

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1)
    }
}
