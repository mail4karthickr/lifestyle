//
//  BookingStore.swift
//  Lifestyle · the customer's confirmed bookings, and what is built from them
//
//  Day 2 writes hotel bookings and Day 3 writes dining reservations. Trips and
//  itineraries are never stored: they are worked out from these records on
//  every load (Day 4).
//

import Foundation
import Observation

/// Which bookings exist when the demo starts.
enum BookingSeed: String, CaseIterable, Identifiable {
    case none, dinnerOnly, hotelOnly, hotelAndDinner, twoTrips

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Nothing booked"
        case .dinnerOnly: "Dinner only"
        case .hotelOnly: "Hotel only"
        case .hotelAndDinner: "Hotel + dinner"
        case .twoTrips: "Two trips"
        }
    }
}

@Observable
final class BookingStore {
    let customerId: String
    /// The trip that exists before anything is booked here: its dates,
    /// travelers and flights are seeded (flight booking isn't in the POC).
    let existingTrip: TripRecord

    private(set) var hotelBookings: [HotelBooking] = []
    private(set) var reservations: [DiningReservation] = []
    /// The booking made most recently in this session.
    private(set) var justAddedId: String?

    /// Debug override for "today", to show a tile disappearing after checkout.
    var todayOverride: Date?
    var today: Date { todayOverride ?? TripCalendar.today() }

    init(existingTrip: TripRecord, customerId: String, seed: BookingSeed = .none,
         seeds: SeedBookings = .sample) {
        self.existingTrip = existingTrip
        self.customerId = customerId
        switch seed {
        case .none: break
        case .dinnerOnly: reservations = [seeds.dinnerHouston]
        case .hotelOnly: hotelBookings = [seeds.hotelHouston]
        case .hotelAndDinner:
            hotelBookings = [seeds.hotelHouston]
            reservations = [seeds.dinnerHouston]
        case .twoTrips:
            hotelBookings = [seeds.hotelHouston, seeds.hotelKesselhorn]
            reservations = [seeds.dinnerHouston]
        }
    }

    // MARK: Records

    var bookings: [Booking] {
        hotelBookings.map(Booking.hotel) + reservations.map(Booking.dining)
    }

    /// Stores a confirmed hotel booking. Storing it again changes nothing.
    @discardableResult
    func record(_ booking: HotelBooking) -> Bool {
        guard !hotelBookings.contains(where: { $0.id == booking.id }) else { return false }
        hotelBookings.append(booking)
        justAddedId = booking.id
        return true
    }

    /// Stores a confirmed dining reservation. Storing it again changes nothing.
    @discardableResult
    func record(_ reservation: DiningReservation) -> Bool {
        guard !reservations.contains(where: { $0.id == reservation.id }) else { return false }
        reservations.append(reservation)
        justAddedId = reservation.id
        return true
    }

    /// Adds a reservation the customer already holds (the overlap demo).
    func seed(_ reservation: DiningReservation) {
        guard !reservations.contains(where: { $0.id == reservation.id }) else { return }
        reservations.append(reservation)
    }

    func hotelBooking(id: String) -> HotelBooking? { hotelBookings.first { $0.id == id } }
    func reservation(id: String) -> DiningReservation? { reservations.first { $0.id == id } }

    /// The existing trip's ID, when the dates fall inside it.
    func tripId(covering start: Date, through end: Date) -> String? {
        existingTrip.start.isOnOrBefore(start) && end.isOnOrBefore(existingTrip.end) ? existingTrip.tripId : nil
    }

    // MARK: Trips

    /// Reruns trip matching and tile logic over the current bookings.
    func trips() -> [Trip] {
        TripBuilder.trips(from: bookings, today: today)
    }

    func trip(id: String) -> Trip? { trips().first { $0.id == id } }

    /// The trip a booking belongs to. Ignores "today", so a confirmation can
    /// always show the trip it was just added to.
    func trip(containing bookingId: String) -> Trip? {
        TripBuilder.trips(from: bookings, today: .distantPast).first { $0.contains(bookingId: bookingId) }
    }

    /// The trip whose itinerary shows this item.
    func trip(showing ref: ItineraryItem.Ref) -> Trip? {
        switch ref {
        case .hotel(let id), .dining(let id):
            return trip(containing: id)
        case .flight(let id):
            return TripBuilder.trips(from: bookings, today: .distantPast).first { trip in
                flights(for: trip).contains { $0.id == id }
            }
        }
    }

    func flight(id: String) -> FlightBooking? { existingTrip.flights.first { $0.id == id } }

    /// The Houston hotel booked on Day 2, for the restaurant's Nearby row.
    func hotel(named name: String) -> HotelBooking? { hotelBookings.first { $0.hotelName == name } }

