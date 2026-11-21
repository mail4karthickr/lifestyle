//
//  HotelCatalog.swift
//  Lifestyle · the hotels the mock Aspire service knows
//
//  The Day 2 sample data has ten Houston hotels in its results and full details
//  for one of them. So every hotel can be opened and booked, and so other
//  destinations have hotels too, this catalog fills in the rest: the same ten
//  Houston hotels with an address, reviews and a description each, and a few
//  placeholder hotels for each other destination. All of it is fictional.
//

import Foundation

/// A hotel with everything the results, the filters, the details and a booking need.
struct CatalogHotel: Identifiable, Hashable {
    let id: String
    let name: String
    /// What the customer searches for: "Houston, TX", "The Caribbean".
    let destination: String
    /// Where the hotel is, for the booking and its trip: "Miami Beach, FL".
    let city: String
    let neighborhood: String
    let address: String
    let distanceMi: Double
    let airportMi: Double
    /// Miles from the customer's dinner; only Houston has one.
    var dinnerMi: Double?
    let rating: Double
    let reviews: Int
    let cashPerNight: Int
    let freeCancellation: Bool
    let imageName: String
    /// One of the brands the filters offer.
    let brand: String
    /// Filter names: Pool, Free Wi-Fi, Parking, Fitness.
    let amenities: Set<String>
    let accessibility: Set<String>
    let about: String
    let nearby: [HotelDetails.Nearby]

    var ratingWord: String {
        switch rating {
        case 4.7...: "Exceptional"
        case 4.5...: "Excellent"
        case 4.2...: "Very good"
        default: "Good"
        }
    }

    /// Amenities as the details screen lists them.
    var amenityList: [String] {
        var list: [String] = []
        if amenities.contains("Free Wi-Fi") { list.append("Free Wi-Fi") }
        if amenities.contains("Pool") { list.append("Pool") }
        if amenities.contains("Fitness") { list.append("Fitness center") }
        if amenities.contains("Parking") { list.append("Parking") }
        if !accessibility.isEmpty { list.append("Accessible rooms") }
        return list
    }

    var summary: HotelSummary {
        var summary = HotelSummary(
            id: id, name: name, neighborhood: neighborhood, distanceMi: distanceMi, rating: rating,
            ratingWord: ratingWord, cashPerNight: cashPerNight, pointsPerNight: cashPerNight * 100,
            freeCancellation: freeCancellation, imageName: imageName)
        summary.brand = brand
        summary.amenities = amenities
        summary.accessibility = accessibility
        summary.distanceFromDinnerMi = dinnerMi ?? distanceMi
        summary.distanceFromAirportMi = airportMi
        return summary
    }
}

enum HotelCatalog {
    static let houston = HotelSampleData.sample.search.destination
    static let caribbean = "The Caribbean"
    static let skiResorts = "Alpine ski resorts"

    /// Every destination with hotels, in the order the search offers them.
    static let destinations = [houston, caribbean, skiResorts, "Miami, FL", "Austin, TX", "Denver, CO", "Seattle, WA", "New York, NY"]

    static let hotels: [CatalogHotel] = houstonHotels + otherHotels

    private static let byId = Dictionary(uniqueKeysWithValues: hotels.map { ($0.id, $0) })

    static func hotel(id: String) -> CatalogHotel? { byId[id] }

    /// Hotels for a search. A hotel also answers to its own city, so a search
    /// for "Miami Beach, FL" finds the Miami hotels.
    static func hotels(in destination: String) -> [CatalogHotel] {
        let direct = hotels.filter { $0.destination == destination }
        if !direct.isEmpty { return direct }
        guard let area = hotels.first(where: { $0.city == destination })?.destination else { return [] }
        return hotels.filter { $0.destination == area }
    }

