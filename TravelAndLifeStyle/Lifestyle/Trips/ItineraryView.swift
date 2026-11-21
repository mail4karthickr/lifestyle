//
//  ItineraryView.swift
//  Lifestyle · Day 4 · a trip's itinerary: every booked item, by day
//
//  Display only. Built on each load from the customer's bookings plus the
//  seeded flights. Opened by selecting a plan on the landing page and from "View itinerary" on the
//  hotel and dining confirmations.
//

import SwiftUI

extension ItineraryItem.Kind {
    var symbol: String {
        switch self {
        case .flight: "airplane"
        case .hotelCheckIn: "bed.double"
        case .hotelCheckOut: "door.left.hand.closed"
        case .dining: "fork.knife"
        }
    }
}

/// The icon for an itinerary item. Check-out is a door, drawn from the designs.
struct ItineraryIcon: View {
    let kind: ItineraryItem.Kind
    var size: CGFloat = 16

    var body: some View {
        if kind == .hotelCheckOut {
            Glyph(shape: DoorShape(), size: size + 3, lineWidth: 1.9)
        } else {
            SymbolIcon(name: kind.symbol, size: size)
        }
    }
}

// MARK: - Timeline (beside a confirmation, and the search preview)

/// One booking on the timeline: flight, check-in, check-out or dinner.
struct ItineraryItemCard: View {
    let item: ItineraryItem
    var showsReference = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconCircle(size: 38, fill: colors.fill, foreground: colors.foreground) {
                ItineraryIcon(kind: item.kind)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .textStyle(.subheadEmphasis)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if item.isJustAdded {
                        TagPill(text: "Just added")
                    }
                }
                Text(item.timelineDetail)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                if showsReference, let reference = item.reference {
                    Text(reference)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 18)
        .overlay {
            if item.isJustAdded {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.Colors.purple2, lineWidth: 2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var colors: (fill: Color, foreground: Color) {
        switch item.kind {
        case .flight: (Theme.Colors.tintPurple, Theme.Colors.purple)
        case .hotelCheckIn: (Theme.Colors.tintRed, Theme.Colors.red)
        case .hotelCheckOut: (Theme.Colors.tintNeutral, Theme.Colors.ink2)
        case .dining: (Theme.Colors.tintAmber, Theme.Colors.amber)
        }
    }
}

/// Day headers with their bookings. `showsHotelSlot` marks where a hotel will go.
struct ItineraryTimeline: View {
    let days: [ItineraryDay]
    var showsReference = true
    var showsHotelSlot = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(days) { day in
                Text(day.header)
                    .textStyle(.dayHeader, color: Theme.Colors.muted)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)
                ForEach(day.items) { item in
                    ItineraryItemCard(item: item, showsReference: showsReference)
                }
                if showsHotelSlot, day.id == days.first?.id {
                    HotelSlot()
                }
            }
        }
    }
}

/// Dashed placeholder on the trip: "Your hotel goes here".
struct HotelSlot: View {
    var body: some View {
        HStack(spacing: 10) {
            SymbolIcon(name: "bed.double", size: 16)
            Text("Your hotel goes here")
                .textStyle(.subheadEmphasis, color: Theme.Colors.purple)
        }
        .foregroundStyle(Theme.Colors.purple)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.Colors.dashedSlot, style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
        }
        .accessibilityElement(children: .combine)
    }
}

/// The trip beside a confirmation: title, dates, Stay and Dining, then the timeline.
struct TripItinerarySection: View {
    let itinerary: TripItinerary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(itinerary.trip.title)
                .textStyle(.paneTitle)
                .accessibilityAddTraits(.isHeader)
            Text(itinerary.shortDatesLine)
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        TripIndicators(trip: itinerary.trip)
            .padding(.top, 6)
        ItineraryTimeline(days: itinerary.days)
    }
}

/// "Added to your trip" with a link to the itinerary, over the timeline.
struct AddedToTripSection: View {
    @Environment(LifestyleStore.self) private var store
    let itinerary: TripItinerary
    let bookingId: String