    // MARK: Itinerary

    /// Seeded flights belong to a trip in the city they fly to, when one of its
    /// bookings carries their trip ID or its dates include them. A stay
    /// somewhere else on the same dates doesn't pick them up. They never drive tiles.
    private func flights(for trip: Trip) -> [FlightBooking] {
        let flightCity = HotelCatalog.houston
        guard trip.bookings.contains(where: { $0.city == flightCity }) else { return [] }
        let tripIds = Set(trip.hotels.compactMap(\.tripId) + trip.dinners.compactMap(\.tripId))
        return existingTrip.flights.filter { flight in
            tripIds.contains(existingTrip.tripId) || (trip.start.isOnOrBefore(flight.date) && flight.date.isOnOrBefore(trip.end))
        }
    }

    /// Every booked item in the trip, plus its flights, grouped by day and sorted by time.
    func itinerary(for trip: Trip) -> TripItinerary {
        var items = flights(for: trip).map(flightItem)
        for booking in trip.hotels { items += hotelItems(booking) }
        for dinner in trip.dinners { items.append(dinnerItem(dinner)) }
        return TripItinerary(trip: trip, items: items)
    }

    /// The existing trip before anything is booked here: its flights, and any
    /// bookings already linked to it. Shown beside the hotel search.
    func existingTripItems() -> [ItineraryDay] {
        var items = existingTrip.flights.map(flightItem)
        for booking in hotelBookings where booking.tripId == existingTrip.tripId { items += hotelItems(booking) }
        for dinner in reservations where dinner.tripId == existingTrip.tripId { items.append(dinnerItem(dinner)) }
        return ItineraryDay.grouping(items)
    }

    var existingTripHasHotel: Bool { hotelBookings.contains { $0.tripId == existingTrip.tripId } }

    private func flightItem(_ flight: FlightBooking) -> ItineraryItem {
        let arrives = "arrives \(TripCalendar.clock(flight.arrive))"
        return ItineraryItem(
            id: "flight-\(flight.id)", kind: .flight, ref: .flight(flight.id), day: flight.date, time24: flight.depart,
            title: flight.title, timelineDetail: flight.detail, line: "\(flight.flight) · \(arrives)",
            reference: "Confirmation \(flight.confirmation)",
            spoken: "\(TripCalendar.clock(flight.depart)), Flight \(flight.from) to \(flight.to), \(flight.flight), \(arrives), confirmation \(flight.confirmation)")
    }

    private func hotelItems(_ booking: HotelBooking) -> [ItineraryItem] {
        let guests = booking.adults == 1 ? "1 guest" : "\(booking.adults) guests"
        let nights = booking.nights == 1 ? "1 night" : "\(booking.nights) nights"
        let shortAddress = booking.hotelAddress.components(separatedBy: ", ").prefix(2).joined(separator: ", ")
        return [
            ItineraryItem(
                id: "in-\(booking.id)", kind: .hotelCheckIn, ref: .hotel(booking.id), day: booking.checkIn,
                time24: booking.checkInFrom, title: "Check in · \(booking.hotelName)",
                timelineDetail: "From \(TripCalendar.clock(booking.checkInFrom)) · \(booking.roomName) · \(guests)",
                line: "\(booking.roomName) · \(nights) · \(guests)",
                reference: "Confirmation \(booking.confirmationNumber)",
                isJustAdded: booking.id == justAddedId,
                spoken: "\(TripCalendar.clock(booking.checkInFrom)), check in at \(booking.hotelName), \(booking.roomName), \(nights), \(guests), confirmation \(booking.confirmationNumber)"),
            ItineraryItem(
                id: "out-\(booking.id)", kind: .hotelCheckOut, ref: .hotel(booking.id), day: booking.checkOut,
                time24: booking.checkOutBy, title: "Check out · \(booking.hotelName)",
                timelineDetail: "By \(TripCalendar.clock(booking.checkOutBy))", line: shortAddress,
                spoken: "\(TripCalendar.clock(booking.checkOutBy)), check out of \(booking.hotelName), \(shortAddress)"),
        ]
    }

    private func dinnerItem(_ dinner: DiningReservation) -> ItineraryItem {
        ItineraryItem(
            id: "dinner-\(dinner.id)", kind: .dining, ref: .dining(dinner.id), day: dinner.date, time24: dinner.time,
            title: "Dinner · \(dinner.restaurantName)",
            timelineDetail: "\(dinner.timeText) · Party of \(dinner.partySize) · \(dinner.offering)",
            line: "\(dinner.offering) · party of \(dinner.partySize)",
            reference: "Reservation \(dinner.reservationId)",
            isJustAdded: dinner.id == justAddedId,
            spoken: "\(dinner.timeText), dinner at \(dinner.restaurantName), \(dinner.offering), party of \(dinner.partySize), reservation \(dinner.reservationId)")
    }
}