    /// The image for a trip in a city, from the destination a hotel there belongs to.
    static func destinationImage(forCity cityName: String) -> String? {
        guard let hotel = hotels.first(where: { Trip.cityName($0.city) == cityName }) else { return nil }
        switch hotel.destination {
        case houston: return "houston"
        case caribbean: return "beach"
        case skiResorts: return "alpine"
        case "Miami, FL": return "event_miami"
        case "New York, NY": return "event_nyc"
        default: return "city"
        }
    }

    // MARK: Photos

    // The hotels are fictional. Their photos are real photographs of other
    // hotels from Wikimedia Commons, used under their free licenses and
    // credited in PHOTO-CREDITS.md at the project root. No two hotels in one
    // destination share a photo. Replace them with the supplier's own
    // photos before this ships.

    /// Photos shown after a hotel's main one in its gallery, before its rooms.
    /// Only the sample's own hotel has them: its details count eight photos.
    private static let morePhotos: [String: [String]] = [
        "HTL-1001": ["photo_glass_towers", "photo_lobby", "photo_room_boutique", "photo_room_fourposter"],
    ]

    static func morePhotos(for hotelId: String) -> [String] { morePhotos[hotelId] ?? [] }

    /// The photo of a room type, from the sample's image for it ("room_king").
    /// The king room's photo has a city skyline in its window, so beach resorts
    /// and ski lodges show another king room.
    static func roomPhoto(_ sampleImage: String, hotelId: String) -> String {
        let photo = "photo_" + sampleImage
        guard photo == "photo_room_king", let destination = hotel(id: hotelId)?.destination,
              destination == caribbean || destination == skiResorts else { return photo }
        return "photo_room_fourposter"
    }

    // MARK: Houston (the sample's results)

    private struct HoustonExtra {
        let photo: String
        let brand: String
        let amenities: Set<String>
        let accessibility: Set<String>
        let dinnerMi: Double
        let airportMi: Double
        let address: String
        let reviews: Int
        let about: String
    }