    var body: some View {
        HStack(spacing: 8) {
            Text("Added to your trip")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Button {
                store.advance(to: .itinerary(bookingId: bookingId))
            } label: {
                LinkLabel(title: "View itinerary")
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
        }
        .frame(minHeight: Theme.Size.touch)
        .padding(.bottom, -6)

        ItineraryTimeline(days: itinerary.days)
    }
}

// MARK: - Day list (Concur style)

/// Time, an icon on the rail, and the booking's card.
private struct ItinerarySegmentRow: View {
    let item: ItineraryItem
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        let clock = TripCalendar.clockParts(item.time24)

        HStack(spacing: 10) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(clock.time)
                    .textStyle(.subheadEmphasis)
                Text(clock.period)
                    .textStyle(.statusLabel, color: Theme.Colors.muted)
            }
            .frame(width: ItineraryDayList.timeWidth, alignment: .trailing)
            .accessibilityHidden(true)

            // Opaque tint with a halo, so the rail line doesn't show through.
            ItineraryIcon(kind: item.kind, size: 15)
                .foregroundStyle(colors.foreground)
                .frame(width: ItineraryDayList.iconSize, height: ItineraryDayList.iconSize)
                .background(colors.fill, in: Circle())
                .background {
                    Circle()
                        .fill(Theme.Colors.railHalo)
                        .padding(-4)
                }

            Button(action: action) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .textStyle(.subheadEmphasis)
                        Text(item.line)
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                        if let reference = item.reference {
                            Text(reference)
                                .textStyle(.footnote, color: Theme.Colors.muted)
                        }
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    SymbolIcon(name: "chevron.right", size: 13, weight: .semibold)
                        .foregroundStyle(Theme.Colors.muted)
                }
                .padding(.vertical, 9)
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .cardSurface(radius: 16)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.Colors.purple2, lineWidth: 2)
                    }
                }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(item.spoken)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        }
    }

    private var colors: (fill: Color, foreground: Color) {
        switch item.kind {
        case .flight: (Theme.Colors.railPurple, Theme.Colors.purple)
        case .hotelCheckIn: (Theme.Colors.railRed, Theme.Colors.red)
        case .hotelCheckOut: (Theme.Colors.railNeutral, Theme.Colors.ink2)
        case .dining: (Theme.Colors.railAmber, Theme.Colors.amber)
        }
    }
}

/// "Wed, Dec 30 · Day 1 of 4" over that day's items. Days with nothing booked
/// are left out.
struct ItineraryDayList: View {
    static let timeWidth: CGFloat = 46
    static let iconSize: CGFloat = 34

    let itinerary: TripItinerary
    /// The booking showing in the details pane, if there is one.
    var selection: ItineraryItem.Ref?
    var onSelect: (ItineraryItem) -> Void

    var body: some View {
        ForEach(Array(itinerary.days.enumerated()), id: \.element.id) { index, day in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(day.label)
                        .textStyle(.bodyEmphasis)
                    Text(day.dayOfTrip)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .frame(minHeight: 28)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                ForEach(day.items) { item in
                    ItinerarySegmentRow(item: item, isSelected: selection == item.ref) { onSelect(item) }
                }
            }
            // The rail runs behind the icons, from the first to the last.
            .background(alignment: .topLeading) {
                Capsule()
                    .fill(Theme.Colors.railLine)
                    .frame(width: 2)
                    .padding(.top, 44)
                    .padding(.bottom, 26)
                    .offset(x: Self.timeWidth + 10 + Self.iconSize / 2 - 1)
                    .accessibilityHidden(true)
            }
            .riseIn(order: index)
        }
    }
}

