//
//  HotelModels.swift
//  Lifestyle · Day 2 models (Book a hotel)
//
//  Search, results, details, rooms and rates, reprice, tender and the stored
//  booking record. Money is `Decimal`, built from whole cents so sums stay exact.
//

import Foundation

// MARK: - Money and dates

extension Date {
    /// Whether this date is the same as or earlier than `other`.
    ///
    /// Compares the intervals. Built with the iOS 27.2 SDK, `<=` between two
    /// dates crashes on the iOS 27.1 simulator runtime, so date ordering goes
    /// through here.
    func isOnOrBefore(_ other: Date) -> Bool {
        timeIntervalSinceReferenceDate <= other.timeIntervalSinceReferenceDate
    }
}

extension Decimal {
    init(cents: Int) { self = Decimal(cents) / 100 }

    /// Whole cents, rounded half up.
    var cents: Int {
        var value = self * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// "$877.50"
    var usd: String {
        formatted(.currency(code: "USD").locale(.enUS))
    }

    /// "$250"
    var usdWhole: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)).locale(.enUS))
    }
}

extension Int {
    /// "12,450"
    var grouped: String { formatted(.number.grouping(.automatic).locale(.enUS)) }

    /// "12,450 pts"
    var pointsText: String { "\(grouped) pts" }
}

extension Locale {
    static let enUS = Locale(identifier: "en_US")
}

/// Trip dates are calendar days with no time zone, so they are handled in UTC.
enum TripCalendar {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = .enUS
        formatter.dateFormat = format
        return formatter
    }

    private static let iso = formatter("yyyy-MM-dd")
    private static let weekdayDay = formatter("EEE, MMM d")
    private static let weekdayDayYear = formatter("EEE, MMM d, yyyy")
    private static let monthDay = formatter("MMM d")
    private static let monthDayYear = formatter("MMM d, yyyy")
    private static let dayOnly = formatter("d")
    private static let clock24 = formatter("HH:mm")
    private static let clock12 = formatter("h:mm a")

    static func date(_ iso8601Day: String) -> Date { iso.date(from: iso8601Day) ?? .distantPast }

    /// "Wed, Dec 30"
    static func day(_ date: Date) -> String { weekdayDay.string(from: date) }

    /// "Wed, Dec 30 – Sat, Jan 2"
    static func range(_ start: Date, _ end: Date) -> String { "\(day(start)) – \(day(end))" }

    /// "Dec 30, 2026 – Jan 2, 2027"
    static func longRange(_ start: Date, _ end: Date) -> String {
        "\(monthDayYear.string(from: start)) – \(monthDayYear.string(from: end))"
    }

    /// "Dec 30 – Jan 2"
    static func shortRange(_ start: Date, _ end: Date) -> String {
        "\(monthDay.string(from: start)) – \(monthDay.string(from: end))"
    }

    /// "Fri, Jan 1, 2027"
    static func dayWithYear(_ date: Date) -> String { weekdayDayYear.string(from: date) }

    /// "Mar 14, 1988"
    static func dateWithYear(_ date: Date) -> String { monthDayYear.string(from: date) }

    /// Trip dates, as short as they can be: "Dec 30, 2026 – Jan 2, 2027",
    /// "Feb 27 – Mar 2, 2027", "Feb 12 – 16, 2027" or "Jan 1, 2027".
    static func tripRange(_ start: Date, _ end: Date) -> String {
        if start == end { return monthDayYear.string(from: start) }
        let from = calendar.dateComponents([.year, .month], from: start)
        let to = calendar.dateComponents([.year, .month], from: end)
        if from.year != to.year { return longRange(start, end) }
        if from.month != to.month { return "\(monthDay.string(from: start)) – \(monthDayYear.string(from: end))" }
        return "\(monthDay.string(from: start)) – \(dayOnly.string(from: end)), \(calendar.component(.year, from: end))"
    }

    /// The customer's local calendar day, as a trip day.
    static func today(from now: Date = .now) -> Date {
        let local = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return calendar.date(from: local) ?? now
    }

    static func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// "15:00" → ("3:00", "PM")
    static func clockParts(_ time24: String) -> (time: String, period: String) {
        let parts = clock(time24).split(separator: " ")
        return parts.count == 2 ? (String(parts[0]), String(parts[1])) : (time24, "")
    }

    static func nights(_ start: Date, _ end: Date) -> Int {
        max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
    }

    /// "15:00" → "3:00 PM"
    static func clock(_ time24: String) -> String {
        guard let date = clock24.date(from: time24) else { return time24 }
        return clock12.string(from: date)
    }

    /// Minutes after midnight, for sorting itinerary items within a day.
    static func minutes(_ time24: String) -> Int {
        let parts = time24.split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? parts[0] * 60 + parts[1] : 0
    }
}

// MARK: - Search

struct HotelSearch: Hashable {
    var destination: String
    var checkIn: Date
    var checkOut: Date
    var adults: Int
    var rooms: Int

