//
//  TravelPreferences.swift
//  Lifestyle · Day 5 · the travel profile, its catalog and its mock service
//
//  One record per customer, keyed by ECN. Every field is optional and each
//  change is saved on its own. The mock keeps the record in UserDefaults, so it
//  survives an app relaunch.
//

import Foundation

// MARK: - Preferences

struct TravelPreferences: Codable, Equatable {
    var brands = Brands()
    var dining = Dining()
    var traveler = Traveler()

    struct Brands: Codable, Equatable {
        var hotelBrandIds: [String] = []
        var airlineIds: [String] = []
        var venueIds: [String] = []
        var restaurantIds: [String] = []

        var isEmpty: Bool { hotelBrandIds.isEmpty && airlineIds.isEmpty && venueIds.isEmpty && restaurantIds.isEmpty }
    }

    struct Dining: Codable, Equatable {
        var cuisines: [String] = []
        var dietaryNeeds: [String] = []
        var priceRange: String?

        var isEmpty: Bool { cuisines.isEmpty && dietaryNeeds.isEmpty && priceRange == nil }
    }

    /// Documents are stored encrypted by the service; the app only ever keeps
    /// the last digits, for display.
    struct Traveler: Codable, Equatable {
        var ktnLast4: String?
        var passportLast4: String?
        var passportCountry: String?
        /// "09/2031"
        var passportExpiry: String?
        var redressLast4: String?

        var isEmpty: Bool {
            ktnLast4 == nil && passportLast4 == nil && passportCountry == nil && passportExpiry == nil && redressLast4 == nil
        }
    }

    /// An empty record means no profile.
    var isEmpty: Bool { brands.isEmpty && dining.isEmpty && traveler.isEmpty }
}

/// The three areas of setup, in order.
enum ProfileArea: Int, CaseIterable, Identifiable {
    case brands, dining, traveler

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .brands: "Brands & airlines"
        case .dining: "Dining"
        case .traveler: "Traveler"
        }
    }

    var symbol: String {
        switch self {
        case .brands: "star"
        case .dining: "fork.knife"
        case .traveler: "person.text.rectangle"
        }
    }

    /// "1 of 3 · Brands & airlines"
    var caption: String { "\(rawValue + 1) of \(Self.allCases.count) · \(title)" }
    var spokenCaption: String { "Step \(rawValue + 1) of \(Self.allCases.count), \(title.replacingOccurrences(of: "&", with: "and"))" }
}

