//
//  DiningService.swift
//  Lifestyle · Day 3 · one static restaurant, hard-coded tables, and its mock
//
//  No restaurant API and no table is really held. Hours, tables and the other
//  guests' bookings are seed data. Table counts live in memory for the session.
//

import Foundation

// MARK: - Models

struct Restaurant: Hashable {
    struct Course: Hashable, Identifiable {
        let course: Int
        let dish: String
        let detail: String
        var id: Int { course }
    }

    let id: String
    let name: String
    /// "Houston, TX"
    let city: String
    let address: String
    let timeZone: String
    let chef: String
    let cuisine: String
    let about: String
    let heroImage: String
    let menuImage: String
    /// "New Year's Day Chef's Table"
    let offering: String
    let menu: [Course]
    let menuNote: String
    let nearbyName: String
    let nearbyWalk: String

    /// "Chef’s table": the offering, as it reads on a tag or an itinerary line.
    var offeringShort: String { offering.lowercased().contains("chef") ? "Chef’s table" : offering }

    /// "1420 Calder Row, Houston"
    var shortAddress: String { address.components(separatedBy: ", ").prefix(2).joined(separator: ", ") }

    /// "Houston"
    var cityName: String { Trip.cityName(city) }
}

/// Hard-coded hours and tables for the POC.
struct DiningSetup: Hashable {
    let date: Date
    let open: String
    let close: String
    let startTimes: [String]
    let tablesPerStartTime: Int
    let tableSizeByStartTime: [String: Int]
    let maxPartySize: Int
    let depositPerPerson: Decimal
    let seatingLengthHours: Int

    /// "Fri, Jan 1"
    var dayText: String { TripCalendar.day(date) }
    /// "Fri, Jan 1, 2027"
    var dayWithYearText: String { TripCalendar.dayWithYear(date) }
    /// "5:00 – 11:00 PM"
    var hoursText: String { Self.span(open, close) }
    /// "5:00 – 10:00 PM"
    var seatingsText: String { Self.span(startTimes.first ?? open, startTimes.last ?? close) }

    private static func span(_ from: String, _ to: String) -> String {
        let start = TripCalendar.clockParts(from)
        let end = TripCalendar.clockParts(to)
        return start.period == end.period
            ? "\(start.time) – \(end.time) \(end.period)"
            : "\(start.time) \(start.period) – \(end.time) \(end.period)"
    }
}

/// A start time and the tables still open at it.
struct Slot: Identifiable, Hashable {
    /// "20:00"
    let id: String
    let tableSize: Int
    var tablesLeft: Int

    var timeText: String { TripCalendar.clock(id) }
    var isSoldOut: Bool { tablesLeft <= 0 }
    var leftText: String { isSoldOut ? "Sold out" : (tablesLeft == 1 ? "1 table left" : "\(tablesLeft) tables left") }
}

struct ReservationRequest: Hashable {
    let restaurantId: String
    let date: Date
    let time: String
    let partySize: Int
    let guestName: String
    let guestEmail: String
    let guestPhone: String
    let accessibilityNeeds: [String]
    let specialRequests: String?
    let dietaryNotes: String?
    let tender: Tender
    let card: PaymentCard
    let customerId: String
    let tripId: String?
}

/// The steps of a reservation, in the order they happen.
enum ReserveStep: Hashable {
    case chargingCard, confirmingTable, deductingPoints
}

enum DiningError: Error, Equatable {
    /// The card was declined: nothing reserved, no count change, no points deducted.
    case paymentDeclined
    /// The last table went while the customer was checking out: nothing charged.
    case soldOut(time: String)
    /// The customer already holds a table that overlaps this one.
    case overlap(existingId: String)
}

protocol DiningService {
    var restaurant: Restaurant { get }
    var setup: DiningSetup { get }
    var policyText: String { get }

    /// Every start time with its table size and open tables.
    func slots() async throws -> [Slot]

