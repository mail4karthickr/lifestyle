//
//  InspireService.swift
//  Lifestyle · Day 5 · "Inspire me": picks driven by the saved profile
//
//  Hotels match favorite hotel brands, flights match favorite airlines, and a
//  trip combines a hotel pick and a flight pick to the same city. All three
//  are always recommended. The picks are
//  simulated from sample data; the matching sits behind this one service so a
//  real AI search can replace it.
//

import Foundation

/// A hotel Inspire me can suggest. Opens Day 2's hotel details.
struct InspireHotel: Identifiable, Hashable {
    let id: String
    let name: String
    let brandId: String
    let brand: String
    /// "Miami Beach, FL"
    let city: String
    let pricePerNight: Decimal
    let imageName: String

    var priceText: String { "\(pricePerNight.usdWhole) a night" }
}

struct InspireFlight: Identifiable, Hashable {
    let flight: String
    let airlineId: String
    let airline: String
    let from: String
    let to: String
    let date: Date
    let nonstop: Bool
    let roundTripFare: Decimal

    var id: String { flight }
    var route: String { "\(from) → \(to)" }
    /// "Fri, Feb 12 · nonstop"
    var detail: String { "\(TripCalendar.day(date)) · \(nonstop ? "nonstop" : "1 stop")" }
}

/// The top hotel and a flight to the same city, as one suggested trip.
struct TripIdea: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let travelers: Int
    let imageName: String
    let flight: InspireFlight
    let hotel: InspireHotel
    /// Hotel nights with taxes and fees, plus fares for the travelers.
    let estimatedTotal: Decimal
    let because: [String]

    var nights: Int { TripCalendar.nights(start, end) }
    /// "Fri, Feb 12 – Mon, Feb 15 · 3 nights"
    var datesText: String { "\(TripCalendar.range(start, end)) · \(nights) \(nights == 1 ? "night" : "nights")" }
    /// "Est. $1,650 for 2"
    var estimateText: String { "Est. \(estimatedTotal.usdWhole) for \(travelers)" }
    /// "Coast Air 1408 · SFO → MIA · round trip"
    var flightLine: String { "\(flight.flight) · \(flight.route) · round trip" }
    /// "Hotel Solenne Miami Beach · Solenne Collection"
    var hotelLine: String { "\(hotel.name) · \(hotel.brand)" }
    /// "Miami"
    var cityName: String { title.components(separatedBy: " ").first ?? title }
}

struct InspireResult: Hashable {
    /// The saved brands and airlines that drove the picks. Empty when none are saved.
    let basedOn: [String]
    /// The favorites, so a card can say when it is a match.
    let favoriteBrandIds: Set<String>
    let favoriteAirlineIds: Set<String>
    let trip: TripIdea?
    let hotels: [InspireHotel]
    /// The next hotels from the same favorite brands, for "More hotels".
    let moreHotels: [InspireHotel]
    let flights: [InspireFlight]
    let followUpText: String?
    let followUpChips: [String]
    let footnote: String

    /// Something in the saved profile drove these picks.
    var isPersonal: Bool { !basedOn.isEmpty }

    func isFavorite(_ hotel: InspireHotel) -> Bool { favoriteBrandIds.contains(hotel.brandId) }
    func isFavorite(_ flight: InspireFlight) -> Bool { favoriteAirlineIds.contains(flight.airlineId) }

    /// The stay Inspire me suggests for a hotel: the dates of a matching flight
    /// to its city, for the length of the trip idea.
    func stay(for hotel: InspireHotel, nights: Int = 3) -> (start: Date, end: Date)? {
        if let trip, trip.hotel.id == hotel.id { return (trip.start, trip.end) }
        guard let flight = InspireCatalog.flight(to: hotel.city, in: flights) else { return nil }
        return (flight.date, TripCalendar.adding(days: nights, to: flight.date))
    }
}

protocol InspireService {
    /// Hotels, flights and a trip for the saved preferences.
    func recommendations(for preferences: TravelPreferences) async throws -> InspireResult
}