// MARK: - Itinerary

struct ItineraryItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case flight, hotelCheckIn, hotelCheckOut, dining
    }

    /// The booking an item opens.
    enum Ref: Hashable {
        case hotel(String), dining(String), flight(String)
    }

    let id: String
    let kind: Kind
    let ref: Ref
    let day: Date
    /// Local start time, "15:00".
    let time24: String
    let title: String
    /// The line on the confirmation's timeline: "From 3:00 PM · Deluxe King · 2 guests".
    let timelineDetail: String
    /// The line on the itinerary: "Deluxe King · 3 nights · 2 guests".
    let line: String
    /// "Confirmation 8842-KJ71", "Reservation RES-270101-7Q3K".
    var reference: String?
    var isJustAdded = false
    /// What VoiceOver reads for the row.
    var spoken = ""

    var minutes: Int { TripCalendar.minutes(time24) }
}

struct ItineraryDay: Identifiable, Hashable {
    let day: Date
    let items: [ItineraryItem]
    /// "Day 1 of 4"; empty when the day isn't part of a trip.
    var dayOfTrip = ""

    var id: Date { day }
    /// "WED, DEC 30"
    var header: String { TripCalendar.day(day).uppercased() }
    /// "Wed, Dec 30"
    var label: String { TripCalendar.day(day) }

    /// Groups items by day and sorts them by time. Days with nothing booked are left out.
    static func grouping(_ items: [ItineraryItem], spanning range: (first: Date, last: Date)? = nil) -> [ItineraryDay] {
        let byDay = Dictionary(grouping: items, by: \.day)
        let days = byDay.keys.sorted()
        guard let first = range?.first ?? days.first, let last = range?.last ?? days.last else { return [] }
        let total = TripCalendar.nights(first, last) + 1
        return days.map { day in
            ItineraryDay(day: day, items: (byDay[day] ?? []).sorted { $0.minutes < $1.minutes },
                         dayOfTrip: "Day \(TripCalendar.nights(first, day) + 1) of \(total)")
        }
    }
}

/// A trip's itinerary: header, summary tags and days.
struct TripItinerary: Hashable {
    struct Tag: Hashable, Identifiable {
        let symbol: String
        let text: String
        var id: String { text }
    }

    let trip: Trip
    let days: [ItineraryDay]
    let tags: [Tag]

    init(trip: Trip, items: [ItineraryItem]) {
        self.trip = trip
        // The trip runs from its first item to its last, flights included.
        let first = ([trip.start] + items.map(\.day)).min() ?? trip.start
        let last = ([trip.end] + items.map(\.day)).max() ?? trip.end
        days = ItineraryDay.grouping(items, spanning: (first, last))

        let nights = trip.hotels.map(\.nights).reduce(0, +)
        let flights = items.filter { $0.kind == .flight }.count
        var tags: [Tag] = []
        func count(_ value: Int, _ one: String, _ many: String) -> String { value == 1 ? "1 \(one)" : "\(value) \(many)" }
        if nights > 0 { tags.append(Tag(symbol: "calendar", text: count(nights, "night", "nights"))) }
        if !trip.hotels.isEmpty { tags.append(Tag(symbol: "bed.double", text: count(trip.hotels.count, "stay", "stays"))) }
        if !trip.dinners.isEmpty { tags.append(Tag(symbol: "fork.knife", text: count(trip.dinners.count, "dinner", "dinners"))) }
        if flights > 0 { tags.append(Tag(symbol: "airplane", text: count(flights, "flight", "flights"))) }
        self.tags = tags
    }

    var items: [ItineraryItem] { days.flatMap(\.items) }

    /// "Dec 30, 2026 – Jan 2, 2027 · Houston, TX"
    var datesLine: String { "\(trip.datesText) · \(trip.destination)" }

    /// "Wed, Dec 30 – Sat, Jan 2 · Houston, TX": the shorter form beside a confirmation.
    var shortDatesLine: String {
        let dates = trip.start == trip.end ? TripCalendar.day(trip.start) : TripCalendar.range(trip.start, trip.end)
        return "\(dates) · \(trip.destination)"
    }
}

// MARK: - Seed data

/// docs/sample-data-day4.json: the bookings the demo can start with.
struct SeedBookings {
    let hotelHouston: HotelBooking
    let dinnerHouston: DiningReservation
    let hotelKesselhorn: HotelBooking
    let today: Date