/// "3 nights · 1 stay · 1 dinner · 2 flights"
private struct ItinerarySummaryTags: View {
    let tags: [TripItinerary.Tag]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags) { tag in
                HStack(spacing: 5) {
                    SymbolIcon(name: tag.symbol, size: 11, weight: .bold)
                    Text(tag.text)
                        .textStyle(.footnoteEmphasis, color: Theme.Colors.ink2)
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.Colors.ink2)
                .padding(.horizontal, 10)
                .frame(minHeight: Theme.Size.imageTag)
                .background(Theme.Colors.tintNeutral, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Screen

enum ItineraryText {
    static let displayOnly = "Display only in this version: changes and cancellations aren’t available yet."
}

struct ItineraryView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Any booking of the trip.
    let bookingId: String

    var body: some View {
        Group {
            if let trip = store.bookings.trip(containing: bookingId) {
                let itinerary = store.bookings.itinerary(for: trip)
                if horizontalSizeClass == .regular {
                    ItinerarySplit(itinerary: itinerary, bookingId: bookingId,
                                   selection: store.selectedRef(in: itinerary, bookingId: bookingId))
                } else {
                    ItineraryCompact(itinerary: itinerary)
                }
            } else {
                ContentUnavailableView("Nothing booked yet", systemImage: "suitcase")
            }
        }
        // Day 1 calls this page My Trip: selecting a plan on the landing page opens it.
        .flowChrome(title: "My Trip")
    }
}

/// Regular width: the day list leads; the selected booking's details trail.
struct ItinerarySplit: View {
    @Environment(LifestyleStore.self) private var store
    let itinerary: TripItinerary
    let bookingId: String
    let selection: ItineraryItem.Ref?

    var body: some View {
        FlowSplit {
            FlowPane(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Thumbnail(name: itinerary.trip.imageName, size: 56, radius: Theme.Radius.thumbnailLarge)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(itinerary.trip.title)
                                .textStyle(.cardTitle)
                                .accessibilityAddTraits(.isHeader)
                            Text(itinerary.datesLine)
                                .textStyle(.footnote, color: Theme.Colors.muted)
                        }
                        .lineLimit(1)
                    }
                    TripIndicators(trip: itinerary.trip)
                }
                ItineraryDayList(itinerary: itinerary, selection: selection) { item in
                    withAnimation(Theme.Motion.select) { store.selectedBooking[bookingId] = item.ref }
                }
            }
        } trailing: {
            FlowPane {
                if let selection {
                    BookingDetailsContent(ref: selection, isPane: true)
                        .id(selection)
                }
                InfoNote(text: ItineraryText.displayOnly)
            }
        }
    }
}

/// Compact width: the destination runs full width under the bars, then the
/// indicators, the summary and the days.
private struct ItineraryCompact: View {
    @Environment(LifestyleStore.self) private var store
    let itinerary: TripItinerary

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let container = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                   height: proxy.size.height + insets.top + insets.bottom)
            let margin = LandingMetrics.margin(forWidth: container.width)
            let isShort = container.height < 760
            let leading = max(insets.leading, margin)
            let trailing = max(insets.trailing, margin)

            ScrollView {
                VStack(spacing: 0) {
                    ItineraryHero(itinerary: itinerary, height: isShort ? 190 : 250,
                                  leading: leading, trailing: trailing)

                    VStack(alignment: .leading, spacing: 14) {
                        TripIndicators(trip: itinerary.trip)
                        ItinerarySummaryTags(tags: itinerary.tags)
                        ItineraryDayList(itinerary: itinerary) { item in
                            store.advance(to: .bookingDetails(item.ref))
                        }
                        InfoNote(text: ItineraryText.displayOnly)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, isShort ? 12 : 14)
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .top)
            .ignoresSafeArea(.container, edges: [.top, .horizontal])
        }
    }
}

/// Destination image with a frost panel: the trip's title, dates and city.
private struct ItineraryHero: View {
    let itinerary: TripItinerary
    let height: CGFloat
    let leading: CGFloat
    let trailing: CGFloat

    var body: some View {
        Color.clear
            .frame(height: height)
            .overlay {
                Image(itinerary.trip.imageName)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous))
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(itinerary.trip.title)
                        .textStyle(.cardTitle)
                        .accessibilityAddTraits(.isHeader)
                    Text(itinerary.datesLine)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .lineLimit(1)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frostSurface(radius: 18)
                .padding(.leading, leading)
                .padding(.trailing, trailing)
                .padding(.bottom, 12)
                .accessibilityElement(children: .combine)
            }
            .riseIn()
    }
}

#Preview("Itinerary · compact") {
    let store = LifestyleStore.preview(seed: .hotelAndDinner)
    if let trip = store.bookings.trips().first { store.open(trip) }
    return LifestyleRootView(store: store)
}

#Preview("Itinerary · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview(seed: .hotelAndDinner)
    if let trip = store.bookings.trips().first { store.open(trip) }
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}
