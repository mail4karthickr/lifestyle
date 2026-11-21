//
//  BookingDetailsView.swift
//  Lifestyle · Day 4 · one booking of a trip: dinner, hotel or flight
//
//  Display only. On compact width this is its own screen; on regular width it
//  is the trailing pane of the itinerary.
//

import SwiftUI

struct BookingDetailsView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let ref: ItineraryItem.Ref

    var body: some View {
        Group {
            if horizontalSizeClass == .regular, let trip = store.bookings.trip(showing: ref) {
                // Opened before the display got wider: the itinerary, with this booking selected.
                ItinerarySplit(itinerary: store.bookings.itinerary(for: trip), bookingId: trip.id, selection: ref)
            } else {
                FlowPage {
                    BookingDetailsContent(ref: ref, isPane: false)
                    InfoNote(text: ItineraryText.displayOnly)
                }
            }
        }
        .flowChrome(title: title, showsBarTitle: horizontalSizeClass != .regular)
    }

    private var title: String {
        switch ref {
        case .dining: "Dinner"
        case .hotel: "Hotel"
        case .flight: "Flight"
        }
    }
}

/// The stored booking behind an itinerary item.
struct BookingDetailsContent: View {
    @Environment(LifestyleStore.self) private var store
    let ref: ItineraryItem.Ref
    var isPane: Bool

    var body: some View {
        switch ref {
        case .dining(let id):
            if let reservation = store.bookings.reservation(id: id) {
                DinnerDetails(reservation: reservation, timeZoneNote: "Houston time (CT)", imageHeight: isPane ? 110 : 180)
            }
        case .hotel(let id):
            if let booking = store.bookings.hotelBooking(id: id) {
                BookingDetailsPane(booking: booking, imageHeight: isPane ? 110 : 180)
            }
        case .flight(let id):
            if let flight = store.bookings.flight(id: id) {
                FlightDetails(flight: flight)
            }
        }
    }
}

// MARK: - Dinner

/// Image with a Confirmed tag, name and address, the reservation ID, then what was reserved.
struct DinnerDetails: View {
    let reservation: DiningReservation
    let timeZoneNote: String
    var imageHeight: CGFloat = 180

    var body: some View {
        CardImage(name: reservation.imageName, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topLeading) {
                TagPill(text: reservation.status, tone: .mint, symbol: "checkmark")
                    .padding(10)
            }

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(reservation.restaurantName)
                    .textStyle(.cardTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(reservation.address)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                Text("Reservation ID")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(reservation.reservationId)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(1)
                    .fixedSize()
            }
            .accessibilityElement(children: .combine)
        }

        VStack(spacing: 0) {
            DetailRow(label: "Date and time",
                      value: "\(TripCalendar.dayWithYear(reservation.date)) · \(reservation.timeText)",
                      detail: "\(timeZoneNote) · \(reservation.offering)", showsDivider: false) {
                SymbolIcon(name: "calendar", size: 16)
            }
            DetailRow(label: "Party", value: reservation.guestsText, detail: accessibilityText) {
                SymbolIcon(name: "person.2", size: 14)
            }
            if let requests = requestLines.first {
                DetailRow(label: "Requests", value: requests, detail: requestLines.dropFirst().first) {
                    SymbolIcon(name: "note.text", size: 15)
                }
            }
            DetailRow(label: "Deposit paid", value: paid.value, detail: paid.detail) {
                SymbolIcon(name: "creditcard", size: 15)
            }
            DetailRow(label: "Cancellation", value: reservation.cancellation.value, detail: reservation.cancellation.detail) {
                SymbolIcon(name: "shield", size: 16)
            }
        }
        .padding(.horizontal, 14)
        .cardSurface()
    }

    private var accessibilityText: String? {
        reservation.accessibilityNeeds.isEmpty ? nil : "Accessibility: \(reservation.accessibilityNeeds.joined(separator: ", "))"
    }

    /// Special requests, then dietary notes.
    private var requestLines: [String] {
        [reservation.specialRequests, reservation.dietaryNotes].compactMap { $0 }.filter { !$0.isEmpty }
    }

    /// "$300.00 card ···· 4821" / "+ 10,000 pts · total $400.00"
    private var paid: (value: String, detail: String) {
        let total = "total \(reservation.depositTotal.usd)"
        if reservation.cardCharged > 0 {
            let card = "\(reservation.cardCharged.usd) card ···· \(reservation.cardLast4)"
            return (card, reservation.pointsUsed > 0 ? "+ \(reservation.pointsUsed.pointsText) · \(total)" : total)
        }
        return (reservation.pointsUsed.pointsText, total)
    }
}

