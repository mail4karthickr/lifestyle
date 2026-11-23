//
//  FlowComponents.swift
//  Lifestyle · shared pieces of the booking flow (Day 2 spec, section 3)
//

import SwiftUI

// MARK: - Page containers

/// Compact width: one decision per screen. Scrolling content with a sticky
/// action bar at the bottom. Margins come from the safe area, so an edge that a
/// side bar already clears gets no extra margin.
struct FlowPage<Content: View, Bar: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content
    @ViewBuilder var bar: Bar

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let margin = LandingMetrics.margin(forWidth: proxy.size.width + insets.leading + insets.trailing)
            let leading = max(margin - insets.leading, 0)
            let trailing = max(margin - insets.trailing, 0)

            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, leading)
                .padding(.trailing, trailing)
                // Under a top bar the page starts 12pt below it; with a side bar it starts at the margin.
                .padding(.top, toolbarVerticalEdge == nil ? 12 : max(margin - insets.top, 0))
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if Bar.self != EmptyView.self {
                    bar
                        .padding(.leading, leading)
                        .padding(.trailing, trailing)
                        .padding(.bottom, insets.bottom > 0 ? 0 : 12)
                }
            }
        }
    }
}

extension FlowPage where Bar == EmptyView {
    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing, content: content, bar: { EmptyView() })
    }
}

/// Regular width: a split arrangement that pairs the decision with the next
/// level of detail. The system keeps both panes out of the fold.
struct FlowSplit<Leading: View, Trailing: View>: View {
    var leadingRatio: CGFloat = 0.53
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        GeometryReader { proxy in
            let insets = SplitPaneInsets(safeArea: proxy.safeAreaInsets)

            ArrangementView {
                leading
                    .environment(\.flowPane, FlowPaneContext(insets: insets, position: .first))
                    .splitArrangementLayoutRatio(idealHorizontal: leadingRatio, idealVertical: 0.5)
            } secondary: {
                trailing
                    .environment(\.flowPane, FlowPaneContext(insets: insets, position: .second))
            }
            .arrangementViewStyle(.split)
        }
    }
}

struct FlowPaneContext {
    var insets = SplitPaneInsets(safeArea: EdgeInsets())
    var position: SplitPaneInsets.Position = .first
}

extension EnvironmentValues {
    @Entry var flowPane = FlowPaneContext()
}

/// One pane of a `FlowSplit`: scrolls when its content doesn't fit, with an
/// optional footer pinned to the bottom.
struct FlowPane<Content: View, Footer: View>: View {
    @Environment(\.flowPane) private var pane
    @Environment(\.splitArrangementAxis) private var axis
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        let padding = pane.insets.padding(for: pane.position, axis: axis)
        let hasFooter = Footer.self != EmptyView.self

        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, padding.top)
            .padding(.leading, padding.leading)
            .padding(.trailing, padding.trailing)
            .padding(.bottom, hasFooter ? 12 : padding.bottom)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if hasFooter {
                footer
                    .padding(.leading, padding.leading)
                    .padding(.trailing, padding.trailing)
                    .padding(.bottom, padding.bottom)
            }
        }
    }
}

extension FlowPane where Footer == EmptyView {
    init(spacing: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing, content: content, footer: { EmptyView() })
    }
}

/// Frosted panel that groups a pane's summary: "Your stay", "Order summary".
struct SummaryPanel<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelSurface()
    }
}

// MARK: - Toolbar

private struct FlowToolbar: ViewModifier {
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let title: String
    /// When set, the bar shows the title over this line (tabletop: the step
    /// header is not in the content). Otherwise the title is in the content.
    let barSubtitle: String?
    /// Shows the title in a top bar. A side bar has no row for it.
    let showsBarTitle: Bool

    func body(content: Content) -> some View {
        let barTitle = barSubtitle != nil || (showsBarTitle && toolbarVerticalEdge == nil)

        // Back comes from the navigation stack and is the only control: every
        // page leaves the way it was entered.
        content
            .background { AmbientBackground() }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: barTitle ? nil : .title)
            .toolbar {
                if barTitle {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title)
                                .textStyle(.headline)
                            if let barSubtitle {
                                Text(barSubtitle)
                                    .textStyle(.footnote, color: Theme.Colors.muted)
                            }
                        }
                        .lineLimit(1)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                    }
                }
            }
    }
}

