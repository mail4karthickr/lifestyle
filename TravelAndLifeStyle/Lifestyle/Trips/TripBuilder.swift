//
//  TripBuilder.swift
//  Lifestyle · Day 4 · trips worked out from confirmed bookings
//
//  Nothing about a trip is stored on its own. Every time the landing page loads,
//  the customer's confirmed hotel and dining bookings are grouped into trips by
//  date overlap, and each trip gets its title, destination, dates and indicators.
//

import Foundation

/// A confirmed dining reservation (Day 3).
struct DiningReservation: Identifiable, Hashable {
    let reservationId: String
    let customerId: String
    /// The existing trip whose dates include the dinner, when there is one.
    let tripId: String?
    let restaurantId: String
    let restaurantName: String
    /// "Houston, TX"
    let city: String
    let address: String
    let imageName: String
    /// "Chef’s table"
    let offering: String
    let date: Date
    /// Start time, restaurant local time: "20:00".
    let time: String
    let partySize: Int
    let accessibilityNeeds: [String]
    let specialRequests: String?
    let dietaryNotes: String?
    let depositTotal: Decimal
    let pointsUsed: Int
    let cardCharged: Decimal
    let cardLast4: String
    let policy: String
    let status: String
    let createdAt: Date

    var id: String { reservationId }
    var guestsText: String { partySize == 1 ? "1 guest" : "\(partySize) guests" }
    var timeText: String { TripCalendar.clock(time) }
}

/// A confirmed booking of either kind.
enum Booking: Identifiable, Hashable {
    case hotel(HotelBooking)
    case dining(DiningReservation)

    var id: String {
        switch self {
        case .hotel(let booking): booking.id
        case .dining(let reservation): reservation.id
        }
    }

    /// A hotel covers check-in through checkout; a dinner covers its date.
    var start: Date {
        switch self {
        case .hotel(let booking): booking.checkIn
        case .dining(let reservation): reservation.date
        }
    }

    var end: Date {
        switch self {
        case .hotel(let booking): booking.checkOut
        case .dining(let reservation): reservation.date
        }
    }

    var city: String {
        switch self {
        case .hotel(let booking): booking.city
        case .dining(let reservation): reservation.city
        }
    }

    var hotel: HotelBooking? {
        if case .hotel(let booking) = self { return booking }
        return nil
    }

    var dining: DiningReservation? {
        if case .dining(let reservation) = self { return reservation }
        return nil
    }
}

/// One tile on the landing page: the bookings whose dates overlap.
struct Trip: Identifiable, Hashable {
    /// Stable: the id of the earliest booking.
    let id: String
    let bookings: [Booking]
    let start: Date
    let end: Date

    init(bookings: [Booking]) {
        self.bookings = bookings
        id = bookings.first?.id ?? ""
        start = bookings.map(\.start).min() ?? .distantPast
        end = bookings.map(\.end).max() ?? .distantPast
    }

    var hotels: [HotelBooking] { bookings.compactMap(\.hotel) }
    var dinners: [DiningReservation] { bookings.compactMap(\.dining) }
    var hasStay: Bool { !hotels.isEmpty }
    var hasDining: Bool { !dinners.isEmpty }

    /// "Your stay at …" for a hotel alone, "Your dinner at …" for a dinner alone,
    /// "Your trip in [city of the hotel]" for two or more bookings.
    var title: String {
        if bookings.count == 1 {
            switch bookings[0] {
            case .hotel(let booking): return "Your stay at \(booking.hotelName)"
            case .dining(let reservation): return "Your dinner at \(reservation.restaurantName)"
            }
        }
        return "Your trip in \(Self.cityName(destination))"
    }

    /// From booking data: the hotel's city, or the restaurant's for dinners alone.
    var destination: String {
        hotels.first?.city ?? dinners.first?.city ?? ""
    }

    /// Earliest start to latest end. A dinner alone shows its date and time.
    var datesText: String {
        if bookings.count == 1, let dinner = dinners.first {
            return "\(TripCalendar.dayWithYear(dinner.date)) · \(dinner.timeText)"
        }
        return TripCalendar.tripRange(start, end)
    }

    /// The image comes from our destination library, by city.
    var imageName: String { Self.imageName(forCity: destination) }

    func contains(bookingId: String) -> Bool { bookings.contains { $0.id == bookingId } }

    /// "Houston, TX" → "Houston"
    static func cityName(_ destination: String) -> String {
        destination.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? destination
    }

    /// From our destination library, by city. Unknown cities get the beach.
    static func imageName(forCity destination: String) -> String {
        HotelCatalog.destinationImage(forCity: cityName(destination)) ?? "beach"
    }
}

enum TripBuilder {

    /// Groups bookings whose date ranges overlap (check-in and checkout day count,
    /// and overlaps chain), drops trips that ended before today, and puts the
    /// upcoming trip first.
    ///
    /// - Parameter today: the customer's local date. A trip shows through its end
    ///   date and is removed the day after.
    static func trips(from bookings: [Booking], today: Date) -> [Trip] {
        let ordered = bookings.sorted { ($0.start, $0.id) < ($1.start, $1.id) }
        var groups: [[Booking]] = []
        var groupEnd = Date.distantPast
        for booking in ordered {
            if !groups.isEmpty, booking.start.isOnOrBefore(groupEnd) {
                groups[groups.count - 1].append(booking)
                if groupEnd.isOnOrBefore(booking.end) { groupEnd = booking.end }
            } else {
                groups.append([booking])
                groupEnd = booking.end
            }
        }
        return groups
            .map { Trip(bookings: $0) }
            .filter { today.isOnOrBefore($0.end) }
            .sorted { ($0.start, $0.id) < ($1.start, $1.id) }
    }
}