    /// What the sample results don't carry: filter attributes, an address, reviews and a description.
    private static let houstonExtras: [String: HoustonExtra] = [
        "HTL-1001": .init(photo: "photo_rooftop_pool_city", brand: "Solenne Collection", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
                          accessibility: ["Accessible room", "Roll-in shower"], dinnerMi: 0.3, airportMi: 19.5,
                          address: "1200 Lamar Arcade, Houston, TX 77002", reviews: 1284,
                          about: "A 24-floor hotel in the middle of Downtown, steps from the Theater District, with a rooftop pool and a lobby bar."),
        "HTL-1002": .init(photo: "photo_brick_midrise", brand: "Independent", amenities: ["Pool", "Free Wi-Fi", "Parking"],
                          accessibility: ["Accessible room"], dinnerMi: 3.2, airportMi: 17.0,
                          address: "5410 Fannin Court, Houston, TX 77004", reviews: 912,
                          about: "A garden hotel beside the museums, with a courtyard pool and rooms that open onto oak-shaded terraces."),
        "HTL-1003": .init(photo: "photo_brick_loft", brand: "Independent", amenities: ["Free Wi-Fi"],
                          accessibility: [], dinnerMi: 2.5, airportMi: 20.1,
                          address: "318 Hawthorne Lane, Houston, TX 77006", reviews: 436,
                          about: "A restored brick townhouse with 28 rooms, a reading room and breakfast in the kitchen, on a quiet Montrose street."),
        "HTL-1004": .init(photo: "photo_highrise_pair", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Fitness"],
                          accessibility: ["Accessible room", "Hearing access"], dinnerMi: 1.1, airportMi: 18.6,
                          address: "2900 Travis Square, Houston, TX 77006", reviews: 1530,
                          about: "A modern Midtown tower a short ride from Downtown, with a lap pool and a gym that stays open late."),
        "HTL-1005": .init(photo: "photo_white_modern", brand: "Independent", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
                          accessibility: ["Accessible room"], dinnerMi: 5.9, airportMi: 24.2,
                          address: "1770 Post Oak Terrace, Houston, TX 77056", reviews: 1107,
                          about: "A glass tower in Uptown with skyline views from every floor, a pool deck and parking on site."),
        "HTL-1006": .init(photo: "photo_brick_oxford", brand: "Independent", amenities: ["Free Wi-Fi", "Parking"],
                          accessibility: [], dinnerMi: 3.8, airportMi: 17.5,
                          address: "640 Harvard Bend, Houston, TX 77007", reviews: 388,
                          about: "A small inn in The Heights with a porch, free parking and lanterns along the bayou path."),
        "HTL-1007": .init(photo: "photo_brick_seattle", brand: "Independent", amenities: ["Free Wi-Fi", "Fitness"],
                          accessibility: ["Accessible room"], dinnerMi: 1.9, airportMi: 16.8,
                          address: "2215 Commerce Row, Houston, TX 77003", reviews: 654,
                          about: "A converted warehouse in EaDo with tall windows, a gym and the stadiums a short walk away."),
        "HTL-1008": .init(photo: "photo_brick_tower", brand: "Independent", amenities: ["Pool", "Free Wi-Fi", "Parking"],
                          accessibility: ["Accessible room", "Roll-in shower"], dinnerMi: 5.3, airportMi: 22.4,
                          address: "2480 Linden Walk, Houston, TX 77005", reviews: 821,
                          about: "A low-rise hotel among Rice Village's shops, with a shaded pool and roll-in showers in its accessible rooms."),
        "HTL-1009": .init(photo: "photo_pool_deck", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
                          accessibility: ["Hearing access"], dinnerMi: 7.6, airportMi: 25.0,
                          address: "5065 Westheimer Quay, Houston, TX 77056", reviews: 1342,
                          about: "All-suite rooms with kitchenettes by the Galleria, with a pool, a gym and parking on site."),
        "HTL-1010": .init(photo: "photo_brick_grand", brand: "Independent", amenities: ["Free Wi-Fi"],
                          accessibility: ["Accessible room"], dinnerMi: 0.5, airportMi: 19.2,
                          address: "905 Pine Crest Street, Houston, TX 77002", reviews: 705,
                          about: "A simple Downtown hotel with compact rooms, close to the light rail and the convention center."),
    ]

    private static let houstonHotels: [CatalogHotel] = {
        let data = HotelSampleData.sample
        let restaurant = DiningSampleData.sample.restaurant
        return data.results.hotels.compactMap { hotel in
            guard let extra = houstonExtras[hotel.hotelId] else { return nil }
            // The sample's own hotel keeps the places its details list.
            let nearby: [HotelDetails.Nearby] = hotel.hotelId == data.hotelDetails.hotelId
                ? data.hotelDetails.nearby.map { .init(name: $0.name, detail: $0.detail, walk: $0.walk) }
                : [
                    .init(name: restaurant.name, detail: "\(restaurant.cuisine) · New Year's Day chef's table",
                          walk: travelTime(miles: extra.dinnerMi)),
                    .init(name: "Downtown", detail: "Theaters, parks and the convention center",
                          walk: travelTime(miles: hotel.distanceMiFromCityCenter)),
                ]
            return CatalogHotel(
                id: hotel.hotelId, name: hotel.name, destination: houston, city: houston,
                neighborhood: hotel.neighborhood, address: extra.address,
                distanceMi: hotel.distanceMiFromCityCenter, airportMi: extra.airportMi, dinnerMi: extra.dinnerMi,
                rating: hotel.rating, reviews: extra.reviews, cashPerNight: hotel.cashPerNight,
                freeCancellation: hotel.freeCancellationAvailable,
                imageName: extra.photo,
                brand: extra.brand, amenities: extra.amenities, accessibility: extra.accessibility,
                about: extra.about, nearby: nearby)
        }
    }()

