//
//  TripTabletopView.swift
//  Lifestyle · My Trip on iPhone Duo, half folded on a table
//
//  Tabletop: the inner display is stacked and one half stands upright. That
//  half shows one booking, large enough to read from across the table: what's
//  next by default, or the booking picked in the days below it. The flat half
//  keeps the days within reach.
//

import SwiftUI

extension TripItinerary {
    /// What's next: the first booking on or after today, or the last one once
    /// the trip is over. Days are compared, not times: the POC has no clock.
    func nextItem(from today: Date) -> ItineraryItem? {
        items.first { today.isOnOrBefore($0.day) } ?? items.last
    }

    /// "Today", "Tomorrow", "In 38 days"; nil for a day that has passed.
    static func countdown(from today: Date, to day: Date) -> String? {
        // `nights` never goes below zero, so a past day is ruled out first.
        guard today.isOnOrBefore(day) else { return nil }
        switch TripCalendar.nights(today, day) {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case let days: return "In \(days) days"
        }
    }
}

/// The upright half: one booking over the trip's image.
struct TripGlancePane: View {
    @Environment(\.flowPane) private var pane
    @Environment(\.splitArrangementAxis) private var axis

    let itinerary: TripItinerary
    let item: ItineraryItem
    /// False when the customer picked a booking other than the next one.
    let isNext: Bool
    let today: Date

    var body: some View {
        let padding = pane.insets.padding(for: pane.position, axis: axis)

        Color.clear
            .overlay {
                Image(itinerary.trip.imageName)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottom) {
                TripGlanceCard(itinerary: itinerary, item: item, isNext: isNext, today: today)
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.heroPane, style: .continuous))
            .padding(padding)
    }
}

/// Time, what it is, where, and the number to quote, on glass.
private struct TripGlanceCard: View {
    let itinerary: TripItinerary
    let item: ItineraryItem
    let isNext: Bool
    let today: Date

    private var day: ItineraryDay? { itinerary.days.first { $0.items.contains(item) } }

    var body: some View {
        let clock = TripCalendar.clockParts(item.time24)
        let countdown = TripItinerary.countdown(from: today, to: item.day)

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(isNext ? "NEXT UP" : "YOUR PICK")
                    .textStyle(.caps, color: Theme.Colors.purple)
                if let day {
                    Text("\(day.label) · \(day.dayOfTrip)")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                Spacer(minLength: 0)
                if let countdown {
                    TagPill(text: countdown, tone: .purple, symbol: "clock")
                }
            }
            .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(clock.time)
                    .textStyle(.display)
                Text(clock.period)
                    .textStyle(.title2, color: Theme.Colors.ink2)
                Spacer(minLength: 8)
                IconCircle(size: 52, fill: colors.fill, foreground: colors.foreground) {
                    ItineraryIcon(kind: item.kind, size: 24)
                }
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 8 }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(item.title)
                .textStyle(.title1)
                .lineLimit(2)
            Text(item.line)
                .textStyle(.body, color: Theme.Colors.ink2)
                .lineLimit(1)

            if let reference = item.reference {
                Text(reference)
                    .textStyle(.code)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Theme.Colors.chipSelectedFill, in: Capsule())
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frostSurface(radius: 22, tint: Theme.Colors.frostFillStrong)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isNext ? "Next up" : "Your pick"): \(item.spoken)\(countdown.map { ". \($0)" } ?? "")")
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

/// The flat half: the trip in one line, then its days. Picking a booking
/// shows it on the upright half.
struct TripTabletopDays: View {
    let itinerary: TripItinerary
    let shownItemId: String
    var onSelect: (ItineraryItem) -> Void

    var body: some View {
        FlowPane(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(itinerary.trip.title)
                    .textStyle(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(itinerary.datesLine)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .lineLimit(1)
            ItineraryDayList(itinerary: itinerary, selectedItemId: shownItemId, onSelect: onSelect)
        }
    }
}