/// The traveler documents a customer can add.
enum DocumentField: String, CaseIterable, Identifiable {
    case ktn, passport, country, expiry, redress

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ktn: "Known Traveler Number (KTN)"
        case .passport: "Passport number"
        case .country: "Country"
        case .expiry: "Expires"
        case .redress: "Redress number"
        }
    }

    var placeholder: String {
        switch self {
        case .ktn: "8 to 10 letters or digits"
        case .passport: "6 to 9 letters or digits"
        case .country: "Country of issue"
        case .expiry: "MM/YYYY"
        case .redress: "If you have one"
        }
    }

    /// Numbers are masked to their last digits once saved.
    var isNumber: Bool { self == .ktn || self == .passport || self == .redress }

    /// Placeholder format checks so the demo catches typos (see the sample data).
    /// Returns a message to show under the field, or nil when the value passes.
    func problem(with value: String, today: Date = .now) -> String? {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch self {
        case .ktn:
            return text.wholeMatch(of: #/[A-Za-z0-9]{8,10}/#) == nil ? "Enter 8 to 10 letters or digits." : nil
        case .passport:
            return text.wholeMatch(of: #/[A-Za-z0-9]{6,9}/#) == nil ? "Enter 6 to 9 letters or digits." : nil
        case .redress:
            return text.wholeMatch(of: #/[0-9]{1,7}/#) == nil ? "Enter up to 7 digits." : nil
        case .country:
            return text.count < 2 ? "Enter the country that issued the passport." : nil
        case .expiry:
            guard let match = text.wholeMatch(of: #/(\d{1,2})\/(\d{4})/#),
                  let month = Int(match.1), let year = Int(match.2), (1...12).contains(month) else {
                return "Use MM/YYYY."
            }
            let now = Calendar.current.dateComponents([.year, .month], from: today)
            let isFuture = (year, month) > (now.year ?? 0, now.month ?? 0)
            return isFuture ? nil : "Enter a month in the future."
        }
    }

    /// "•••• •••• 4417": what a saved number shows.
    func masked(last4: String) -> String {
        switch self {
        case .ktn: "•••• •••• \(last4)"
        case .passport: "••••• \(last4)"
        case .redress: "••• \(last4)"
        case .country, .expiry: last4
        }
    }
}

/// One change, saved on its own (`PATCH /customers/{ecn}/travel-preferences`).
enum PreferencePatch: Equatable {
    case hotelBrands([String])
    case airlines([String])
    case venues([String])
    case restaurants([String])
    case cuisines([String])
    case dietaryNeeds([String])
    case priceRange(String?)
    /// A document number. Only its last digits travel in the clear; the full
    /// number would go to the service encrypted and is never kept or logged here.
    case document(DocumentField, display: String)

    /// The field name sent to the service.
    var field: String {
        switch self {
        case .hotelBrands: "brands.hotelBrandIds"
        case .airlines: "brands.airlineIds"
        case .venues: "brands.venueIds"
        case .restaurants: "brands.restaurantIds"
        case .cuisines: "dining.cuisines"
        case .dietaryNeeds: "dining.dietaryNeeds"
        case .priceRange: "dining.priceRange"
        case .document(let field, _): "traveler.\(field.rawValue)"
        }
    }

    func apply(to preferences: inout TravelPreferences) {
        switch self {
        case .hotelBrands(let ids): preferences.brands.hotelBrandIds = ids
        case .airlines(let ids): preferences.brands.airlineIds = ids
        case .venues(let ids): preferences.brands.venueIds = ids
        case .restaurants(let ids): preferences.brands.restaurantIds = ids
        case .cuisines(let values): preferences.dining.cuisines = values
        case .dietaryNeeds(let values): preferences.dining.dietaryNeeds = values
        case .priceRange(let value): preferences.dining.priceRange = value
        case .document(let field, let display):
            switch field {
            case .ktn: preferences.traveler.ktnLast4 = display
            case .passport: preferences.traveler.passportLast4 = display
            case .country: preferences.traveler.passportCountry = display
            case .expiry: preferences.traveler.passportExpiry = display
            case .redress: preferences.traveler.redressLast4 = display
            }
        }
    }
}

// MARK: - Catalog and customer record

struct CatalogOption: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
}

/// docs/sample-data-day5.json: the options shown as chips, the customer record,
/// the sample profile and the Inspire me response.
struct ProfileSampleData: Decodable {
    struct Customer: Decodable {
        struct Record: Decodable {
            let name: String
            let address: String
            let dateOfBirth: String
            let email: String
            let phone: String

            /// "Mar 14, 1988"
            var dateOfBirthText: String { TripCalendar.dateWithYear(TripCalendar.date(dateOfBirth)) }
        }
        let customerId: String
        let ecn: String
        let record: Record
    }

    struct Catalog: Decodable {
        let hotelBrands: [CatalogOption]
        let airlines: [CatalogOption]
        let venues: [CatalogOption]
        let restaurants: [CatalogOption]
        let cuisines: [String]
        let dietaryNeeds: [String]
        let priceRanges: [String]
        let priceRangeNote: String
    }

    struct Stored: Decodable {
        struct Brands: Decodable { let hotelBrandIds, airlineIds, venueIds, restaurantIds: [String] }
        struct Dining: Decodable { let cuisines, dietaryNeeds: [String]; let priceRange: String? }
        struct Document: Decodable { let last4: String }
        struct Traveler: Decodable {
            let knownTravelerNumber: Document?
            let passportNumber: Document?
            let passportCountry: String?
            let passportExpiry: String?
            let redressNumber: Document?
        }
        let brands: Brands
        let dining: Dining
        let traveler: Traveler
    }

    struct Preferences: Decodable { let afterSetup: Stored }

    struct Inspire: Decodable {
        struct Response: Decodable {
            struct TripRecord: Decodable {
                let id, title, start, end, image: String
                let nights, travelers: Int
            }
            struct Hotel: Decodable {
                let hotelId, name, brandId, brand, city, image: String
                let pricePerNight: Double
            }
            struct Flight: Decodable {
                let flight, airlineId, from, to, date: String
                let nonstop: Bool
                let roundTripFare: Double
            }
            struct FollowUp: Decodable { let chips: [String] }
            let trip: TripRecord
            let hotels: [Hotel]
            let flights: [Flight]
            let followUp: FollowUp
            let footnote: String
        }
        let response: Response
    }

    let customer: Customer
    let catalog: Catalog
    let preferences: Preferences
    let inspireMe: Inspire

    static let sample: ProfileSampleData = {
        guard let url = Bundle.main.url(forResource: "sample-data-day5", withExtension: "json") else {
            fatalError("sample-data-day5.json is missing from the app bundle")
        }
        do {
            return try JSONDecoder().decode(ProfileSampleData.self, from: Data(contentsOf: url))
        } catch {
            fatalError("sample-data-day5.json could not be decoded: \(error)")
        }
    }()

    /// The profile the designs show once setup is finished.
    var afterSetup: TravelPreferences {
        let stored = preferences.afterSetup
        var result = TravelPreferences()
        result.brands = .init(hotelBrandIds: stored.brands.hotelBrandIds, airlineIds: stored.brands.airlineIds,
                              venueIds: stored.brands.venueIds, restaurantIds: stored.brands.restaurantIds)
        result.dining = .init(cuisines: stored.dining.cuisines, dietaryNeeds: stored.dining.dietaryNeeds,
                              priceRange: stored.dining.priceRange)
        // "2031-09" → "09/2031"
        let expiry = stored.traveler.passportExpiry.map { value -> String in
            let parts = value.split(separator: "-")
            return parts.count == 2 ? "\(parts[1])/\(parts[0])" : value
        }
        result.traveler = .init(ktnLast4: stored.traveler.knownTravelerNumber?.last4,
                                passportLast4: stored.traveler.passportNumber?.last4,
                                passportCountry: stored.traveler.passportCountry, passportExpiry: expiry,
                                redressLast4: stored.traveler.redressNumber?.last4)
        return result
    }
}

// MARK: - Service

/// What the service holds for a customer.
struct StoredProfile: Codable, Equatable {
    var preferences = TravelPreferences()
    /// Set by the first successful save: from then on the customer has a profile.
    var createdAt: Date?
    var updatedAt: Date?
    var optedOut = false

    var exists: Bool { createdAt != nil }
}

protocol PreferencesService {
    func load(ecn: String) async throws -> StoredProfile
    /// Saves one change. Throws when the service answers `saved: false`.
    func save(ecn: String, patch: PreferencePatch) async throws
    func optOut(ecn: String) async throws
}

enum PreferencesError: Error {
    case notSaved
}

/// Whether saving a preference works.
enum ProfileSaveScenario: String, CaseIterable, Identifiable {
    case succeeds, failsOnce

    var id: String { rawValue }
    var label: String { self == .succeeds ? "Succeeds" : "Fails once" }
}

/// Keeps one record per ECN in UserDefaults, with a 0.7s delay per save.
final class MockPreferencesService: PreferencesService {
    private let defaults: UserDefaults
    var delayScale: Double
    private var failuresRemaining: Int

    init(scenario: ProfileSaveScenario = .succeeds, delayScale: Double = 1, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.delayScale = delayScale
        failuresRemaining = scenario == .failsOnce ? 1 : 0
    }

    private static func key(_ ecn: String) -> String { "lifestyle.travelPreferences.\(ecn)" }

    private func read(_ ecn: String) -> StoredProfile {
        guard let data = defaults.data(forKey: Self.key(ecn)),
              let profile = try? JSONDecoder().decode(StoredProfile.self, from: data) else {
            return StoredProfile()
        }
        return profile
    }

    private func write(_ profile: StoredProfile, ecn: String) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Self.key(ecn))
        }
    }

    private func wait(_ milliseconds: Int) async throws {
        guard delayScale > 0 else { return }
        try await Task.sleep(for: .milliseconds(Int(Double(milliseconds) * delayScale)))
    }

    func load(ecn: String) async throws -> StoredProfile {
        try await wait(300)
        return read(ecn)
    }

    func save(ecn: String, patch: PreferencePatch) async throws {
        try await wait(700)
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw PreferencesError.notSaved
        }
        var profile = read(ecn)
        patch.apply(to: &profile.preferences)
        let now = Date.now
        // The first saved choice counts as a profile.
        if profile.createdAt == nil { profile.createdAt = now }
        profile.updatedAt = now
        write(profile, ecn: ecn)
    }

    func optOut(ecn: String) async throws {
        try await wait(300)
        var profile = read(ecn)
        profile.optedOut = true
        write(profile, ecn: ecn)
    }

    // MARK: Debug

    /// Clears the profile and the opt-out, so the banner comes back for demos.
    func reset(ecn: String) {
        defaults.removeObject(forKey: Self.key(ecn))
    }

    /// Stores a finished profile, for demos and screenshots.
    func seed(_ preferences: TravelPreferences, ecn: String) {
        write(StoredProfile(preferences: preferences, createdAt: .now, updatedAt: .now), ecn: ecn)
    }
}