extension View {
    /// Background and title shared by every step of a flow.
    func flowChrome(title: String, barSubtitle: String? = nil, showsBarTitle: Bool = false) -> some View {
        modifier(FlowToolbar(title: title, barSubtitle: barSubtitle, showsBarTitle: showsBarTitle))
    }
}

// MARK: - Progress

/// A segmented progress bar with a caption, then the step's title and an
/// optional subtitle. `trailing` sits at the end of the title row (a save pill).
struct StepHeader<Trailing: View>: View {
    let segments: Int
    /// How many segments are purple (done or current).
    let filled: Int
    let caption: String
    /// What VoiceOver reads for the bar.
    var spokenCaption: String?
    /// Nil when the screen shows its own headline (a confirmation).
    var title: String?
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(1...max(segments, 1), id: \.self) { index in
                        Capsule()
                            .fill(index <= filled ? Theme.Colors.purple2 : Theme.Colors.progressTrack)
                            .frame(height: 4)
                    }
                }
                Text(caption)
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenCaption ?? caption)

            if let title {
                HStack(spacing: 8) {
                    Text(title)
                        .textStyle(.title1)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    trailing
                }
            }
            if let subtitle {
                Text(subtitle)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
        }
    }
}

extension StepHeader where Trailing == EmptyView {
    init(segments: Int, filled: Int, caption: String, spokenCaption: String? = nil,
         title: String? = nil, subtitle: String? = nil) {
        self.init(segments: segments, filled: filled, caption: caption, spokenCaption: spokenCaption,
                  title: title, subtitle: subtitle, trailing: { EmptyView() })
    }

    /// Book a hotel: Hotel, Room, Pay, Review, Done.
    init(step: Int, title: String? = nil, subtitle: String? = nil) {
        let names = ["Hotel", "Room", "Pay", "Review", "Done"]
        self.init(segments: names.count, filled: step,
                  caption: "Step \(step) of \(names.count) · \(names[step - 1])",
                  spokenCaption: "Step \(step) of \(names.count), \(names[step - 1])",
                  title: title, subtitle: subtitle)
    }

    /// Reserve a table: Table, Details, Pay, Review; "Reserved" once it is done.
    static func dining(step: Int, title: String? = nil) -> StepHeader {
        let names = ["Table", "Details", "Pay", "Review"]
        guard step <= names.count else {
            return StepHeader(segments: names.count, filled: names.count, caption: "Reserved", title: title)
        }
        return StepHeader(segments: names.count, filled: step,
                          caption: "Step \(step) of \(names.count) · \(names[step - 1])",
                          spokenCaption: "Step \(step) of \(names.count), \(names[step - 1])",
                          title: title)
    }
}

// MARK: - Action bar

/// Sticky glass bar: summary on the left, primary button on the right.
struct ActionBar<Summary: View>: View {
    let buttonTitle: String
    var isEnabled = true
    /// Read by VoiceOver when the button is disabled.
    var disabledReason: String?
    var action: () -> Void
    @ViewBuilder var summary: Summary

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                summary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            // The button keeps its full title; the summary gives way first.
            Button(buttonTitle, action: action)
                .buttonStyle(FilledButtonStyle(kind: .red, fullWidth: false))
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .disabled(!isEnabled)
                .accessibilityHint(isEnabled ? "" : (disabledReason ?? ""))
        }
        .padding(.vertical, 10)
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .frame(minHeight: 68)
        .floatingGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - Small pieces

/// Pill tag: "From your trip", "Free cancellation", "Just added", "Confirmed".
struct TagPill: View {
    enum Tone { case purple, mint, image }

    let text: String
    var tone: Tone = .purple
    var symbol: String?

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                SymbolIcon(name: symbol, size: 11, weight: .bold)
            }
            Text(text)
                .textStyle(.footnoteEmphasis, color: foreground)
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .frame(minHeight: Theme.Size.imageTag)
        .background {
            if tone == .image {
                // Over a photo: glass, so the tag reads on any image.
                Color.clear.glassTag()
            } else {
                Capsule().fill(fill)
            }
        }
    }

    private var foreground: Color {
        switch tone {
        case .purple: Theme.Colors.purple
        case .mint: Theme.Colors.green
        case .image: Theme.Colors.ink
        }
    }

    private var fill: Color {
        switch tone {
        case .purple: Theme.Colors.tintPurple
        case .mint: Theme.Colors.mint
        case .image: .clear
        }
    }
}

