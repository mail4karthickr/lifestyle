//
//  LifestyleModels.swift
//  Lifestyle · Codable models for docs/sample-data.json
//

import Foundation

struct LifestyleContent: Decodable {
    let customer: Customer
    let tabs: [CategoryTab]
    let travelCards: [TravelCard]
    let diningEvents: [DiningEvent]
    let bookNowTiles: [BookNowTile]
    let concierge: ConciergeContent
}

// MARK: - Customer

struct Customer: Decodable {
    let firstName: String
    let pointsBalance: Int
    let pointValueUSD: Double
    let hasTravelProfile: Bool
    let card: RewardsCard

    struct RewardsCard: Decodable {
        let name: String
        let valueProp: String
    }
}

/// Points balance shown in the header and hero. Loaded on its own.
struct Rewards: Equatable {
    let points: Int
    let pointValueUSD: Double

    var pointsText: String {
        "\(points.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))) pts"
    }

    var travelValueText: String {
        let value = Double(points) * pointValueUSD
        return "\(value.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))) in travel value"
    }
}

// MARK: - Tabs and carousel

struct CategoryTab: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let inPOC: Bool
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, inPOC
        case isDefault = "default"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        inPOC = try c.decode(Bool.self, forKey: .inPOC)
        isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    static let travelID = "travel"
    static let diningID = "dining"
}

struct TravelCard: Decodable, Identifiable, Hashable {
    let id: String
    let image: String
    let title: String
    let subtitle: String
    let opens: String?
    let inPOC: Bool

    var imageName: String { image.assetName }
    var route: LifestyleRoute? { LifestyleRoute(opens: opens) }
}

struct DiningEvent: Decodable, Identifiable, Hashable {
    let id: String
    let image: String
    let date: String
    let menu: String
    let name: String
    let cuisine: String
    let chef: String
    let venue: String
    let address: String
    let city: String
    let opens: String?

    var imageName: String { image.assetName }
    var route: LifestyleRoute? { LifestyleRoute(opens: opens) }
    var cuisineLine: String { "\(cuisine) · \(chef)" }
    var locationLine: String { "\(venue), \(address)" }
}

/// What the Travel and Dining tabs show. Loaded on its own.
struct CarouselContent: Equatable {
    let travelCards: [TravelCard]
    let diningEvents: [DiningEvent]
}

// MARK: - Book now

struct BookNowTile: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let sfSymbolHint: String
    let opens: String?

    var route: LifestyleRoute? { LifestyleRoute(opens: opens) }
}

// MARK: - Concierge

struct ConciergeContent: Decodable {
    let mode: String
    let greeting: [String]
    let inspireMe: [InspireCard]
    let promptChips: [String]
    let disclosure: String
    let script: [ScriptStep]
    let picks: [ConciergePick]
    let afterPicksChips: [String]
    let footnote: String

    struct InspireCard: Decodable, Identifiable, Hashable {
        let image: String
        let prompt: String

        var id: String { prompt }
        var imageName: String { image.assetName }
    }

    struct ScriptStep: Decodable {
        let role: String
        let text: String?
        let followUps: FollowUps?
    }

    struct FollowUps: Decodable {
        let title: String
        let dates: String
        let budgetPerNight: SingleChoice
        let vibe: MultiChoice
        let dining: MultiChoice
        let cta: String

        struct SingleChoice: Decodable {
            let options: [String]
            let single: Bool
            let `default`: String
        }

        struct MultiChoice: Decodable {
            let options: [String]
            let `default`: [String]
        }
    }

    /// The user's scripted request.
    var userRequest: String { script.first { $0.role == "user" }?.text ?? "" }

    /// Concierge's scripted lines, in order: the follow-up intro, then the picks intro.
    var conciergeLines: [String] { script.filter { $0.role == "concierge" }.compactMap(\.text) }

    var followUps: FollowUps? { script.compactMap(\.followUps).first }
}

struct ConciergePick: Decodable, Identifiable, Hashable {
    let kind: String
    let title: String
    let meta: String
    let why: String
    let cta: String
    let image: String
    let opens: String?
    /// Set on picks made from the hotel catalog (the sample's picks use `opens`).
    var hotelId: String?

    var id: String { title }
    /// A hotel pick shows the photo the hotel has in search and details.
    var imageName: String {
        if case .hotelDetails(let hotelId) = route, let photo = HotelCatalog.hotel(id: hotelId)?.imageName {
            return photo
        }
        return image.assetName
    }
    var route: LifestyleRoute? {
        if let hotelId { return .hotelDetails(hotelId: hotelId) }
        return LifestyleRoute(opens: opens)
    }
}

// MARK: - Loading

extension LifestyleContent {

    /// The POC content bundled with the app (a copy of docs/sample-data.json).
    static let sample: LifestyleContent = {
        guard let url = Bundle.main.url(forResource: "sample-data", withExtension: "json") else {
            fatalError("sample-data.json is missing from the app bundle")
        }
        do {
            return try JSONDecoder().decode(LifestyleContent.self, from: Data(contentsOf: url))
        } catch {
            fatalError("sample-data.json could not be decoded: \(error)")
        }
    }()

    var rewards: Rewards {
        Rewards(points: customer.pointsBalance, pointValueUSD: customer.pointValueUSD)
    }

    var carousel: CarouselContent {
        CarouselContent(travelCards: travelCards, diningEvents: diningEvents)
    }

    var defaultTabID: String {
        tabs.first(where: \.isDefault)?.id ?? tabs.first?.id ?? CategoryTab.travelID
    }
}

private extension String {
    /// "design/assets/beach.webp" → "beach" (the asset catalog name).
    var assetName: String {
        URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }
}
