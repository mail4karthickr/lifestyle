//
//  InspireViews.swift
//  Lifestyle · Day 5 · Inspire me: trip, hotels and flights picked from the profile
//

import SwiftUI

/// Why a pick was suggested: "Solenne Collection", "Your airline".
struct BecauseChip: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Glyph.sparkle(12, lineWidth: 2.2)
            Text(text)
                .textStyle(.chipSmall, color: Theme.Colors.purple)
                .lineLimit(1)
        }
        .foregroundStyle(Theme.Colors.purple)
        .padding(.horizontal, 9)
        .frame(minHeight: 24)
        .background(Theme.Colors.becauseFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Because of \(text)")
    }
}

/// "Based on" and the saved brands and airlines that drove the picks.
struct BasedOnRow: View {
    let names: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            Text("Based on")
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(minHeight: 24)
            ForEach(names, id: \.self) { name in
                BecauseChip(text: name)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Based on \(names.joined(separator: ", "))")
    }
}

/// The top hotel and a flight to the same city, as one suggested trip.
struct TripIdeaCard: View {
    let idea: TripIdea
    var imageHeight: CGFloat = 110
    var onView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardImage(name: idea.imageName, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    ImageTag(symbol: "point.topleft.down.to.point.bottomright.curvepath", text: "Trip idea")
                        .padding(10)
                }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(idea.title)
                        .textStyle(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(idea.datesText)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(idea.estimateText)
                    .textStyle(.footnoteEmphasis)
                    .lineLimit(1)
                    .fixedSize()
            }
            .accessibilityElement(children: .combine)

            line(symbol: "airplane", text: idea.flightLine)
            line(symbol: "bed.double", text: idea.hotelLine)

            HStack(spacing: 6) {
                ForEach(idea.because, id: \.self) { reason in
                    BecauseChip(text: reason)
                }
                Spacer(minLength: 0)
                Button(action: onView) {
                    LinkLabel(title: "View trip")
                        .frame(minHeight: Theme.Size.touch)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityHint("Opens the hotel with the trip's dates and travelers")
            }
        }
        .padding(12)
        .cardSurface(radius: Theme.Radius.groupCard)
    }

    private func line(symbol: String, text: String) -> some View {
        HStack(spacing: 8) {
            IconCircle(size: 30) {
                SymbolIcon(name: symbol, size: 13)
            }
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.ink2)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A suggested hotel. Opens Day 2's hotel details. A hotel from a favorite
/// brand carries the brand as its reason; any other just names its brand.
struct HotelPickCard: View {
    let hotel: InspireHotel
    var isFavorite = true
    var imageHeight: CGFloat = 84
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CardImage(name: hotel.imageName, height: imageHeight)
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name)
                        .textStyle(.subheadEmphasis)
                        .lineLimit(1)
                    Text(hotel.priceText)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                    if isFavorite {
                        BecauseChip(text: hotel.brand)
                    } else {
                        Text(hotel.brand)
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(hotel.name), \(hotel.priceText), \(isFavorite ? "because of " : "")\(hotel.brand)")
        .accessibilityHint("Opens the hotel")
    }
}

