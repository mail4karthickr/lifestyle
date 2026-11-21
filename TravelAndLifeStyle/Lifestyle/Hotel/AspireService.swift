//
//  AspireService.swift
//  Lifestyle · Day 2 hotel API and its mock
//
//  The mock reads sample-data-day2.json, adds delays, and has a scenario switch
//  for reprice (Price changed / No change / Room unavailable) and for a booking
//  failure, so every state can be demoed. No network calls.
//

import Foundation

protocol AspireService {
    /// Guest and room limits for a booking.
    var limits: SearchLimits { get }
    var filterOptions: HotelFilterOptions { get }
    /// Destinations that have hotels, in the order the search offers them.
    var destinations: [String] { get }

    func search(_ search: HotelSearch) async throws -> [HotelSummary]
    func details(hotelId: String) async throws -> HotelDetails
    func rooms(hotelId: String, search: HotelSearch) async throws -> [RoomType]
    func reprice(rateId: String, search: HotelSearch) async throws -> RepriceResult
    /// Books the rate. Calling again with the same key returns the same booking.
    func book(_ request: BookingRequest, idempotencyKey: UUID) async throws -> HotelBooking
}

enum AspireError: Error {
    /// The hotel has no details or rooms in the sample data.
    case notInSample
    /// The booking response never arrived.
    case timedOut
}

/// Which responses the mock gives.
struct AspireScenario: Equatable {
    enum Reprice: String, CaseIterable, Identifiable {
        case priceChanged, noChange, roomUnavailable
        var id: String { rawValue }
        var label: String {
            switch self {
            case .priceChanged: "Price changed"
            case .noChange: "No change"
            case .roomUnavailable: "Room unavailable"
            }
        }
    }

    enum Booking: String, CaseIterable, Identifiable {
        case succeeds, failsOnce
        var id: String { rawValue }
        var label: String { self == .succeeds ? "Succeeds" : "Fails once" }
    }

    var reprice: Reprice = .priceChanged
    var booking: Booking = .succeeds
    /// Zero in previews and screenshots.
    var delayScale: Double = 1
}

// MARK: - Sample data

/// docs/sample-data-day2.json.
struct HotelSampleData: Decodable {
    struct Customer: Decodable {
        struct SavedCard: Decodable {
            let label: String
            let last4: String
        }
        let customerId: String
        let name: String
        let rewardsBalancePoints: Int
        let pointsPerDollar: Int
        let savedCard: SavedCard
    }

    struct Trip: Decodable {
        struct Flight: Decodable {
            let flight, from, to, date, depart, arrive, confirmation: String
        }
        let tripId: String
        let title: String
        let start: String
        let end: String
        let travelers: Int
        let flights: [Flight]
    }

    struct Search: Decodable {
        struct Limits: Decodable {
            let maxGuests: Int
            let maxRooms: Int
        }
        let destination: String
        let checkIn: String
        let checkOut: String
        let nights: Int
        let adults: Int
        let rooms: Int
        let limits: Limits
    }

    struct Results: Decodable {
        struct Hotel: Decodable {
            let hotelId: String
            let name: String
            let neighborhood: String
            let distanceMiFromCityCenter: Double
            let rating: Double
            let ratingWord: String
            let cashPerNight: Int
            let pointsPerNight: Int
            let freeCancellationAvailable: Bool
            let image: String
        }
        struct Filters: Decodable {
            let brand: [String]
            let priceRangePerNight: [Int]
            let rating: [String]
            let amenities: [String]
            let distanceFrom: [String]
            let accessibility: [String]
        }
        let hotels: [Hotel]
        let filters: Filters
    }

    struct Details: Decodable {
        struct Nearby: Decodable {
            let name, detail, walk: String
        }
        let hotelId: String
        let name: String
        let address: String
        let rating: Double
        let ratingWord: String
        let reviews: Int
        let photos: Int
        let amenities: [String]
        let about: String
        let nearby: [Nearby]
        let checkInFrom: String
        let checkOutBy: String
    }

    struct Room: Decodable {
        struct Rate: Decodable {
            let rateId: String
            let name: String
            let cashPerNight: Int
            let pointsPerNight: Int
            let taxesAndFeesTotal: Double
            let refundable: Bool
            let cancellationPolicy: String
        }
        let roomId: String
        let name: String
        let beds: String
        let sleeps: Int
        let sizeSqFt: Int
        let features: [String]
        let image: String
        let rates: [Rate]
    }