extension DiningReservation {
    /// The policy as a headline and a detail line:
    /// "Full refund until Wed, Dec 30, 8:00 PM" / "After that, the deposit isn’t refunded".
    var cancellation: (value: String, detail: String?) {
        let text = policy.replacingOccurrences(of: ";", with: ".")
        let sentences = text.components(separatedBy: ". ")
        var first = sentences.first ?? text
        if first.hasPrefix("Cancel by "), let end = first.range(of: " for a full refund") {
            var cutoff = String(first[first.index(first.startIndex, offsetBy: 10)..<end.lowerBound])
            if let note = cutoff.range(of: " (") { cutoff = String(cutoff[..<note.lowerBound]) }
            first = "Full refund until \(cutoff)"
        }
        var rest = sentences.dropFirst().joined(separator: ". ").trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        if let initial = rest.first { rest = initial.uppercased() + rest.dropFirst() }
        return (first, rest.isEmpty ? nil : rest)
    }
}

// MARK: - Hotel

/// The stored booking: confirmation, check-in and check-out, room, guests,
/// cancellation and payment.
struct BookingDetailsPane: View {
    let booking: HotelBooking
    var imageHeight: CGFloat = 120

    var body: some View {
        CardImage(name: booking.imageName, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topLeading) {
                TagPill(text: booking.status, tone: .mint, symbol: "checkmark")
                    .padding(10)
            }

        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(booking.hotelName)
                    .textStyle(.cardTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(booking.hotelAddress)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                Text("Confirmation")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(booking.confirmationNumber)
                    .textStyle(.subheadEmphasis)
            }
            .accessibilityElement(children: .combine)
        }

        VStack(spacing: 0) {
            DetailRow(label: "Check in · check out",
                      value: "\(TripCalendar.day(booking.checkIn)) · \(TripCalendar.day(booking.checkOut))",
                      detail: "From \(TripCalendar.clock(booking.checkInFrom)) · by \(TripCalendar.clock(booking.checkOutBy))",
                      showsDivider: false) {
                SymbolIcon(name: "calendar", size: 16)
            }
            DetailRow(label: "Room", value: roomText, detail: partyText) {
                SymbolIcon(name: "bed.double", size: 15)
            }
            if !booking.cancellationSummary.isEmpty {
                DetailRow(label: "Cancellation",
                          value: booking.cancellationSummary.replacingOccurrences(of: "Free cancellation until", with: "Free until")) {
                    SymbolIcon(name: "shield", size: 16)
                }
            }
            if let paid {
                DetailRow(label: "Paid", value: paid.value, detail: paid.detail) {
                    SymbolIcon(name: "creditcard", size: 15)
                }
            }
        }
        .padding(.horizontal, 14)
        .cardSurface()
    }

    private var roomText: String {
        booking.rateName.isEmpty ? booking.roomName : "\(booking.roomName) · \(booking.rateName)"
    }

    private var partyText: String {
        let adults = booking.adults == 1 ? "1 adult" : "\(booking.adults) adults"
        let rooms = booking.rooms == 1 ? "1 room" : "\(booking.rooms) rooms"
        return "\(adults) · \(rooms)"
    }

    /// "$795.05 card ···· 4821" / "+ 10,000 pts · total $895.05"
    private var paid: (value: String, detail: String)? {
        guard let tender = booking.tender, let price = booking.price else { return nil }
        let total = "total \(price.total.usd)"
        if tender.cardAmount > 0 {
            let card = "\(tender.cardAmount.usd) card ···· \(booking.cardLast4)"
            return (card, tender.points > 0 ? "+ \(tender.points.pointsText) · \(total)" : total)
        }
        return (tender.points.pointsText, total)
    }
}

// MARK: - Flight

/// A seeded flight. Flight booking isn't in the POC, so this is all there is to show.
private struct FlightDetails: View {
    let flight: FlightBooking

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(size: 44) {
                SymbolIcon(name: "airplane", size: 19)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(flight.title)
                    .textStyle(.cardTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(flight.flight)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                Text("Confirmation")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(flight.confirmation)
                    .textStyle(.subheadEmphasis)
            }
            .accessibilityElement(children: .combine)
        }

        VStack(spacing: 0) {
            DetailRow(label: "Departs", value: "\(TripCalendar.dayWithYear(flight.date)) · \(TripCalendar.clock(flight.depart))",
                      detail: "From \(flight.from)", showsDivider: false) {
                SymbolIcon(name: "airplane.departure", size: 15)
            }
            DetailRow(label: "Arrives", value: TripCalendar.clock(flight.arrive), detail: "At \(flight.to)") {
                SymbolIcon(name: "airplane.arrival", size: 15)
            }
        }
        .padding(.horizontal, 14)
        .cardSurface()

        InfoNote(text: "This flight came with your trip. Flight booking isn’t available in this version.")
    }
}

#Preview("Dinner details") {
    let store = LifestyleStore.preview(seed: .hotelAndDinner)
    if let dinner = store.bookings.reservations.first {
        store.path = [.itinerary(bookingId: dinner.id), .bookingDetails(.dining(dinner.id))]
    }
    return LifestyleRootView(store: store)
}