    /// "6 min" on foot up to a mile, otherwise a drive.
    private static func travelTime(miles: Double) -> String {
        miles <= 1 ? "\(max(Int((miles * 20).rounded()), 1)) min" : "\(Int((miles * 3).rounded()) + 3) min drive"
    }

    // MARK: Other destinations (placeholders)

    private static func hotel(_ id: String, _ name: String, in destination: String, city: String, _ neighborhood: String,
                              address: String, center: Double, airport: Double, rating: Double, reviews: Int,
                              price: Int, flexible: Bool = true, image: String, brand: String = "Independent",
                              amenities: Set<String>, accessibility: Set<String> = ["Accessible room"],
                              about: String, nearby: [(String, String, String)]) -> CatalogHotel {
        CatalogHotel(
            id: id, name: name, destination: destination, city: city, neighborhood: neighborhood, address: address,
            distanceMi: center, airportMi: airport, dinnerMi: nil, rating: rating, reviews: reviews,
            cashPerNight: price, freeCancellation: flexible, imageName: image, brand: brand, amenities: amenities,
            accessibility: accessibility, about: about,
            nearby: nearby.map { .init(name: $0.0, detail: $0.1, walk: $0.2) })
    }

    private static let all: Set<String> = ["Pool", "Free Wi-Fi", "Parking", "Fitness"]