    struct RepriceScenario: Decodable {
        let rateId: String?
        let oldCashPerNight: Int?
        let newCashPerNight: Int?
    }

    struct Payment: Decodable {
        let defaultPoints: Int
        let pointsStep: Int
    }

    struct Booking: Decodable {
        let aspireBookingId: String
        let confirmationNumber: String
        let status: String
        let timestamp: String
        let tripId: String
    }

    let customer: Customer
    let existingTrip: Trip
    let search: Search
    let results: Results
    let hotelDetails: Details
    let rooms: [Room]
    let taxRateForMocks: Double
    let repriceScenarios: [String: RepriceScenario]
    let payment: Payment
    let booking: Booking

    static let sample: HotelSampleData = {
        guard let url = Bundle.main.url(forResource: "sample-data-day2", withExtension: "json") else {
            fatalError("sample-data-day2.json is missing from the app bundle")
        }
        do {
            return try JSONDecoder().decode(HotelSampleData.self, from: Data(contentsOf: url))
        } catch {
            fatalError("sample-data-day2.json could not be decoded: \(error)")
        }
    }()

    var trip: TripRecord {
        TripRecord(
            tripId: existingTrip.tripId,
            title: existingTrip.title,
            start: TripCalendar.date(existingTrip.start),
            end: TripCalendar.date(existingTrip.end),
            travelers: existingTrip.travelers,
            flights: existingTrip.flights.map {
                FlightBooking(flight: $0.flight, from: $0.from, to: $0.to, date: TripCalendar.date($0.date),
                              depart: $0.depart, arrive: $0.arrive, confirmation: $0.confirmation,
                              tripId: existingTrip.tripId)
            })
    }

    /// The search the trip prefills: its destination, dates and travelers.
    var tripSearch: HotelSearch {
        HotelSearch(destination: search.destination,
                    checkIn: TripCalendar.date(search.checkIn),
                    checkOut: TripCalendar.date(search.checkOut),
                    adults: search.adults,
                    rooms: search.rooms)
    }

    var savedCard: PaymentCard {
        PaymentCard(label: customer.savedCard.label, last4: customer.savedCard.last4)
    }

    /// The cancellation policy of the sample's flexible rate, as the API returns it.
    var flexibleRatePolicy: String {
        rooms.flatMap(\.rates).first(where: \.refundable)?.cancellationPolicy ?? ""
    }

    var flexibleRatePolicySummary: String {
        Rate(id: "", name: "", cashPerNight: 0, pointsPerNight: 0, taxesAndFeesTotal: 0, refundable: true,
             cancellationPolicy: flexibleRatePolicy).policySummary
    }

    /// The sample stay after reprice: $255 × 3 nights plus taxes and fees.
    var repricedSamplePrice: StayPrice {
        let nightly = Decimal(repriceScenarios["Price changed"]?.newCashPerNight ?? 0)
        let subtotal = nightly * Decimal(search.nights) * Decimal(search.rooms)
        return StayPrice(nightly: nightly, nights: search.nights, rooms: search.rooms,
                         taxesAndFees: Decimal(cents: (subtotal * Decimal(taxRateForMocks)).cents))
    }
}

private func assetName(_ path: String) -> String {
    URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
}

// MARK: - Mock

final class MockAspireService: AspireService {
    private let data: HotelSampleData
    var scenario: AspireScenario

    /// Bookings Aspire has made, by idempotency key.
    private var bookingsByKey: [UUID: HotelBooking] = [:]
    private var bookingFailuresRemaining: Int

    init(data: HotelSampleData = .sample, scenario: AspireScenario = AspireScenario()) {
        self.data = data
        self.scenario = scenario
        bookingFailuresRemaining = scenario.booking == .failsOnce ? 1 : 0
    }

    /// How many bookings exist, for checking that a repeat submission made no duplicate.
    var bookingCount: Int { bookingsByKey.count }

    var limits: SearchLimits {
        SearchLimits(maxGuests: data.search.limits.maxGuests, maxRooms: data.search.limits.maxRooms)
    }