    var nights: Int { TripCalendar.nights(checkIn, checkOut) }
    var datesText: String { TripCalendar.range(checkIn, checkOut) }
    var nightsText: String { nights == 1 ? "1 night" : "\(nights) nights" }
    var guestsText: String { adults == 1 ? "1 guest" : "\(adults) guests" }
    var adultsText: String { adults == 1 ? "1 adult" : "\(adults) adults" }
    var roomsText: String { rooms == 1 ? "1 room" : "\(rooms) rooms" }

    /// "3 nights · 2 guests · 1 room"
    var summaryText: String { "\(nightsText) · \(guestsText) · \(roomsText)" }

    /// "Houston, TX" → "Houston"
    var city: String { destination.components(separatedBy: ",").first ?? destination }

    /// For "Hotels in …": "Houston", "the Caribbean".
    var cityInSentence: String {
        city.hasPrefix("The ") ? "the " + city.dropFirst(4) : city
    }
}

struct SearchLimits: Equatable {
    var maxGuests: Int
    var maxRooms: Int
}

// MARK: - Results

struct HotelSummary: Identifiable, Hashable {
    let id: String
    let name: String
    let neighborhood: String
    let distanceMi: Double
    let rating: Double
    let ratingWord: String
    let cashPerNight: Int
    let pointsPerNight: Int
    let freeCancellation: Bool
    let imageName: String
    /// Filter attributes. The sample data doesn't carry these; the mock service adds them.
    var brand = ""
    var amenities: Set<String> = []
    var accessibility: Set<String> = []
    var distanceFromDinnerMi = 0.0
    var distanceFromAirportMi = 0.0

    var ratingText: String { rating.formatted(.number.precision(.fractionLength(1)).locale(.enUS)) }

    func distance(from origin: String) -> Double {
        switch origin {
        case HotelFilters.dinnerOrigin: distanceFromDinnerMi
        case HotelFilters.airportOrigin: distanceFromAirportMi
        default: distanceMi
        }
    }

    /// "Downtown · 0.3 mi"
    func locationText(from origin: String) -> String {
        "\(neighborhood) · \(distance(from: origin).formatted(.number.precision(.fractionLength(1)).locale(.enUS))) mi"
    }
}

enum HotelSort: String, CaseIterable, Identifiable {
    case recommended = "Recommended"
    case price = "Price"
    case rating = "Rating"

    var id: String { rawValue }

    var note: String {
        switch self {
        case .recommended: "Sorted by relevance"
        case .price: "Lowest price first"
        case .rating: "Highest rated first"
        }
    }
}

/// What the filters offer; comes with the results.
struct HotelFilterOptions: Equatable {
    var brands: [String] = []
    var priceRange: ClosedRange<Int> = 0...0
    var ratings: [String] = []
    var amenities: [String] = []
    var distanceFrom: [String] = []
    var accessibility: [String] = []
}

struct HotelFilters: Equatable {
    static let dinnerOrigin = "Your dinner"
    static let airportOrigin = "Airport"

    var brands: Set<String> = []
    var price: ClosedRange<Int>?
    var minimumRating: Double?
    var amenities: Set<String> = []
    var distanceFrom = "City center"
    var accessibility: Set<String> = []

    func matches(_ hotel: HotelSummary) -> Bool {
        if !brands.isEmpty, !brands.contains(hotel.brand) { return false }
        if let price, !price.contains(hotel.cashPerNight) { return false }
        if let minimumRating, hotel.rating < minimumRating { return false }
        if !amenities.isSubset(of: hotel.amenities) { return false }
        if !accessibility.isSubset(of: hotel.accessibility) { return false }
        return true
    }

    func apply(to hotels: [HotelSummary], sort: HotelSort) -> [HotelSummary] {
        let matching = hotels.filter(matches)
        switch sort {
        case .recommended: return matching
        case .price: return matching.sorted { $0.cashPerNight < $1.cashPerNight }
        case .rating: return matching.sorted { $0.rating > $1.rating }
        }
    }
}

// MARK: - Details, rooms and rates

struct HotelDetails: Hashable {
    struct Nearby: Hashable, Identifiable {
        let name: String
        let detail: String
        let walk: String
        var id: String { name }
        /// "6 min walk", or "12 min drive" when it is too far to walk.
        var walkText: String { walk.hasSuffix("drive") ? walk : "\(walk) walk" }
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

    /// "1200 Lamar Arcade, Houston"
    var shortAddress: String {
        address.components(separatedBy: ", ").prefix(2).joined(separator: ", ")
    }
}

struct Rate: Identifiable, Hashable {
    let id: String
    let name: String
    let cashPerNight: Decimal
    let pointsPerNight: Int
    let taxesAndFeesTotal: Decimal
    let refundable: Bool
    /// The policy exactly as the API returned it.
    let cancellationPolicy: String

