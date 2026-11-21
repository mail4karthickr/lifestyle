//
//  TripComponents.swift
//  Lifestyle · My plans on the landing page (Day 1) and the Stay and Dining
//  indicators of a trip (Day 4)
//

import SwiftUI

// MARK: - Indicators

/// Stay or Dining (Day 4): green with a check when booked, greyed out when not.
struct TripIndicator: View {
    enum Kind {
        case stay, dining

        var label: String { self == .stay ? "Stay" : "Dining" }
        var symbol: String { self == .stay ? "bed.double" : "fork.knife" }
    }

    let kind: Kind
    let isBooked: Bool

    var body: some View {
        HStack(spacing: 8) {
            SymbolIcon(name: kind.symbol, size: 15)
                .frame(width: 18)
            Text(kind.label)
                .textStyle(.indicator, color: foreground)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isBooked {
                Circle()
                    .fill(Theme.Colors.green)
                    .frame(width: 18, height: 18)
                    .overlay {
                        Glyph(shape: CheckShape(), size: 12, lineWidth: 3)
                            .foregroundStyle(Theme.Colors.white)
                    }
            } else {
                Text("Not booked")
                    .textStyle(.statusLabel, color: Theme.Colors.indicatorIdleNote)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(isBooked ? Theme.Colors.mint : Theme.Colors.statusIdleFill,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.statusTile, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.label): \(isBooked ? "booked" : "not booked")")
    }

    private var foreground: Color { isBooked ? Theme.Colors.green : Theme.Colors.indicatorIdleText }
}

/// Stay and Dining, side by side.
struct TripIndicators: View {
    let hasStay: Bool
    let hasDining: Bool

    var body: some View {
        HStack(spacing: 6) {
            TripIndicator(kind: .stay, isBooked: hasStay)
            TripIndicator(kind: .dining, isBooked: hasDining)
        }
    }
}

extension TripIndicators {
    init(trip: Trip) {
        self.init(hasStay: trip.hasStay, hasDining: trip.hasDining)
    }
}

// MARK: - Plan card

/// One status on a plan card (Day 1): mint with a green check badge when
/// booked, grey when not.
struct PlanStatusTile: View {
    enum Kind: CaseIterable {
        case stay, travel, dining, experience

        var label: String {
            switch self {
            case .stay: "Stay"
            case .travel: "Travel"
            case .dining: "Dining"
            case .experience: "Experience"
            }
        }

        var symbol: String {
            switch self {
            case .stay: "bed.double"
            case .travel: "airplane"
            case .dining: "fork.knife"
            case .experience: "star"
            }
        }
    }

    let kind: Kind
    let isBooked: Bool

    var body: some View {
        VStack(spacing: 2) {
            SymbolIcon(name: kind.symbol, size: 15)
                .frame(height: 18)
            Text(kind.label)
                .textStyle(.statusLabel, color: foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(isBooked ? Theme.Colors.mint : Theme.Colors.statusIdleFill,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.statusTile, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if isBooked {
                Circle()
                    .fill(Theme.Colors.green)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Glyph(shape: CheckShape(), size: 11, lineWidth: 3)
                            .foregroundStyle(Theme.Colors.white)
                    }
                    .padding(4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.label): \(isBooked ? "booked" : "not booked")")
    }

    private var foreground: Color { isBooked ? Theme.Colors.green : Theme.Colors.muted }
}

extension Trip {
    /// What a plan card marks as booked. Only stays and dinners can be booked
    /// in the POC, so Travel and Experience stay grey; the flights the
    /// itinerary lists are seed data and never drive a status (Day 4).
    func isBooked(_ kind: PlanStatusTile.Kind) -> Bool {
        switch kind {
        case .stay: hasStay
        case .dining: hasDining
        case .travel, .experience: false
        }
    }
}

/// One plan on the landing page: trip name and dates with the four status
/// tiles (Day 1), plus the image and destination a trip's tile shows (Day 4).
/// The whole card is one button that opens My Trip, the trip's itinerary.
struct PlanCard: View {
    let trip: Trip
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Thumbnail(name: trip.imageName, size: 60)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(trip.title)
                            .textStyle(.headline)
                        HStack(spacing: 3) {
                            Glyph(shape: PinShape(), size: 14)
                                .foregroundStyle(Theme.Colors.muted)
                            Text(trip.destination)
                                .textStyle(.footnote, color: Theme.Colors.ink2)
                        }
                        Text(trip.datesText)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    SymbolIcon(name: "chevron.right", size: 14, weight: .semibold)
                        .foregroundStyle(Theme.Colors.muted)
                }
                HStack(spacing: 6) {
                    ForEach(PlanStatusTile.Kind.allCases, id: \.self) { kind in
                        PlanStatusTile(kind: kind, isBooked: trip.isBooked(kind))
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(spokenSummary)
        .accessibilityHint("Opens My Trip")
    }

    /// "Your trip in Houston, Houston, TX, Dec 30, 2026 – Jan 2, 2027. Stay booked, Dining booked."
    private var spokenSummary: String {
        let booked = PlanStatusTile.Kind.allCases.filter(trip.isBooked).map { "\($0.label) booked" }
        return "\(trip.title), \(trip.destination), \(trip.datesText). \(booked.joined(separator: ", "))."
    }
}

// MARK: - Section

/// My plans on the landing page, below Book now (Day 1). It is always there:
/// one card per trip once something is booked, and the empty state until then.
/// Which trips there are, their titles and their order come from the bookings
/// on every load (Day 4's rules). Selecting a plan opens My Trip, its itinerary.
struct MyPlansSection: View {
    let state: LoadState<[Trip]>
    var onSelect: (Trip) -> Void
    var onPlanWithConcierge: () -> Void
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My plans")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)

            switch state {
            case .loading:
                TripSkeletonCard(thumbnail: 60, tiles: 4, tileHeight: 52)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Loading your plans")
            case .failed:
                SectionErrorCard(title: "Couldn't load your plans",
                                 message: "Everything else on this page is up to date.",
                                 onRetry: onRetry)
            case .loaded(let trips):
                if trips.isEmpty {
                    EmptyPlansCard(onPlanWithConcierge: onPlanWithConcierge)
                        .riseIn()
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                            PlanCard(trip: trip) { onSelect(trip) }
                                .riseIn(order: index)
                        }
                    }
                }
            }
        }
    }
}

/// Nothing booked yet (Day 1): "No plans yet", and a way to start with Fargo Concierge.
struct EmptyPlansCard: View {
    var onPlanWithConcierge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                NoteIcon(fill: Theme.Colors.lockedFill, foreground: Theme.Colors.ink2) {
                    SymbolIcon(name: "suitcase", size: 19)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("No plans yet")
                        .textStyle(.bodyEmphasis)
                    Text("Stays and tables you book show up here.")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            Button(action: onPlanWithConcierge) {
                LinkLabel(title: "Plan with Fargo Concierge")
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .padding(.leading, 56)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// A card-shaped skeleton: a thumbnail, two lines and a row of blocks. The
/// defaults match a trip header; My plans passes its own card's sizes.
struct TripSkeletonCard: View {
    var thumbnail: CGFloat = 64
    var tiles = 2
    var tileHeight: CGFloat = 40

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ShimmerBlock(cornerRadius: Theme.Radius.thumbnailLarge)
                    .frame(width: thumbnail, height: thumbnail)
                VStack(alignment: .leading, spacing: 9) {
                    ShimmerBlock().frame(height: 14).containerRelativeFrame(.horizontal) { width, _ in width * 0.45 }
                    ShimmerBlock(cornerRadius: 6).frame(height: 11).containerRelativeFrame(.horizontal) { width, _ in width * 0.29 }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 6) {
                ForEach(0..<tiles, id: \.self) { _ in
                    ShimmerBlock(cornerRadius: Theme.Radius.statusTile)
                        .frame(height: tileHeight)
                }
            }
        }
        .padding(10)
        .cardSurface()
    }
}

#Preview("My plans · states") {
    let seeds = SeedBookings.sample
    let two = TripBuilder.trips(from: [.hotel(seeds.hotelHouston), .dining(seeds.dinnerHouston), .hotel(seeds.hotelKesselhorn)],
                                today: seeds.today)
    let dinner = TripBuilder.trips(from: [.dining(seeds.dinnerHouston)], today: seeds.today)
    return ScrollView {
        VStack(spacing: 24) {
            MyPlansSection(state: .loaded(two), onSelect: { _ in }, onPlanWithConcierge: {}, onRetry: {})
            MyPlansSection(state: .loaded(dinner), onSelect: { _ in }, onPlanWithConcierge: {}, onRetry: {})
            MyPlansSection(state: .loaded([]), onSelect: { _ in }, onPlanWithConcierge: {}, onRetry: {})
            MyPlansSection(state: .loading, onSelect: { _ in }, onPlanWithConcierge: {}, onRetry: {})
            MyPlansSection(state: .failed, onSelect: { _ in }, onPlanWithConcierge: {}, onRetry: {})
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