    /// Reserves in order: recheck availability, check overlap, charge the card,
    /// create the reservation and lower that time's count. Points are deducted
    /// by the caller once this returns. A repeat with the same key returns the
    /// first result and changes nothing.
    func reserve(_ request: ReservationRequest, holding existing: [DiningReservation], idempotencyKey: UUID,
                 progress: @escaping (ReserveStep) -> Void) async throws -> DiningReservation
}

/// Which outcome the mock gives when a reservation is submitted.
enum DiningScenario: String, CaseIterable, Identifiable {
    case success, paymentDeclined, soldOutAtConfirm, overlap

    var id: String { rawValue }

    var label: String {
        switch self {
        case .success: "Succeeds"
        case .paymentDeclined: "Card declined once"
        case .soldOutAtConfirm: "Sells out at confirm"
        case .overlap: "Already has a 7:00 PM table"
        }
    }
}

// MARK: - Sample data

/// docs/sample-data-day3.json.
struct DiningSampleData: Decodable {
    struct Customer: Decodable {
        let customerId: String
        let name: String
        let email: String
        let phone: String
    }

    struct RestaurantRecord: Decodable {
        struct Images: Decodable { let hero, menu: String }
        struct Course: Decodable { let course: Int; let dish, detail: String }
        struct Nearby: Decodable { let name, walk: String }
        let restaurantId, name, city, address, timeZone, chef, cuisine, about, offering, menuNote: String
        let images: Images
        let menu: [Course]
        let nearby: Nearby
    }

    struct Setup: Decodable {
        struct Hours: Decodable { let open, close: String }
        let openHours: Hours
        let availableDate: String
        let startTimes: [String]
        let tablesPerStartTime: Int
        let tableSizeByStartTime: [String: Int]
        let maxPartySize: Int
        let depositPerPersonUsd: Int
        let seatingLengthHours: Int
    }

    struct Policy: Decodable { let text: String }

    /// The request the designs show.
    struct SampleRequest: Decodable {
        let time: String
        let partySize: Int
        let accessibilityNeeds: [String]
        let specialRequests: String?
        let dietaryNotes: String?
    }

    struct Result: Decodable { let reservationId, status: String }

    struct Validation: Decodable {
        struct OverlapDemo: Decodable {
            struct Existing: Decodable { let date, time, reservationId: String }
            let existing: Existing
        }
        let overlapDemo: OverlapDemo
    }

    private struct SeededKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    let customer: Customer
    private let restaurantRecord: RestaurantRecord
    private let setupRecord: Setup
    /// Confirmed bookings by other guests at each start time.
    let seededBookings: [String: Int]
    let policy: Policy
    let reservationResult: Result
    let validation: Validation
    let sampleRequest: SampleRequest

    private enum CodingKeys: String, CodingKey {
        case customer, policy, reservationResult, validation
        case sampleRequest = "reservationRequest"
        case restaurantRecord = "restaurant"
        case setupRecord = "setup"
        case seededBookings = "seededBookingsByOtherGuests"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customer = try container.decode(Customer.self, forKey: .customer)
        restaurantRecord = try container.decode(RestaurantRecord.self, forKey: .restaurantRecord)
        setupRecord = try container.decode(Setup.self, forKey: .setupRecord)
        policy = try container.decode(Policy.self, forKey: .policy)
        reservationResult = try container.decode(Result.self, forKey: .reservationResult)
        validation = try container.decode(Validation.self, forKey: .validation)
        sampleRequest = try container.decode(SampleRequest.self, forKey: .sampleRequest)
        // The seeded counts sit beside a "note" string, so read them key by key.
        let seeded = try container.nestedContainer(keyedBy: SeededKey.self, forKey: .seededBookings)
        var counts: [String: Int] = [:]
        for key in seeded.allKeys {
            if let count = try? seeded.decode(Int.self, forKey: key) { counts[key.stringValue] = count }
        }
        seededBookings = counts
    }

