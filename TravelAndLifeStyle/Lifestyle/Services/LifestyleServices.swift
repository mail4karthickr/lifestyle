//
//  LifestyleServices.swift
//  Lifestyle · mock services (Day 1 spec, section 6)
//
//  Hero points, the carousel and My plans each come from their own service so
//  they load, and fail, independently. The mocks add a delay and a failure switch.
//

import Foundation

protocol RewardsService {
    func fetchRewards() async throws -> Rewards
}

protocol CarouselService {
    func fetchCarousel() async throws -> CarouselContent
}

/// Looks up the customer's confirmed hotel and dining bookings (Day 4).
protocol BookingsService {
    func fetchBookings() async throws -> [Booking]
}

enum LifestyleServiceError: Error {
    case unavailable
}

/// Delay and failure switch shared by the mocks.
final class MockBehavior {
    var delay: Duration
    /// How many upcoming calls fail before the service recovers. `Int.max` never recovers.
    var failuresRemaining: Int

    init(delay: Duration, failuresRemaining: Int = 0) {
        self.delay = delay
        self.failuresRemaining = failuresRemaining
    }

    func run() async throws {
        try await Task.sleep(for: delay)
        if failuresRemaining > 0 {
            if failuresRemaining != .max { failuresRemaining -= 1 }
            throw LifestyleServiceError.unavailable
        }
    }

    /// Never returns: keeps a section in its loading state (previews, screenshots).
    static var forever: MockBehavior { MockBehavior(delay: .seconds(60 * 60 * 24)) }
}

struct MockRewardsService: RewardsService {
    let rewards: Rewards
    let behavior: MockBehavior

    func fetchRewards() async throws -> Rewards {
        try await behavior.run()
        return rewards
    }
}

struct MockCarouselService: CarouselService {
    let carousel: CarouselContent
    let behavior: MockBehavior

    func fetchCarousel() async throws -> CarouselContent {
        try await behavior.run()
        return carousel
    }
}

/// Reads the booking store after a delay, with the failure switch.
struct MockBookingsService: BookingsService {
    let store: BookingStore
    let behavior: MockBehavior

    func fetchBookings() async throws -> [Booking] {
        try await behavior.run()
        return store.bookings
    }
}

// MARK: - Demo scenario

/// What the POC starts with and how its mock services behave.
struct LifestyleScenario: Equatable {
    enum Loading: String, CaseIterable, Identifiable {
        case normal, slow, stuck, plansFail
        var id: String { rawValue }
        var label: String {
            switch self {
            case .normal: "Normal"
            case .slow: "Slow network"
            case .stuck: "Keep loading"
            case .plansFail: "My plans fails once"
            }
        }
    }

    /// Day 4: which bookings exist when the demo starts.
    var seed: BookingSeed = .none
    var loading: Loading = .normal
    /// Rewards balance to start from; nil uses the customer record (12,450).
    /// 52,450 is enough to pay a $400 dining deposit with points only.
    var points: Int?
    /// Day 4: debug override for "today", to show a tile disappearing after checkout.
    var today: Date?
    /// Day 2: what the mock Aspire service answers at reprice and at booking.
    var reprice: AspireScenario.Reprice = .priceChanged
    var booking: AspireScenario.Booking = .succeeds
    /// Day 3: what happens when a table is reserved.
    var dining: DiningScenario = .success
    /// Day 5: whether saving a preference works.
    var profileSave: ProfileSaveScenario = .succeeds

    /// Launch arguments, so screenshots and demos can start in a given state:
    /// `-lifestyleSeed none|dinnerOnly|hotelOnly|hotelAndDinner|twoTrips`,
    /// `-lifestyleLoading slow|stuck|plansFail`, `-lifestylePoints 52450`,
    /// `-lifestyleToday 2027-01-03`,
    /// `-lifestyleReprice priceChanged|noChange|roomUnavailable`,
    /// `-lifestyleBooking succeeds|failsOnce`,
    /// `-lifestyleDining success|paymentDeclined|soldOutAtConfirm|overlap` and
    /// `-lifestyleSave succeeds|failsOnce`.
    static var launch: LifestyleScenario {
        let defaults = UserDefaults.standard
        func value<T: RawRepresentable>(_ key: String, _ fallback: T) -> T where T.RawValue == String {
            defaults.string(forKey: key).flatMap(T.init(rawValue:)) ?? fallback
        }
        var scenario = LifestyleScenario()
        scenario.seed = value("lifestyleSeed", BookingSeed.none)
        // Day 1's "returning customer" had plans; it now means two trips booked.
        if defaults.string(forKey: "lifestyleCustomer") == "returning" { scenario.seed = .twoTrips }
        scenario.loading = value("lifestyleLoading", Loading.normal)
        if let points = defaults.string(forKey: "lifestylePoints").flatMap(Int.init) { scenario.points = points }
        if let today = defaults.string(forKey: "lifestyleToday") { scenario.today = TripCalendar.date(today) }
        scenario.reprice = value("lifestyleReprice", AspireScenario.Reprice.priceChanged)
        scenario.booking = value("lifestyleBooking", AspireScenario.Booking.succeeds)
        scenario.dining = value("lifestyleDining", DiningScenario.success)
        scenario.profileSave = value("lifestyleSave", ProfileSaveScenario.succeeds)
        return scenario
    }

    private func behavior(_ milliseconds: Int, canFail: Bool = false) -> MockBehavior {
        switch loading {
        case .normal: MockBehavior(delay: .milliseconds(milliseconds))
        case .slow: MockBehavior(delay: .milliseconds(milliseconds * 4))
        case .stuck: .forever
        case .plansFail: MockBehavior(delay: .milliseconds(milliseconds), failuresRemaining: canFail ? 1 : 0)
        }
    }

    /// The balance the session starts with.
    func startingPoints(_ content: LifestyleContent) -> Int { points ?? content.customer.pointsBalance }

    func rewardsService(_ content: LifestyleContent) -> RewardsService {
        MockRewardsService(rewards: Rewards(points: startingPoints(content), pointValueUSD: content.customer.pointValueUSD),
                           behavior: behavior(600))
    }

    func carouselService(_ content: LifestyleContent) -> CarouselService {
        MockCarouselService(carousel: content.carousel, behavior: behavior(1100))
    }

    /// "Slow network" slows the booking services too.
    var serviceDelayScale: Double { loading == .slow ? 4 : 1 }

    func aspireService(delayScale: Double? = nil) -> MockAspireService {
        MockAspireService(scenario: AspireScenario(reprice: reprice, booking: booking,
                                                   delayScale: delayScale ?? serviceDelayScale))
    }

    func diningService(delayScale: Double? = nil) -> MockDiningService {
        MockDiningService(scenario: dining, delayScale: delayScale ?? serviceDelayScale)
    }

    func bookingsService(_ store: BookingStore) -> BookingsService {
        MockBookingsService(store: store, behavior: behavior(1600, canFail: true))
    }
}