/// What Inspire me can choose from. The first two hotels and flights are the
/// sample response; the rest are placeholders so every brand and airline in the
/// catalog has a match.
enum InspireCatalog {
    static let hotels: [InspireHotel] = {
        let data = ProfileSampleData.sample
        // Each suggestion shows the photo the hotel has in search and details.
        func photo(_ hotelId: String) -> String? { HotelCatalog.hotel(id: hotelId)?.imageName }
        let sample = data.inspireMe.response.hotels.map {
            InspireHotel(id: $0.hotelId, name: $0.name, brandId: $0.brandId, brand: $0.brand, city: $0.city,
                         pricePerNight: Decimal($0.pricePerNight), imageName: photo($0.hotelId) ?? $0.image)
        }
        func brand(_ id: String) -> String { data.catalog.hotelBrands.first { $0.id == id }?.name ?? id }
        let extra = [
            InspireHotel(id: "HTL-AUS-0011", name: "Hotel Solenne Austin", brandId: "hb-solenne", brand: brand("hb-solenne"),
                         city: "Austin, TX", pricePerNight: 262, imageName: photo("HTL-AUS-0011") ?? "city"),
            InspireHotel(id: "HTL-MIA-0019", name: "Meridian Miami", brandId: "hb-meridian", brand: brand("hb-meridian"),
                         city: "Miami, FL", pricePerNight: 231, imageName: photo("HTL-MIA-0019") ?? "city"),
            InspireHotel(id: "HTL-DEN-0004", name: "Larkspur House Denver", brandId: "hb-larkspur", brand: brand("hb-larkspur"),
                         city: "Denver, CO", pricePerNight: 198, imageName: photo("HTL-DEN-0004") ?? "city"),
            InspireHotel(id: "HTL-SEA-0002", name: "Auden Seattle", brandId: "hb-auden", brand: brand("hb-auden"),
                         city: "Seattle, WA", pricePerNight: 276, imageName: photo("HTL-SEA-0002") ?? "city"),
            InspireHotel(id: "HTL-MIA-0023", name: "Wrenfield Resort Miami", brandId: "hb-wrenfield", brand: brand("hb-wrenfield"),
                         city: "Miami, FL", pricePerNight: 305, imageName: photo("HTL-MIA-0023") ?? "city"),
            InspireHotel(id: "HTL-AUS-0015", name: "Bayou Inn Austin", brandId: "hb-bayou", brand: brand("hb-bayou"),
                         city: "Austin, TX", pricePerNight: 149, imageName: photo("HTL-AUS-0015") ?? "city"),
        ]
        return sample + extra
    }()

    static let flights: [InspireFlight] = {
        let data = ProfileSampleData.sample
        func airline(_ id: String) -> String { data.catalog.airlines.first { $0.id == id }?.name ?? id }
        let sample = data.inspireMe.response.flights.map {
            InspireFlight(flight: $0.flight, airlineId: $0.airlineId, airline: airline($0.airlineId), from: $0.from,
                          to: $0.to, date: TripCalendar.date($0.date), nonstop: $0.nonstop,
                          roundTripFare: Decimal($0.roundTripFare))
        }
        func flight(_ number: String, _ id: String, to: String, _ date: String, _ fare: Decimal) -> InspireFlight {
            InspireFlight(flight: "\(airline(id)) \(number)", airlineId: id, airline: airline(id), from: "SFO", to: to,
                          date: TripCalendar.date(date), nonstop: true, roundTripFare: fare)
        }
        let extra = [
            flight("512", "al-northstar", to: "MIA", "2027-02-12", 332),
            flight("77", "al-pacific", to: "SEA", "2027-03-18", 189),
            flight("340", "al-lumen", to: "DEN", "2027-02-26", 206),
            flight("905", "al-summit", to: "AUS", "2027-03-04", 251),
        ]
        return sample + extra
    }()

    /// Airports by city, to pair a hotel with a flight.
    private static let airports = ["Miami": "MIA", "Miami Beach": "MIA", "Austin": "AUS", "Denver": "DEN", "Seattle": "SEA"]

    static func flight(to city: String, in flights: [InspireFlight]) -> InspireFlight? {
        guard let airport = airports[Trip.cityName(city)] else { return nil }
        return flights.first { $0.to == airport }
    }

    /// "Miami Beach, FL" → "Miami"
    static func tripCity(_ city: String) -> String {
        Trip.cityName(city).replacingOccurrences(of: " Beach", with: "")
    }
}

/// Simulated picks from the catalog, following the rules in the Day 5 spec.
struct MockInspireService: InspireService {
    var delayScale: Double = 1

    func recommendations(for preferences: TravelPreferences) async throws -> InspireResult {
        if delayScale > 0 { try await Task.sleep(for: .milliseconds(Int(900 * delayScale))) }
        return Self.match(preferences)
    }