    static let sample: DiningSampleData = {
        guard let url = Bundle.main.url(forResource: "sample-data-day3", withExtension: "json") else {
            fatalError("sample-data-day3.json is missing from the app bundle")
        }
        do {
            return try JSONDecoder().decode(DiningSampleData.self, from: Data(contentsOf: url))
        } catch {
            fatalError("sample-data-day3.json could not be decoded: \(error)")
        }
    }()

    var restaurant: Restaurant {
        let record = restaurantRecord
        return Restaurant(
            id: record.restaurantId, name: record.name, city: record.city, address: record.address,
            timeZone: record.timeZone, chef: record.chef, cuisine: record.cuisine, about: record.about,
            heroImage: record.images.hero, menuImage: record.images.menu, offering: record.offering,
            menu: record.menu.map { .init(course: $0.course, dish: $0.dish, detail: $0.detail) },
            menuNote: record.menuNote, nearbyName: record.nearby.name, nearbyWalk: record.nearby.walk)
    }

    var setup: DiningSetup {
        let record = setupRecord
        return DiningSetup(
            date: TripCalendar.date(record.availableDate), open: record.openHours.open, close: record.openHours.close,
            startTimes: record.startTimes, tablesPerStartTime: record.tablesPerStartTime,
            tableSizeByStartTime: record.tableSizeByStartTime, maxPartySize: record.maxPartySize,
            depositPerPerson: Decimal(record.depositPerPersonUsd), seatingLengthHours: record.seatingLengthHours)
    }

    /// The table the customer already holds in the overlap demo: a 7:00 PM 2-top.
    func overlapDemoReservation(customerId: String, tripId: String?) -> DiningReservation {
        let existing = validation.overlapDemo.existing
        let restaurant = restaurant
        let party = setup.tableSizeByStartTime[existing.time] ?? 2
        let deposit = setup.depositPerPerson * Decimal(party)
        return DiningReservation(
            reservationId: existing.reservationId, customerId: customerId, tripId: tripId,
            restaurantId: restaurant.id, restaurantName: restaurant.name, city: restaurant.city,
            address: restaurant.address, imageName: restaurant.heroImage, offering: restaurant.offeringShort,
            date: TripCalendar.date(existing.date), time: existing.time, partySize: party,
            accessibilityNeeds: [], specialRequests: nil, dietaryNotes: nil, depositTotal: deposit,
            pointsUsed: 0, cardCharged: deposit, cardLast4: HotelSampleData.sample.customer.savedCard.last4,
            policy: policy.text, status: reservationResult.status, createdAt: .now)
    }
}

// MARK: - Mock

final class MockDiningService: DiningService {
    private let data: DiningSampleData
    let restaurant: Restaurant
    let setup: DiningSetup
    var scenario: DiningScenario
    /// Zero in previews and screenshots.
    var delayScale: Double

    /// Confirmed bookings at each start time: other guests' (seeded) plus the customer's.
    private var confirmed: [String: Int]
    private var reservationsByKey: [UUID: DiningReservation] = [:]
    private var declinesRemaining: Int

    init(data: DiningSampleData = .sample, scenario: DiningScenario = .success, delayScale: Double = 1) {
        self.data = data
        self.scenario = scenario
        self.delayScale = delayScale
        restaurant = data.restaurant
        setup = data.setup
        confirmed = data.seededBookings
        declinesRemaining = scenario == .paymentDeclined ? 1 : 0
    }

    var policyText: String { data.policy.text }

    /// Counts a table the customer already holds (seeded demo bookings).
    func count(_ reservation: DiningReservation) {
        confirmed[reservation.time, default: 0] += 1
    }

    /// Debug: puts the table counts back to the seed data.
    func resetCounts() {
        confirmed = data.seededBookings
        reservationsByKey = [:]
    }

    private func wait(_ milliseconds: Int) async throws {
        guard delayScale > 0 else { return }
        try await Task.sleep(for: .milliseconds(Int(Double(milliseconds) * delayScale)))
    }