/// Dates and party for the stay, with a tag or a link on the right.
struct TripChip<Trailing: View>: View {
    let search: HotelSearch
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            SymbolIcon(name: "calendar", size: 16)
                .foregroundStyle(Theme.Colors.ink2)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(search.datesText)
                    .textStyle(.subheadEmphasis)
                Text(search.summaryText)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            trailing
        }
        .padding(.vertical, 8)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .frame(minHeight: 60)
        .cardSurface(radius: 16)
    }
}

extension TripChip where Trailing == TagPill {
    /// The chip with a tag saying where the dates came from: "From your trip".
    init(search: HotelSearch, tag: String = "From your trip") {
        self.init(search: search) { TagPill(text: tag) }
    }
}

/// A small note with an icon: limits, disclosures, reasons.
struct InfoNote: View {
    let text: String
    var symbol = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            SymbolIcon(name: symbol, size: 14)
                .foregroundStyle(Theme.Colors.muted)
                .frame(width: 16, height: 18)
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// An icon in a tinted circle.
struct IconCircle<Icon: View>: View {
    var size: CGFloat = 36
    var fill = Theme.Colors.tintPurple
    var foreground = Theme.Colors.purple
    @ViewBuilder var icon: Icon

    var body: some View {
        icon
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Icon · label over value (and an optional detail line) · trailing control.
struct DetailRow<Icon: View, Trailing: View>: View {
    let label: String
    let value: String
    var detail: String?
    /// Larger icon and value, as in the search form.
    var isLarge = false
    var showsDivider = true
    @ViewBuilder var icon: Icon
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(size: isLarge ? 40 : 36) { icon }
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(value)
                    .textStyle(isLarge ? .bodyEmphasis : .subheadEmphasis)
                if let detail {
                    Text(detail)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            trailing
        }
        .padding(.vertical, isLarge ? 0 : 6)
        .frame(minHeight: isLarge ? 66 : 56)
        .overlay(alignment: .top) {
            if showsDivider { Hairline() }
        }
    }
}

extension DetailRow where Trailing == EmptyView {
    init(label: String, value: String, detail: String? = nil, isLarge: Bool = false,
         showsDivider: Bool = true, @ViewBuilder icon: () -> Icon) {
        self.init(label: label, value: value, detail: detail, isLarge: isLarge,
                  showsDivider: showsDivider, icon: icon, trailing: { EmptyView() })
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.hairline)
            .frame(height: Theme.Size.border)
            .accessibilityHidden(true)
    }
}

/// − value +, with 44pt buttons that disable at the limits.
struct StepperControl: View {
    let value: Int
    let name: String
    var canDecrease: Bool
    var canIncrease: Bool
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            RoundIconButton(symbol: "minus", label: "Fewer \(name)", isEnabled: canDecrease) { onChange(-1) }
            Text("\(value)")
                .textStyle(.headline)
                .frame(minWidth: 18)
                .contentTransition(.numericText())
                .accessibilityHidden(true)
            RoundIconButton(symbol: "plus", label: "More \(name)", isEnabled: canIncrease) { onChange(1) }
        }
    }
}

struct RoundIconButton: View {
    let symbol: String
    let label: String
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SymbolIcon(name: symbol, size: 17, weight: .semibold)
                .foregroundStyle(Theme.Colors.ink.opacity(isEnabled ? 1 : 0.3))
                .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                .background(Theme.Colors.stepperFill, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// Segmented control in the retail app's style: a white thumb on a grey track.
struct SegmentedControl<Value: Hashable>: View {
    struct Option: Identifiable {
        let value: Value
        let label: String
        var isEnabled = true
        /// Why the option is unavailable; read by VoiceOver.
        var disabledReason: String?
        var id: String { label }
    }

    let options: [Option]
    let selection: Value
    var height: CGFloat = 40
    var onSelect: (Value) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option.value == selection
                Button {
                    withAnimation(Theme.Motion.select) { onSelect(option.value) }
                } label: {
                    Text(option.label)
                        .textStyle(.subheadEmphasis, color: color(for: option, isSelected: isSelected))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: height)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Theme.Colors.white)
                                    .shadow(color: Theme.Colors.segmentShadow, radius: 4, x: 0, y: 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!option.isEnabled)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityHint(option.isEnabled ? "" : (option.disabledReason ?? ""))
            }
        }
        .padding(3)
        .background(Theme.Colors.segmentTrack, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func color(for option: Option, isSelected: Bool) -> Color {
        if !option.isEnabled { return Theme.Colors.segmentDisabled }
        return isSelected ? Theme.Colors.ink : Theme.Colors.ink2
    }
}