    var filterOptions: HotelFilterOptions {
        let filters = data.results.filters
        let low = filters.priceRangePerNight.first ?? 0
        let high = filters.priceRangePerNight.last ?? low
        return HotelFilterOptions(brands: filters.brand, priceRange: low...high, ratings: filters.rating,
                                  amenities: filters.amenities, distanceFrom: filters.distanceFrom,
                                  accessibility: filters.accessibility)
    }

    private func wait(_ milliseconds: Int) async throws {
        guard scenario.delayScale > 0 else { return }
        try await Task.sleep(for: .milliseconds(Int(Double(milliseconds) * scenario.delayScale)))
    }

    var destinations: [String] { HotelCatalog.destinations }

    // Every hotel in the catalog can be searched, opened and booked. The sample's
    // own hotel keeps its details and rates exactly as the sample data has them.
    func search(_ search: HotelSearch) async throws -> [HotelSummary] {
        try await wait(900)
        return HotelCatalog.hotels(in: search.destination).map(\.summary)
    }

    func details(hotelId: String) async throws -> HotelDetails {
        try await wait(500)
        let details = data.hotelDetails
        if hotelId == details.hotelId {
            return HotelDetails(
                hotelId: details.hotelId, name: details.name, address: details.address, rating: details.rating,
                ratingWord: details.ratingWord, reviews: details.reviews, photos: details.photos,
                amenities: details.amenities, about: details.about,
                nearby: details.nearby.map { .init(name: $0.name, detail: $0.detail, walk: $0.walk) },
                checkInFrom: details.checkInFrom, checkOutBy: details.checkOutBy)
        }
        guard let hotel = HotelCatalog.hotel(id: hotelId) else { throw AspireError.notInSample }
        return HotelDetails(
            hotelId: hotel.id, name: hotel.name, address: hotel.address, rating: hotel.rating,
            ratingWord: hotel.ratingWord, reviews: hotel.reviews, photos: data.rooms.count + 1,
            amenities: hotel.amenityList, about: hotel.about, nearby: hotel.nearby,
            checkInFrom: details.checkInFrom, checkOutBy: details.checkOutBy)
    }

    /// The rooms and rates of a hotel. The sample's hotel uses the sample's
    /// rates. Any other hotel offers the same room types, priced in proportion
    /// to its own nightly rate, with a policy dated from the stay; a hotel with
    /// no free cancellation offers one non-refundable rate per room.
    private func rates(hotelId: String, search: HotelSearch) throws -> [(room: HotelSampleData.Room, rates: [Rate])] {
        if hotelId == data.hotelDetails.hotelId {
            return data.rooms.map { room in
                (room, room.rates.map { rate in
                    let nightly = Decimal(rate.cashPerNight)
                    return Rate(id: rate.rateId, name: rate.name, cashPerNight: nightly, pointsPerNight: rate.cashPerNight * 100,
                                taxesAndFeesTotal: taxes(nightly: nightly, search: search),
                                refundable: rate.refundable, cancellationPolicy: rate.cancellationPolicy)
                })
            }
        }
        guard let hotel = HotelCatalog.hotel(id: hotelId) else { throw AspireError.notInSample }
        let sampleBase = data.results.hotels.first { $0.hotelId == data.hotelDetails.hotelId }?.cashPerNight ?? 1
        let cutoff = TripCalendar.adding(days: -2, to: search.checkIn)
        let flexiblePolicy = "Free cancellation until \(TripCalendar.dayWithYear(cutoff)), 6:00 PM hotel time. After that, the first night is charged."
        return data.rooms.map { room in
            let offered = hotel.freeCancellation ? room.rates : Array(room.rates.prefix(1))
            return (room, offered.map { rate in
                // Whole dollars, in the same proportion as the sample's rates.
                let dollars = Int((Double(hotel.cashPerNight) * Double(rate.cashPerNight) / Double(sampleBase)).rounded())
                let nightly = Decimal(dollars)
                let refundable = hotel.freeCancellation && rate.refundable
                return Rate(id: "\(hotel.id)/\(rate.rateId)",
                            name: hotel.freeCancellation ? rate.name : "Standard rate",
                            cashPerNight: nightly, pointsPerNight: dollars * 100,
                            taxesAndFeesTotal: taxes(nightly: nightly, search: search), refundable: refundable,
                            cancellationPolicy: refundable ? flexiblePolicy : "Non-refundable.")
            })
        }
    }

