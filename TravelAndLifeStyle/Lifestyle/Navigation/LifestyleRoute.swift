//
//  LifestyleRoute.swift
//  Lifestyle · navigation destinations
//

import Foundation

enum LifestyleRoute: Hashable {
    /// Simulated Concierge chat.
    case concierge

    // Day 2 — book a hotel.
    /// Search, prefilled from the trip. The carousel cards preset the destination.
    case hotelSearch(destination: HotelFlowModel.Destination)
    case hotelResults
    case hotelDetails(hotelId: String)
    /// The selected hotel's photos, full screen.
    case hotelPhotos
    case hotelRooms
    case hotelCheckout
    case hotelReview
    case hotelConfirmed

    // Day 3 — reserve a table.
    case restaurant
    case diningTable
    case diningDetails
    case diningDeposit
    case diningReview
    case diningConfirmed

    // Day 4 — My Trip: a trip's itinerary and its bookings.
    /// The itinerary of the trip that holds this booking. Trips aren't stored,
    /// so a trip is named by one of its bookings.
    case itinerary(bookingId: String)
    /// One booking of a trip (compact width; regular width shows it beside the itinerary).
    case bookingDetails(ItineraryItem.Ref)

    // Day 5 — travel profile.
    case profileIntro
    case profileArea(ProfileArea)
    case profileDone

    /// Maps an `opens` value from sample-data.json, e.g. "day2.hotelBooking(caribbean)".
    /// Returns nil for entries that are not in the POC.
    init?(opens: String?) {
        guard let opens else { return nil }
        let name = opens.prefix { $0 != "(" }
        var argument: String?
        if let open = opens.firstIndex(of: "("), let close = opens.lastIndex(of: ")"), open < close {
            argument = String(opens[opens.index(after: open)..<close])
        }
        switch name {
        case "day2.hotelBooking":
            switch argument {
            case "caribbean": self = .hotelSearch(destination: .caribbean)
            case "skiResort": self = .hotelSearch(destination: .skiResort)
            // A Concierge pick opens its hotel directly.
            case "hotel-solenne": self = .hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId)
            default: self = .hotelSearch(destination: .trip)
            }
        // One static restaurant: every dining entry point opens it.
        case "day3.reserveTable": self = .restaurant
        case "day5.profileSetup": self = .profileIntro
        default: return nil
        }
    }

    /// Steps of the travel profile setup.
    var isProfileSetup: Bool {
        switch self {
        case .profileIntro, .profileArea, .profileDone: true
        default: false
        }
    }
}