/// Radio mark: a purple ring and dot when selected.
struct RadioMark: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .fill(Theme.Colors.white)
            .overlay { Circle().strokeBorder(isOn ? Theme.Colors.purple2 : Theme.Colors.radioIdle, lineWidth: 2) }
            .overlay {
                Circle()
                    .fill(Theme.Colors.purple2)
                    .frame(width: 10, height: 10)
                    .opacity(isOn ? 1 : 0)
            }
            .frame(width: 22, height: 22)
            .animation(Theme.Motion.select, value: isOn)
            .accessibilityHidden(true)
    }
}

/// A spinning ring for "checking" and "in progress".
struct ProgressRing: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinning = false

    var body: some View {
        Circle()
            .stroke(Theme.Colors.spinnerTrack, lineWidth: lineWidth)
            .overlay {
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Theme.Colors.purple2, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(spinning ? 360 : 0))
            }
            .frame(width: size, height: size)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { spinning = true }
            }
            .accessibilityHidden(true)
    }
}

/// One line of a price breakdown.
struct PriceRow: View {
    let label: String
    let value: String
    var isTotal = false
    var valueColor = Theme.Colors.ink

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .textStyle(isTotal ? .subheadEmphasis : .subhead, color: isTotal ? Theme.Colors.ink : Theme.Colors.muted)
            Spacer(minLength: 0)
            Text(value)
                .textStyle(.subheadEmphasis, color: valueColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Nightly line, taxes and fees, and the total.
struct PriceBreakdown: View {
    let price: StayPrice
    var spacing: CGFloat = 8
    var showsDivider = true

    var body: some View {
        VStack(spacing: spacing) {
            PriceRow(label: price.nightsLine, value: price.subtotal.usd)
            PriceRow(label: "Taxes and fees", value: price.taxesAndFees.usd)
            if showsDivider { Hairline() }
            PriceRow(label: "Total", value: price.total.usd, isTotal: true)
        }
    }
}

/// Thumbnail with rounded corners.
struct Thumbnail: View {
    let name: String
    var size: CGFloat = 52
    var radius: CGFloat = Theme.Radius.thumbnail

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Hotel · room and rate · dates, as a compact card.
struct StaySummaryRow: View {
    let imageName: String
    let title: String
    let line1: String
    var line2: String?

    var body: some View {
        HStack(spacing: 12) {
            Thumbnail(name: imageName)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textStyle(.subheadEmphasis)
                Text(line1)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                if let line2 {
                    Text(line2)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .cardSurface(radius: 18)
        .accessibilityElement(children: .combine)
    }
}

/// Rewards balance after a booking.
struct RewardsBalanceCard: View {
    let balance: Int
    let used: Int

    var body: some View {
        HStack(spacing: 12) {
            PointsCoin(size: 36, starSize: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text("Rewards balance")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(balance.pointsText)
                        .textStyle(.headline)
                    if used > 0 {
                        Text("\(used.pointsText) used")
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// Loading placeholder for a list of cards.
struct CardListSkeleton: View {
    var count = 3
    var height: CGFloat = 108

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { _ in
                ShimmerBlock(cornerRadius: Theme.Radius.card)
                    .frame(height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

#Preview("Flow components") {
    let search = HotelSampleData.sample.tripSearch
    return ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            StepHeader(step: 2, title: "Choose a room", subtitle: "Houston · for your trip")
            TripChip(search: search)
            SegmentedControl(options: HotelSort.allCases.map { .init(value: $0, label: $0.rawValue) },
                             selection: HotelSort.recommended) { _ in }
            StepperControl(value: 2, name: "guests", canDecrease: true, canIncrease: true) { _ in }
            InfoNote(text: "Dates and travelers come from Your trip in Houston.")
            RewardsBalanceCard(balance: 2450, used: 10000)
            ActionBar(buttonTitle: "Continue", action: {}) {
                Text("$877.50 total").textStyle(.headline)
            }
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