    private func tablesLeft(at time: String) -> Int {
        max(setup.tablesPerStartTime - (confirmed[time] ?? 0), 0)
    }

    func slots() async throws -> [Slot] {
        try await wait(500)
        return setup.startTimes.map { time in
            Slot(id: time, tableSize: setup.tableSizeByStartTime[time] ?? 0, tablesLeft: tablesLeft(at: time))
        }
    }

    func reserve(_ request: ReservationRequest, holding existing: [DiningReservation], idempotencyKey: UUID,
                 progress: @escaping (ReserveStep) -> Void) async throws -> DiningReservation {
        // A repeat of the same request returns the reservation it already made.
        if let made = reservationsByKey[idempotencyKey] { return made }

        // 1. Recheck availability: tables aren't held during checkout.
        try await wait(400)
        if scenario == .soldOutAtConfirm {
            confirmed[request.time] = setup.tablesPerStartTime
        }
        guard tablesLeft(at: request.time) > 0 else { throw DiningError.soldOut(time: request.time) }

        // 2. Block a table that overlaps one the customer already holds.
        if let clash = existing.first(where: { Self.overlaps($0, date: request.date, time: request.time, hours: setup.seatingLengthHours) }) {
            throw DiningError.overlap(existingId: clash.id)
        }

        // 3. Charge the card (simulated).
        if request.tender.cardAmount > 0 {
            progress(.chargingCard)
            try await wait(900)
            if declinesRemaining > 0 {
                declinesRemaining -= 1
                throw DiningError.paymentDeclined
            }
        }

        // 4. Create the reservation and lower that time's count.
        progress(.confirmingTable)
        try await wait(900)
        if let made = reservationsByKey[idempotencyKey] { return made }
        let reservation = DiningReservation(
            // The first reservation uses the sample's ID; later ones get their own.
            reservationId: reservationsByKey.isEmpty ? data.reservationResult.reservationId : Self.makeId(for: request.date),
            customerId: request.customerId, tripId: request.tripId, restaurantId: restaurant.id,
            restaurantName: restaurant.name, city: restaurant.city, address: restaurant.address,
            imageName: restaurant.heroImage, offering: restaurant.offeringShort, date: request.date,
            time: request.time, partySize: request.partySize, accessibilityNeeds: request.accessibilityNeeds,
            specialRequests: request.specialRequests, dietaryNotes: request.dietaryNotes,
            depositTotal: setup.depositPerPerson * Decimal(request.partySize), pointsUsed: request.tender.points,
            cardCharged: request.tender.cardAmount, cardLast4: request.card.last4, policy: data.policy.text,
            status: data.reservationResult.status, createdAt: .now)
        reservationsByKey[idempotencyKey] = reservation
        confirmed[request.time, default: 0] += 1

        // 5. Points come off only now that the table is confirmed.
        if request.tender.points > 0 {
            progress(.deductingPoints)
            try await wait(900)
        }
        return reservation
    }

    /// Two seatings on the same date clash when they start less than a seating length apart.
    static func overlaps(_ existing: DiningReservation, date: Date, time: String, hours: Int) -> Bool {
        guard existing.date == date else { return false }
        return abs(TripCalendar.minutes(existing.time) - TripCalendar.minutes(time)) < hours * 60
    }

    /// `RES-yymmdd-XXXX`: the reservation date, then 4 characters from A–Z and 2–9
    /// without O, I, 0 or 1.
    static func makeId(for date: Date) -> String {
        let parts = TripCalendar.calendar.dateComponents([.year, .month, .day], from: date)
        let stamp = String(format: "%02d%02d%02d", (parts.year ?? 0) % 100, parts.month ?? 0, parts.day ?? 0)
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = String((0..<4).map { _ in alphabet.randomElement() ?? "A" })
        return "RES-\(stamp)-\(suffix)"
    }
}