    /// "Free cancellation until Mon, Dec 28, 6:00 PM" — the policy's first sentence,
    /// without the year or "hotel time".
    var policySummary: String {
        var text = cancellationPolicy.components(separatedBy: ". ").first ?? cancellationPolicy
        text = text.replacingOccurrences(of: " hotel time", with: "")
        text = text.replacingOccurrences(of: #", \d{4}"#, with: "", options: .regularExpression)
        return text.hasSuffix(".") ? String(text.dropLast()) : text
    }

    /// "Free until Mon, Dec 28, 6:00 PM"
    var policyShort: String {
        policySummary.replacingOccurrences(of: "Free cancellation until", with: "Free until")
    }
}

struct RoomType: Identifiable, Hashable {
    let id: String
    let name: String
    let beds: String
    let sleeps: Int
    let sizeSqFt: Int
    let features: [String]
    let imageName: String
    let rates: [Rate]

    /// "1 king bed · Sleeps 2 · 320 sq ft"
    var summaryText: String { "\(beds) · Sleeps \(sleeps) · \(sizeSqFt) sq ft" }
    var featuresText: String { features.joined(separator: " · ") }
}

// MARK: - Price, reprice, tender

/// A stay's price: nightly rate × nights × rooms, plus taxes and fees.
struct StayPrice: Hashable {
    let nightly: Decimal
    let nights: Int
    let rooms: Int
    let taxesAndFees: Decimal

    var subtotal: Decimal { nightly * Decimal(nights) * Decimal(rooms) }
    var total: Decimal { subtotal + taxesAndFees }
    /// 100 points = $1.
    var totalInPoints: Int { total.cents }

    /// "3 nights × $250.00"
    var nightsLine: String {
        let nightsText = nights == 1 ? "1 night" : "\(nights) nights"
        return rooms > 1 ? "\(nightsText) × \(nightly.usd) × \(rooms) rooms" : "\(nightsText) × \(nightly.usd)"
    }
}

enum RepriceChange: Hashable {
    case price, room, cancellationTerms
}

enum RepriceResult: Hashable {
    case unchanged(StayPrice)
    case changed(old: StayPrice, new: StayPrice, changes: Set<RepriceChange>)
    case unavailable

    /// The price to charge, when the room can still be booked.
    var price: StayPrice? {
        switch self {
        case .unchanged(let price): price
        case .changed(_, let new, _): new
        case .unavailable: nil
        }
    }

    var requiresAcceptance: Bool {
        if case .changed = self { return true }
        return false
    }
}

struct Tender: Hashable {
    var points: Int
    var cardAmount: Decimal

    /// Value of the points at 100 points = $1.
    var pointsValue: Decimal { Decimal(cents: points) }
}

struct PaymentCard: Hashable {
    var label: String
    var last4: String
    var isSaved = true

    /// "Card ···· 4821"
    var maskedText: String { "Card ···· \(last4)" }
}

// MARK: - Booking record

/// What is stored once Aspire confirms: IDs, status, rate, cancellation terms,
/// amounts, payment, timestamp, and the trip and customer it belongs to.
struct HotelBooking: Identifiable, Hashable {
    let aspireBookingId: String
    let confirmationNumber: String
    let status: String
    let timestamp: Date
    /// The existing trip the booking was linked to, when its dates fall in one.
    let tripId: String?
    let customerId: String

    let hotelId: String
    let hotelName: String
    /// "Houston, TX"
    let city: String
    let hotelAddress: String
    let imageName: String
    let roomId: String
    let roomName: String
    let rateId: String
    let rateName: String
    let cancellationTerms: String
    let cancellationSummary: String

    let checkIn: Date
    let checkOut: Date
    let checkInFrom: String
    let checkOutBy: String
    let adults: Int
    let rooms: Int

    /// Amounts and payment. Nil for bookings seeded without them.
    let price: StayPrice?
    let tender: Tender?
    let cardLast4: String

    var id: String { aspireBookingId }
    var nights: Int { TripCalendar.nights(checkIn, checkOut) }
}

struct BookingRequest: Hashable {
    let hotelId: String
    let roomId: String
    let rateId: String
    let search: HotelSearch
    let price: StayPrice
    let tender: Tender
    let card: PaymentCard
    let tripId: String?
    let customerId: String
}

// MARK: - Trip

struct FlightBooking: Hashable, Identifiable {
    let flight: String
    let from: String
    let to: String
    let date: Date
    let depart: String
    let arrive: String
    let confirmation: String
    var tripId: String?

    var id: String { "\(flight)-\(depart)" }
    var title: String { "Flight \(from) → \(to)" }
    /// "Coast Air 1015 · 10:15 AM – 4:05 PM"
    var detail: String { "\(flight) · \(TripCalendar.clock(depart)) – \(TripCalendar.clock(arrive))" }
}

/// The existing trip. Seeded for the demo: flight booking isn't in the POC.
struct TripRecord: Hashable {
    let tripId: String
    let title: String
    let start: Date
    let end: Date
    let travelers: Int
    let flights: [FlightBooking]

    /// "Wed, Dec 30 – Sat, Jan 2 · 2 travelers"
    var subtitle: String {
        "\(TripCalendar.range(start, end)) · \(travelers) \(travelers == 1 ? "traveler" : "travelers")"
    }
}