    func rooms(hotelId: String, search: HotelSearch) async throws -> [RoomType] {
        try await wait(700)
        return try rates(hotelId: hotelId, search: search).map { room, rates in
            RoomType(id: room.roomId, name: room.name, beds: room.beds, sleeps: room.sleeps, sizeSqFt: room.sizeSqFt,
                     features: room.features, imageName: HotelCatalog.roomPhoto(assetName(room.image), hotelId: hotelId), rates: rates)
        }
    }

    /// The hotel a rate belongs to: "HTL-MIA-0007/RT-DK-FLEX" or the sample's "RT-DK-FLEX".
    private func hotelId(ofRate rateId: String) -> String {
        rateId.contains("/") ? String(rateId.prefix { $0 != "/" }) : data.hotelDetails.hotelId
    }

    func reprice(rateId: String, search: HotelSearch) async throws -> RepriceResult {
        try await wait(1400)
        let all = (try? rates(hotelId: hotelId(ofRate: rateId), search: search))?.flatMap(\.rates) ?? []
        guard let rate = all.first(where: { $0.id == rateId }) else { return .unavailable }
        let old = price(nightly: rate.cashPerNight, search: search)
        switch scenario.reprice {
        case .roomUnavailable:
            return .unavailable
        case .noChange:
            return .unchanged(old)
        case .priceChanged:
            // The sample's price change is for one rate; the others come back unchanged.
            guard let change = data.repriceScenarios["Price changed"], change.rateId == rateId,
                  let newNightly = change.newCashPerNight else {
                return .unchanged(old)
            }
            return .changed(old: old, new: price(nightly: Decimal(newNightly), search: search), changes: [.price])
        }
    }

    func book(_ request: BookingRequest, idempotencyKey: UUID) async throws -> HotelBooking {
        try await wait(2400)
        // A repeat of the same request returns the booking it already made.
        if let existing = bookingsByKey[idempotencyKey] { return existing }

        let offered = try rates(hotelId: request.hotelId, search: request.search)
        guard let (room, rates) = offered.first(where: { $0.room.roomId == request.roomId }),
              let rate = rates.first(where: { $0.id == request.rateId }),
              let hotel = HotelCatalog.hotel(id: request.hotelId) else {
            throw AspireError.notInSample
        }
        let details = data.hotelDetails
        let sequence = bookingsByKey.count
        let booking = HotelBooking(
            // The first booking uses the sample's IDs; later ones get their own.
            aspireBookingId: sequence == 0 ? data.booking.aspireBookingId : "ASP-\(30418872 + sequence)",
            confirmationNumber: sequence == 0 ? data.booking.confirmationNumber : "\(8842 + sequence)-KJ71",
            status: data.booking.status,
            timestamp: .now,
            tripId: request.tripId,
            customerId: request.customerId,
            hotelId: request.hotelId,
            hotelName: hotel.name,
            city: hotel.city,
            hotelAddress: hotel.address,
            imageName: hotel.imageName,
            roomId: room.roomId,
            roomName: room.name,
            rateId: rate.id,
            rateName: rate.name,
            cancellationTerms: rate.cancellationPolicy,
            cancellationSummary: rate.policySummary,
            checkIn: request.search.checkIn,
            checkOut: request.search.checkOut,
            checkInFrom: details.checkInFrom,
            checkOutBy: details.checkOutBy,
            adults: request.search.adults,
            rooms: request.search.rooms,
            price: request.price,
            tender: request.tender,
            cardLast4: request.card.last4)
        bookingsByKey[idempotencyKey] = booking

        // "Fails once": Aspire made the booking but the response is lost, so the
        // retry has to find it by its key rather than book again.
        if bookingFailuresRemaining > 0 {
            bookingFailuresRemaining -= 1
            throw AspireError.timedOut
        }
        return booking
    }

    // MARK: Mock maths

    /// Taxes in the mocks: a fixed share of the room subtotal, rounded to the cent.
    private func taxes(nightly: Decimal, search: HotelSearch) -> Decimal {
        let subtotal = nightly * Decimal(search.nights) * Decimal(search.rooms)
        return Decimal(cents: (subtotal * Decimal(data.taxRateForMocks)).cents)
    }

    private func price(nightly: Decimal, search: HotelSearch) -> StayPrice {
        StayPrice(nightly: nightly, nights: search.nights, rooms: search.rooms,
                  taxesAndFees: taxes(nightly: nightly, search: search))
    }
}