    private static let otherHotels: [CatalogHotel] = [
        // The Caribbean
        hotel("HTL-CAR-0002", "Solenne Palm Cay", in: caribbean, city: "Palm Cay, Caribbean", "Beachfront",
              address: "1 Lagoon Walk, Palm Cay", center: 0.4, airport: 6.2, rating: 4.8, reviews: 964, price: 365,
              image: "photo_resort_aerial", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "Low villas along a white-sand lagoon, with two pools, a dive shop and breakfast on the beach.",
              nearby: [("Palm Cay Beach", "Steps from the sand", "1 min"), ("Harbor market", "Stalls and boat trips", "9 min")]),
        hotel("HTL-CAR-0005", "Coral Lantern Resort", in: caribbean, city: "Seven Reefs, Caribbean", "Reef side",
              address: "22 Coral Lantern Road, Seven Reefs", center: 1.8, airport: 9.4, rating: 4.6, reviews: 1218, price: 298,
              image: "photo_resort_domes", amenities: ["Pool", "Free Wi-Fi", "Fitness"],
              about: "A resort on a calm reef with a long pool, snorkeling from the jetty and lanterns lit at dusk.",
              nearby: [("Seven Reefs jetty", "Snorkeling and glass-bottom boats", "3 min"), ("Old town", "Shops and a weekend market", "12 min")]),
        hotel("HTL-CAR-0009", "Meridian Blue Harbor", in: caribbean, city: "Blue Harbor, Caribbean", "Harbor front",
              address: "8 Quay Street, Blue Harbor", center: 0.2, airport: 4.1, rating: 4.4, reviews: 1586, price: 244,
              image: "photo_beach_resort", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A harbor-front hotel with a rooftop pool, close to the ferry and the promenade.",
              nearby: [("Ferry pier", "Day trips to the outer cays", "4 min"), ("Promenade", "Cafes and sunset views", "2 min")]),
        hotel("HTL-CAR-0013", "Sandpiper Beach House", in: caribbean, city: "Tern Bay, Caribbean", "Tern Bay",
              address: "14 Sandpiper Lane, Tern Bay", center: 2.6, airport: 13.0, rating: 4.3, reviews: 342, price: 189,
              flexible: false, image: "photo_ocean_plunge", amenities: ["Free Wi-Fi", "Parking"], accessibility: [],
              about: "Twelve rooms in a beach house on a quiet bay, with hammocks, kayaks and free parking.",
              nearby: [("Tern Bay", "A quiet beach with kayaks", "2 min"), ("Lighthouse trail", "A coastal walk", "15 min")]),

        // Alpine ski resorts
        hotel("HTL-SKI-0001", "Kesselhorn Lodge", in: skiResorts, city: "Silver Basin, CO", "Slope side",
              address: "40 Kesselhorn Way, Silver Basin, CO 80481", center: 0.3, airport: 38.0, rating: 4.7, reviews: 873, price: 255,
              image: "photo_ski_timber", amenities: ["Free Wi-Fi", "Parking", "Fitness"],
              about: "A timber lodge at the foot of the Kesselhorn lift, with a stone fireplace and a boot room by the door.",
              nearby: [("Kesselhorn lift", "Ski-in, ski-out access", "1 min"), ("Village square", "Shops and warming huts", "6 min")]),
        hotel("HTL-SKI-0004", "Hotel Solenne Summit", in: skiResorts, city: "Pine Ridge, CO", "Upper village",
              address: "9 Summit Terrace, Pine Ridge, CO 81620", center: 0.6, airport: 31.5, rating: 4.8, reviews: 1045, price: 342,
              image: "photo_ski_base", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "A mountain hotel above the village with a heated outdoor pool, a spa and a gondola at the door.",
              nearby: [("Summit gondola", "Ski-in, ski-out access", "2 min"), ("Ice rink", "Skating under the lights", "8 min")]),
        hotel("HTL-SKI-0007", "Meridian Snowline", in: skiResorts, city: "Silver Basin, CO", "Base village",
              address: "215 Snowline Drive, Silver Basin, CO 80481", center: 0.8, airport: 37.2, rating: 4.5, reviews: 1396, price: 279,
              image: "photo_ski_timberline", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A base-village hotel with an indoor pool, ski storage and a shuttle to the lifts every ten minutes.",
              nearby: [("Lift shuttle", "Every ten minutes to the lifts", "1 min"), ("Village square", "Shops and warming huts", "4 min")]),
        hotel("HTL-SKI-0011", "Larkspur Chalet", in: skiResorts, city: "Aspen Hollow, UT", "Hollow road",
              address: "77 Larkspur Road, Aspen Hollow, UT 84060", center: 1.4, airport: 44.0, rating: 4.4, reviews: 418, price: 226,
              flexible: false, image: "photo_ski_alpine", amenities: ["Free Wi-Fi", "Parking"], accessibility: [],
              about: "A family-run chalet with eighteen rooms, a hot tub on the deck and trails from the back gate.",
              nearby: [("Hollow trailhead", "Cross-country trails", "3 min"), ("Aspen Hollow lifts", "Free shuttle in the morning", "10 min drive")]),

        // Miami
        hotel("HTL-MIA-0007", "Hotel Solenne Miami Beach", in: "Miami, FL", city: "Miami Beach, FL", "South Beach",
              address: "1510 Ocean Promenade, Miami Beach, FL 33139", center: 4.8, airport: 11.6, rating: 4.7, reviews: 2140, price: 289,
              image: "photo_deco_white", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "An oceanfront tower in South Beach with a pool deck over the sand and cabanas along the boardwalk.",
              nearby: [("South Beach", "Steps from the sand", "2 min"), ("Art Deco district", "Walking tours and galleries", "7 min")]),
        hotel("HTL-MIA-0019", "Meridian Miami", in: "Miami, FL", city: "Miami, FL", "Brickell",
              address: "880 Brickell Key Drive, Miami, FL 33131", center: 0.9, airport: 7.8, rating: 4.5, reviews: 1873, price: 231,
              image: "photo_pool_skyline", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A Brickell high-rise with a bay-view pool and the Metromover a block away.",
              nearby: [("Bayfront park", "Waterfront paths and concerts", "9 min"), ("Metromover", "Free rides around Downtown", "3 min")]),
        hotel("HTL-MIA-0023", "Wrenfield Resort Miami", in: "Miami, FL", city: "Miami, FL", "Coconut Grove",
              address: "3401 Bayshore Grove, Miami, FL 33133", center: 4.2, airport: 8.9, rating: 4.6, reviews: 1011, price: 305,
              image: "photo_resort_pool_palms", amenities: all,
              about: "A resort among banyan trees in Coconut Grove, with a lagoon pool and a marina across the road.",
              nearby: [("Grove marina", "Sailing and sunset cruises", "5 min"), ("Village shops", "Boutiques and bookshops", "8 min")]),
        hotel("HTL-MIA-0031", "Coral Row Hotel", in: "Miami, FL", city: "Miami, FL", "Wynwood",
              address: "255 Coral Row, Miami, FL 33127", center: 2.7, airport: 6.3, rating: 4.3, reviews: 688, price: 176,
              image: "photo_deco_yellow", amenities: ["Free Wi-Fi", "Fitness"],
              about: "A small hotel among Wynwood's murals, with a gym, bikes to borrow and a rooftop terrace.",
              nearby: [("Mural walls", "Street art in every direction", "2 min"), ("Design district", "Showrooms and galleries", "8 min drive")]),
        hotel("HTL-MIA-0036", "Palmetto House", in: "Miami, FL", city: "Miami, FL", "Little Havana",
              address: "1418 Palmetto Street, Miami, FL 33135", center: 2.1, airport: 5.4, rating: 4.1, reviews: 297, price: 139,
              flexible: false, image: "photo_deco_park", amenities: ["Free Wi-Fi", "Parking"], accessibility: [],
              about: "A 1920s guesthouse with a tiled patio and free parking, two blocks from the main street.",
              nearby: [("Main street", "Music and domino park", "4 min"), ("Downtown", "Museums and the arena", "9 min drive")]),

        // Austin
        hotel("HTL-AUS-0003", "Meridian Austin", in: "Austin, TX", city: "Austin, TX", "Downtown",
              address: "410 Colorado Mews, Austin, TX 78701", center: 0.3, airport: 8.1, rating: 4.5, reviews: 1659, price: 214,
              image: "photo_rooftop_pool_city", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A Downtown tower two blocks from the lake trail, with a rooftop pool and live music in the lobby.",
              nearby: [("Lake trail", "Ten miles of paths by the water", "5 min"), ("Music district", "Stages on every block", "8 min")]),
        hotel("HTL-AUS-0011", "Hotel Solenne Austin", in: "Austin, TX", city: "Austin, TX", "South Congress",
              address: "1620 South Congress Walk, Austin, TX 78704", center: 1.4, airport: 7.0, rating: 4.7, reviews: 1322, price: 262,
              image: "photo_white_modern", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "A hotel on South Congress with a courtyard pool, a record library and skyline views from the bar.",
              nearby: [("South Congress", "Shops and food trucks", "1 min"), ("Bat bridge", "The evening flight at dusk", "12 min")]),
        hotel("HTL-AUS-0015", "Bayou Inn Austin", in: "Austin, TX", city: "Austin, TX", "East Austin",
              address: "2207 Cesar Row, Austin, TX 78702", center: 1.9, airport: 6.2, rating: 4.2, reviews: 512, price: 149,
              flexible: false, image: "photo_brick_loft", amenities: ["Free Wi-Fi", "Parking"], accessibility: [],
              about: "A simple inn in East Austin with a shaded yard, free parking and bikes to borrow.",
              nearby: [("East side galleries", "Studios and murals", "6 min"), ("Downtown", "The Capitol and the lake", "7 min drive")]),
        hotel("HTL-AUS-0022", "The Pecan Exchange", in: "Austin, TX", city: "Austin, TX", "Rainey Street",
              address: "96 Pecan Exchange, Austin, TX 78701", center: 0.7, airport: 7.6, rating: 4.6, reviews: 934, price: 228,
              image: "photo_brick_seattle", amenities: ["Pool", "Free Wi-Fi", "Parking"],
              about: "A former cotton exchange near Rainey Street, with a pool on the roof and bungalows-turned-bars next door.",
              nearby: [("Rainey Street", "Bungalow patios and music", "2 min"), ("Convention center", "Three blocks north", "6 min")]),

        // Denver
        hotel("HTL-DEN-0004", "Larkspur House Denver", in: "Denver, CO", city: "Denver, CO", "LoDo",
              address: "1745 Wazee Court, Denver, CO 80202", center: 0.5, airport: 23.4, rating: 4.6, reviews: 787, price: 198,
              image: "photo_brick_oxford", amenities: ["Free Wi-Fi", "Fitness"],
              about: "A brick warehouse in LoDo turned into a 60-room hotel, a block from the station.",
              nearby: [("Union Station", "Trains, shops and the airport line", "3 min"), ("Ballpark", "Home games in summer", "9 min")]),
        hotel("HTL-DEN-0009", "Meridian Mile High", in: "Denver, CO", city: "Denver, CO", "Capitol Hill",
              address: "1300 Grant Parade, Denver, CO 80203", center: 1.0, airport: 24.6, rating: 4.4, reviews: 1418, price: 187,
              image: "photo_sandstone", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Parking", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A Capitol Hill hotel with an indoor pool, mountain views from the upper floors and parking on site.",
              nearby: [("Art museum", "Galleries and the civic park", "10 min"), ("Capitol steps", "Exactly one mile high", "6 min")]),
        hotel("HTL-DEN-0012", "Hotel Solenne Denver", in: "Denver, CO", city: "Denver, CO", "Cherry Creek",
              address: "255 Fillmore Plaza, Denver, CO 80206", center: 3.4, airport: 25.9, rating: 4.8, reviews: 1102, price: 271,
              image: "photo_highrise_pair", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "A quiet hotel in Cherry Creek with a rooftop pool, a spa and the creek path outside.",
              nearby: [("Cherry Creek path", "Miles of walking and cycling", "2 min"), ("Shopping district", "Boutiques and galleries", "5 min")]),
        hotel("HTL-DEN-0017", "Front Range Inn", in: "Denver, CO", city: "Denver, CO", "RiNo",
              address: "3120 Larimer Yard, Denver, CO 80205", center: 1.8, airport: 22.0, rating: 4.1, reviews: 356, price: 134,
              flexible: false, image: "photo_brick_loft", amenities: ["Free Wi-Fi", "Parking"], accessibility: [],
              about: "A no-frills inn in the River North arts district, with free parking and murals on every wall.",
              nearby: [("Art district", "Murals and food halls", "3 min"), ("Downtown", "The station and the ballpark", "6 min drive")]),

        // Seattle
        hotel("HTL-SEA-0002", "Auden Seattle", in: "Seattle, WA", city: "Seattle, WA", "Belltown",
              address: "2110 Second Rise, Seattle, WA 98121", center: 0.8, airport: 14.2, rating: 4.6, reviews: 1244, price: 276,
              image: "photo_glass_towers", amenities: ["Free Wi-Fi", "Fitness", "Parking"],
              about: "A glass hotel in Belltown with views across the sound and a library bar on the top floor.",
              nearby: [("Waterfront", "Piers, ferries and the wheel", "8 min"), ("Market", "Stalls open from early morning", "9 min")]),
        hotel("HTL-SEA-0006", "Meridian Harborview", in: "Seattle, WA", city: "Seattle, WA", "Waterfront",
              address: "66 Alaskan Quay, Seattle, WA 98101", center: 0.4, airport: 13.6, rating: 4.5, reviews: 1967, price: 243,
              image: "photo_rooftop_terrace_sea", brand: "Meridian", amenities: ["Pool", "Free Wi-Fi", "Fitness"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A waterfront hotel beside the ferry terminal, with an indoor pool and harbor views.",
              nearby: [("Ferry terminal", "Boats to the islands", "3 min"), ("Market", "Stalls open from early morning", "6 min")]),
        hotel("HTL-SEA-0010", "Cedar & Pike Hotel", in: "Seattle, WA", city: "Seattle, WA", "Capitol Hill",
              address: "1512 Cedar Passage, Seattle, WA 98122", center: 1.3, airport: 14.9, rating: 4.3, reviews: 574, price: 169,
              flexible: false, image: "photo_brick_seattle", amenities: ["Free Wi-Fi"], accessibility: [],
              about: "A small hotel on Capitol Hill above a record shop, with compact rooms and coffee downstairs.",
              nearby: [("Hilltop park", "Views over the city", "7 min"), ("Light rail", "Three stops to the waterfront", "4 min")]),
        hotel("HTL-SEA-0014", "Hotel Solenne Seattle", in: "Seattle, WA", city: "Seattle, WA", "Downtown",
              address: "400 Union Arcade, Seattle, WA 98101", center: 0.2, airport: 13.9, rating: 4.7, reviews: 1503, price: 298,
              image: "photo_grand_seattle", brand: "Solenne Collection", amenities: all, accessibility: ["Accessible room", "Roll-in shower"],
              about: "A Downtown landmark with a glass-roofed pool, a spa and the symphony hall across the street.",
              nearby: [("Symphony hall", "Concerts most evenings", "2 min"), ("Waterfront", "Piers, ferries and the wheel", "10 min")]),

        // New York
        hotel("HTL-NYC-0003", "Hotel Solenne Midtown", in: "New York, NY", city: "New York, NY", "Midtown",
              address: "24 West 51st Mews, New York, NY 10019", center: 0.4, airport: 9.8, rating: 4.7, reviews: 2488, price: 389,
              image: "photo_nyc_entrance", brand: "Solenne Collection", amenities: ["Free Wi-Fi", "Fitness", "Pool"],
              accessibility: ["Accessible room", "Roll-in shower"],
              about: "A Midtown tower between the theaters and the park, with a pool on the 40th floor.",
              nearby: [("Theater row", "Curtain at eight", "6 min"), ("The park", "Paths, lakes and carriage rides", "9 min")]),
        hotel("HTL-NYC-0008", "Meridian Hudson", in: "New York, NY", city: "New York, NY", "Hudson Yards",
              address: "501 Hudson Passage, New York, NY 10001", center: 1.2, airport: 11.3, rating: 4.5, reviews: 2011, price: 312,
              image: "photo_highrise_pair", brand: "Meridian", amenities: ["Free Wi-Fi", "Fitness", "Parking"],
              accessibility: ["Accessible room", "Hearing access"],
              about: "A river-facing hotel at Hudson Yards with a gym, valet parking and the elevated park at its door.",
              nearby: [("Elevated park", "A garden walk above the streets", "2 min"), ("Convention center", "Two blocks west", "7 min")]),
        hotel("HTL-NYC-0011", "The Larchmont", in: "New York, NY", city: "New York, NY", "West Village",
              address: "214 Larchmont Row, New York, NY 10014", center: 2.6, airport: 12.0, rating: 4.6, reviews: 846, price: 268,
              image: "photo_brick_tower", amenities: ["Free Wi-Fi"],
              about: "A townhouse hotel on a tree-lined West Village block, with 40 rooms and a garden.",
              nearby: [("Riverside piers", "Lawns and sunset views", "8 min"), ("Jazz clubs", "Sets from nine", "5 min")]),
        hotel("HTL-NYC-0016", "Cobble & Vine", in: "New York, NY", city: "New York, NY", "Brooklyn",
              address: "88 Cobble Street, Brooklyn, NY 11201", center: 4.1, airport: 10.2, rating: 4.3, reviews: 623, price: 214,
              flexible: false, image: "photo_brick_loft", amenities: ["Free Wi-Fi", "Fitness"], accessibility: [],
              about: "A converted factory by the Brooklyn waterfront, with a gym and skyline views from the roof.",
              nearby: [("Waterfront park", "Piers under the bridges", "6 min"), ("Midtown", "Four subway stops away", "20 min drive")]),
    ]
}