/// A suggested flight. Display only: flights can't be booked in the POC. A
/// flight on a favorite airline carries the airline as its reason.
struct FlightPickRow: View {
    let flight: InspireFlight
    var isFavorite = true

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(size: 38) {
                SymbolIcon(name: "airplane", size: 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(flight.route)
                        .textStyle(.subheadEmphasis)
                    Text(flight.flight)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                Text(flight.detail)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                    .lineLimit(1)
                if isFavorite {
                    BecauseChip(text: flight.airline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                Text(flight.roundTripFare.usdWhole)
                    .textStyle(.subheadEmphasis)
                Text("round trip")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .cardSurface(radius: 18)
        .accessibilityElement(children: .combine)
    }
}

/// Trip for you, Hotels for you, Flights for you: Inspire me always recommends all three.
struct InspirePicks: View {
    enum Style {
        /// One column in the chat; hotels scroll sideways.
        case thread(leadingBleed: CGFloat, trailingBleed: CGFloat)
        /// The context pane beside the chat: hotels in two columns.
        case pane
        /// Tabletop, upright half: the trip beside the hotels.
        case upright
        /// Tabletop, flat half: the flights, under the thread.
        case flights
    }

    @Environment(LifestyleStore.self) private var store
    let result: InspireResult
    let showsMoreHotels: Bool
    var style: Style

    private var hotels: [InspireHotel] {
        result.hotels + (showsMoreHotels ? result.moreHotels : [])
    }

    var body: some View {
        switch style {
        case .thread(let leadingBleed, let trailingBleed):
            trip(imageHeight: 110)
            if !hotels.isEmpty {
                title("Hotels for you")
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(hotels) { hotel in
                            HotelPickCard(hotel: hotel, isFavorite: result.isFavorite(hotel)) { open(hotel) }
                                .frame(width: 175)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                }
                .contentMargins(.leading, leadingBleed, for: .scrollContent)
                .contentMargins(.trailing, trailingBleed, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .padding(.leading, -leadingBleed)
                .padding(.trailing, -trailingBleed)
                .padding(.bottom, -8)
                .riseIn(order: 2)
            }
            flights(showsTitle: true)

        case .pane:
            trip(imageHeight: 96)
            if !hotels.isEmpty {
                title("Hotels for you")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(hotels) { hotel in
                        HotelPickCard(hotel: hotel, isFavorite: result.isFavorite(hotel), imageHeight: 64) { open(hotel) }
                    }
                }
                .riseIn(order: 2)
            }
            flights(showsTitle: true)

        case .upright:
            // The trip takes a little more than half; the hotels stack beside it.
            Grid(alignment: .top, horizontalSpacing: 14) {
                GridRow {
                    if let idea = result.trip {
                        TripIdeaCard(idea: idea, imageHeight: 150) { open(idea) }
                            .gridCellColumns(5)
                            .riseIn(order: 1)
                    }
                    VStack(spacing: 10) {
                        ForEach(hotels) { hotel in
                            HotelPickCard(hotel: hotel, isFavorite: result.isFavorite(hotel), imageHeight: 70) { open(hotel) }
                        }
                    }
                    .gridCellColumns(result.trip == nil ? 9 : 4)
                    .riseIn(order: 2)
                }
            }

        case .flights:
            flights(showsTitle: false)
        }
    }

    @ViewBuilder
    private func trip(imageHeight: CGFloat) -> some View {
        if let idea = result.trip {
            title("Trip for you")
            TripIdeaCard(idea: idea, imageHeight: imageHeight) { open(idea) }
                .riseIn(order: 1)
        }
    }

    @ViewBuilder
    private func flights(showsTitle: Bool) -> some View {
        if !result.flights.isEmpty {
            if showsTitle { title("Flights for you") }
            ForEach(result.flights) { flight in
                FlightPickRow(flight: flight, isFavorite: result.isFavorite(flight))
                    .riseIn(order: 3)
            }
            InfoNote(text: result.footnote)
        }
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .textStyle(.section)
            .padding(.top, 2)
            .accessibilityAddTraits(.isHeader)
    }

    /// View trip: the trip's hotel, with its dates and travelers carried over.
    private func open(_ idea: TripIdea) {
        store.open(idea.hotel, stay: (idea.start, idea.end), travelers: idea.travelers)
    }

    /// Opens Day 2's hotel details, with Inspire me's dates and the trip's travelers.
    private func open(_ hotel: InspireHotel) {
        store.open(hotel, stay: result.stay(for: hotel, nights: result.trip?.nights ?? 3),
                   travelers: result.trip?.travelers)
    }
}

/// "Want me to build the Miami trip, or show more hotels from Solenne Collection?"
struct InspireFollowUp: View {
    @Environment(LifestyleStore.self) private var store
    let model: ConciergeModel
    let result: InspireResult
    var bubbleWidth: CGFloat = 300

    var body: some View {
        if let text = result.followUpText {
            ConciergeBubble(text, maxWidth: bubbleWidth)
            FlowLayout(spacing: 8) {
                ForEach(result.followUpChips, id: \.self) { chip in
                    if chip == "More hotels" {
                        if !model.showsMoreHotels {
                            ChoiceChip(title: chip, isSelected: false) {
                                withAnimation(Theme.Motion.select) { model.showMoreHotels() }
                            }
                        }
                    } else if let trip = result.trip {
                        ChoiceChip(title: chip, isSelected: false) {
                            store.open(trip.hotel, stay: (trip.start, trip.end), travelers: trip.travelers)
                        }
                    }
                }
            }
        }
    }
}

#Preview("Inspire me · cards") {
    let store = LifestyleStore.preview(profile: ProfileSampleData.sample.afterSetup)
    return ScrollView {
        VStack(alignment: .leading, spacing: 10) {
            let result = MockInspireService.match(store.profile.preferences)
            if result.isPersonal { BasedOnRow(names: result.basedOn) }
            InspirePicks(result: result, showsMoreHotels: false, style: .thread(leadingBleed: 16, trailingBleed: 16))
            InspireFollowUp(model: store.concierge, result: result)
        }
        .padding(16)
    }
    .background(AmbientBackground())
    .environment(store)
}