    /// The matching, kept in one place. Inspire me always recommends hotels,
    /// flights and a trip (Day 5):
    /// - Hotels match favorite hotel brands.
    /// - Flights match favorite airlines.
    /// - The trip combines a hotel pick and a flight pick to the same city.
    /// Where no favorite is saved for one of them, that list is filled from the
    /// catalog so there is still something to recommend; only matches are
    /// marked as coming from the profile.
    static func match(_ preferences: TravelPreferences) -> InspireResult {
        let data = ProfileSampleData.sample
        let brandIds = preferences.brands.hotelBrandIds
        let airlineIds = preferences.brands.airlineIds
        let allFlights = InspireCatalog.flights
        let favoriteFlights = allFlights.filter { airlineIds.contains($0.airlineId) }

        // Hotels whose brand is a favorite: one per brand first (best match
        // first, in the order the brands are listed), then the rest.
        let matching = InspireCatalog.hotels.filter { brandIds.contains($0.brandId) }
        var top: [InspireHotel] = []
        for brandId in data.catalog.hotelBrands.map(\.id) where brandIds.contains(brandId) {
            if let first = matching.first(where: { $0.brandId == brandId }) { top.append(first) }
        }
        var more = matching.filter { !top.contains($0) }
        if top.isEmpty {
            // No favorite brand saved: hotels where a favorite airline flies
            // come first, so the trip can still use the customer's airline.
            let reachable = InspireCatalog.hotels.filter { InspireCatalog.flight(to: $0.city, in: favoriteFlights) != nil }
            let others = InspireCatalog.hotels.filter { !reachable.contains($0) }
            top = Array((reachable + others).prefix(2))
            more = []
        }

        // Flights on favorite airlines. With none saved: a flight to each
        // suggested hotel's city.
        var flights = favoriteFlights
        if flights.isEmpty {
            for hotel in top + more {
                guard flights.count < 2, let flight = InspireCatalog.flight(to: hotel.city, in: allFlights),
                      !flights.contains(flight) else { continue }
                flights.append(flight)
            }
        }

        // The trip: a suggested hotel and a flight to the same city, from the
        // picks above when they share a city, otherwise any flight there.
        let candidates = top + more
        func pair(in pool: [InspireFlight]) -> (InspireHotel, InspireFlight)? {
            for hotel in candidates {
                if let flight = InspireCatalog.flight(to: hotel.city, in: pool) { return (hotel, flight) }
            }
            return nil
        }
        var trip: TripIdea?
        if let (hotel, flight) = pair(in: flights) ?? pair(in: allFlights) {
            let sample = data.inspireMe.response.trip
            let nights = sample.nights
            let travelers = sample.travelers
            let taxRate = Decimal(HotelSampleData.sample.taxRateForMocks)
            let stay = hotel.pricePerNight * Decimal(nights)
            let estimate = stay + Decimal(cents: (stay * taxRate).cents) + flight.roundTripFare * Decimal(travelers)
            let city = InspireCatalog.tripCity(hotel.city)
            var because: [String] = []
            if airlineIds.contains(flight.airlineId) { because.append("Your airline") }
            if brandIds.contains(hotel.brandId) { because.append("Your hotel brand") }
            trip = TripIdea(
                id: "IDEA-\(flight.to)-\(hotel.id)", title: "\(city) long weekend", start: flight.date,
                end: TripCalendar.adding(days: nights, to: flight.date), travelers: travelers,
                imageName: Trip.imageName(forCity: city), flight: flight, hotel: hotel,
                estimatedTotal: estimate, because: because)
        }

        let brandNames = data.catalog.hotelBrands.filter { brandIds.contains($0.id) }.map(\.name)
        let airlineNames = data.catalog.airlines.filter { airlineIds.contains($0.id) }.map(\.name)

        // Offer what there is to follow up on.
        var chips: [String] = []
        var asks: [String] = []
        if let trip {
            chips.append("Build the \(trip.cityName) trip")
            asks.append("build the \(trip.cityName) trip")
        }
        if !more.isEmpty, let brand = brandNames.first(where: { name in more.contains { $0.brand == name } }) ?? brandNames.first {
            chips.append("More hotels")
            asks.append("show more hotels from \(brand)")
        }
        let followUp = asks.isEmpty ? nil : "Want me to \(asks.joined(separator: ", or "))?"

        return InspireResult(basedOn: brandNames + airlineNames, favoriteBrandIds: Set(brandIds), favoriteAirlineIds: Set(airlineIds),
                             trip: trip, hotels: top, moreHotels: more, flights: flights,
                             followUpText: followUp, followUpChips: chips,
                             footnote: data.inspireMe.response.footnote)
    }
}