    private struct File: Decodable {
        struct Customer: Decodable { let customerId: String }
        struct Hotel: Decodable {
            let bookingId, confirmation, status, hotelName, city, address: String
            let checkIn, checkOut, checkInTime, checkOutTime, room: String
            let guests: Int
            let tripId: String?
        }
        struct Dinner: Decodable {
            struct Deposit: Decodable {
                let totalUsd: Double
                let pointsUsed: Int
                let cardChargedUsd: Double
                let cardLast4: String
            }
            let reservationId, status, restaurantName, city, address, date, time: String
            let partySize: Int
            let tripId: String?
            let accessibilityNeeds: [String]
            let specialRequests: String?
            let dietaryNotes: String?
            let deposit: Deposit
            let policy: String
        }
        struct Bookings: Decodable {
            let hotelHouston: Hotel
            let dinnerHouston: Dinner
            let hotelKesselhorn: Hotel
        }
        let customer: Customer
        let today: String
        let bookings: Bookings
    }

    static let sample: SeedBookings = {
        guard let url = Bundle.main.url(forResource: "sample-data-day4", withExtension: "json") else {
            fatalError("sample-data-day4.json is missing from the app bundle")
        }
        do {
            let file = try JSONDecoder().decode(File.self, from: Data(contentsOf: url))
            return SeedBookings(file)
        } catch {
            fatalError("sample-data-day4.json could not be decoded: \(error)")
        }
    }()

    private init(_ file: File) {
        let day2 = HotelSampleData.sample
        today = TripCalendar.date(file.today)

        func hotel(_ seed: File.Hotel, hotelId: String, image: String, payment: (StayPrice, Tender, String)?) -> HotelBooking {
            let room = seed.room.components(separatedBy: " · ")
            return HotelBooking(
                aspireBookingId: seed.bookingId, confirmationNumber: seed.confirmation, status: seed.status,
                timestamp: TripCalendar.date(file.today), tripId: seed.tripId, customerId: file.customer.customerId,
                hotelId: hotelId, hotelName: seed.hotelName, city: seed.city, hotelAddress: seed.address,
                imageName: image, roomId: "", roomName: room.first ?? seed.room, rateId: "",
                rateName: room.dropFirst().first ?? "",
                cancellationTerms: payment == nil ? "" : day2.flexibleRatePolicy,
                cancellationSummary: payment == nil ? "" : day2.flexibleRatePolicySummary,
                checkIn: TripCalendar.date(seed.checkIn), checkOut: TripCalendar.date(seed.checkOut),
                checkInFrom: seed.checkInTime, checkOutBy: seed.checkOutTime, adults: seed.guests, rooms: 1,
                price: payment?.0, tender: payment?.1, cardLast4: payment?.2 ?? "")
        }

        // The Houston hotel as Day 2 books it: repriced, 10,000 points and the card.
        let houstonPrice = day2.repricedSamplePrice
        let houstonTender = Tender(points: day2.payment.defaultPoints,
                                   cardAmount: houstonPrice.total - Decimal(cents: day2.payment.defaultPoints))
        hotelHouston = hotel(file.bookings.hotelHouston, hotelId: day2.hotelDetails.hotelId,
                             image: HotelCatalog.hotel(id: day2.hotelDetails.hotelId)?.imageName ?? "houston",
                             payment: (houstonPrice, houstonTender, day2.customer.savedCard.last4))
        // Seeded so the demo can show two trips; its payment isn't part of the data.
        hotelKesselhorn = hotel(file.bookings.hotelKesselhorn, hotelId: "HTL-KESSELHORN",
                                image: HotelCatalog.hotel(id: "HTL-SKI-0001")?.imageName ?? "alpine", payment: nil)

        let dinner = file.bookings.dinnerHouston
        let restaurant = DiningSampleData.sample.restaurant
        dinnerHouston = DiningReservation(
            reservationId: dinner.reservationId, customerId: file.customer.customerId, tripId: dinner.tripId,
            restaurantId: restaurant.id, restaurantName: dinner.restaurantName, city: dinner.city,
            address: dinner.address, imageName: restaurant.heroImage, offering: restaurant.offeringShort,
            date: TripCalendar.date(dinner.date), time: dinner.time, partySize: dinner.partySize,
            accessibilityNeeds: dinner.accessibilityNeeds, specialRequests: dinner.specialRequests,
            dietaryNotes: dinner.dietaryNotes, depositTotal: Decimal(cents: Int((dinner.deposit.totalUsd * 100).rounded())),
            pointsUsed: dinner.deposit.pointsUsed,
            cardCharged: Decimal(cents: Int((dinner.deposit.cardChargedUsd * 100).rounded())),
            cardLast4: dinner.deposit.cardLast4, policy: DiningSampleData.sample.policy.text,
            status: dinner.status, createdAt: TripCalendar.date(file.today))
    }
}
