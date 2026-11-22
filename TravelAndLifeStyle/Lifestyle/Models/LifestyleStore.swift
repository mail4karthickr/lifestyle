//
//  LifestyleStore.swift
//  Lifestyle · state that must survive layout and display changes
//
//  Selected tab, scroll positions, the navigation path, the Concierge thread and
//  every flow's answers live here rather than in views, so opening or closing
//  iPhone Duo keeps them.
//

import SwiftUI
import Observation

@Observable
final class LifestyleStore {

    let content: LifestyleContent
    let scenario: LifestyleScenario

    // Independently loading sections.
    let rewards: RewardsModel
    let carousel: CarouselModel
    /// My plans: the customer's trips, built from the bookings on every load (Day 4).
    let trips: TripsModel

    let concierge: ConciergeModel

    // Day 2 and Day 3: the booking flows, and the bookings they confirm.
    let hotel: HotelFlowModel
    let dining: DiningFlowModel
    let bookings: BookingStore
    let diningService: MockDiningService

    // Day 5: the travel profile.
    let profile: ProfileModel
    let preferencesService: MockPreferencesService

    // Navigation and view state.
    var path: [LifestyleRoute] = []
    var selectedTabID: String
    /// Carousel position per tab (card id).
    var carouselPosition: [String: String] = [:]
    /// Vertical scroll offset of the single-column page.
    var pageOffset: CGFloat = 0
    /// Hinge state, when the device has one (iPhone Duo).
    private(set) var hingeStatus: DeviceHinge.Status?
    /// Debug: a pose to show in place of the device's (`-lifestylePose`).
    var poseOverride: DeviceHinge.Status?
    /// "Open for side by side" on the cover display: done once the device has
    /// been opened, or the hint closed. Starts again with the app.
    var openHintIsDone = false
    /// The booking showing beside an itinerary on regular width, by the
    /// itinerary's booking ID.
    var selectedBooking: [String: ItineraryItem.Ref] = [:]
    /// The photo showing in a hotel's gallery and in its full-screen photos.
    var photoPage = 0
    /// Tabletop: the item showing large on the upright half, when the customer
    /// has picked one, by the itinerary's booking ID.
    var glanceItem: [String: String] = [:]
    /// "Travel profile saved", floating over the landing page.
    private(set) var showsProfileToast = false
    private var profileToastShown = false

    private var hasLoaded = false
    /// Set once a `-lifestyleStart` launch argument has been applied.
    var hasStartedDemo = false

    init(content: LifestyleContent = .sample, scenario: LifestyleScenario = .launch) {
        self.content = content
        self.scenario = scenario
        let balance = scenario.startingPoints(content)
        let bookings = Self.makeBookings(scenario)
        let diningService = scenario.diningService()
        let preferencesService = MockPreferencesService(scenario: scenario.profileSave, delayScale: scenario.serviceDelayScale)
        let profile = ProfileModel(service: preferencesService)

        self.bookings = bookings
        self.diningService = diningService
        self.preferencesService = preferencesService
        self.profile = profile
        rewards = RewardsModel(service: scenario.rewardsService(content))
        carousel = CarouselModel(service: scenario.carouselService(content))
        trips = TripsModel(service: scenario.bookingsService(bookings), store: bookings)
        concierge = ConciergeModel(content: content.concierge, firstName: content.customer.firstName,
                                   inspire: MockInspireService(delayScale: scenario.serviceDelayScale), profile: profile)
        hotel = HotelFlowModel(service: scenario.aspireService(), balance: balance)
        hotel.bookingStepInterval = .milliseconds(Int(900 * scenario.serviceDelayScale))
        dining = DiningFlowModel(service: diningService, balance: balance)
        selectedTabID = content.defaultTabID
        connectFlows()
    }

    /// Preview and screenshot support: start with fixed section states and no loading.
    init(content: LifestyleContent = .sample,
         scenario: LifestyleScenario,
         rewards: LoadState<Rewards>,
         carousel: LoadState<CarouselContent>,
         trips: LoadState<[Trip]>?) {
        self.content = content
        self.scenario = scenario
        let balance = scenario.startingPoints(content)
        let bookings = Self.makeBookings(scenario)
        let diningService = scenario.diningService(delayScale: 0)
        // Previews keep their profile out of the app's saved one.
        let preferencesService = MockPreferencesService(delayScale: 0, defaults: UserDefaults(suiteName: "lifestyle.preview") ?? .standard)
        let profile = ProfileModel(service: preferencesService)
        profile.debounce = .zero

        self.bookings = bookings
        self.diningService = diningService
        self.preferencesService = preferencesService
        self.profile = profile
        self.rewards = RewardsModel(service: scenario.rewardsService(content), state: rewards)
        self.carousel = CarouselModel(service: scenario.carouselService(content), state: carousel)
        self.trips = TripsModel(service: scenario.bookingsService(bookings), store: bookings,
                                state: trips ?? .loaded(bookings.trips()))
        concierge = ConciergeModel(content: content.concierge, firstName: content.customer.firstName,
                                   inspire: MockInspireService(delayScale: 0), profile: profile)
        concierge.typingDelay = .zero
        hotel = HotelFlowModel(service: scenario.aspireService(delayScale: 0), balance: balance)
        dining = DiningFlowModel(service: diningService, balance: balance)
        selectedTabID = content.defaultTabID
        hasLoaded = true
        connectFlows()
    }

    private static func makeBookings(_ scenario: LifestyleScenario) -> BookingStore {
        let hotelData = HotelSampleData.sample
        let store = BookingStore(existingTrip: hotelData.trip, customerId: hotelData.customer.customerId, seed: scenario.seed)
        store.todayOverride = scenario.today
        return store
    }

    private func connectFlows() {
        hotel.onBooked = { [weak self] booking in self?.didBook(booking) }
        dining.onReserved = { [weak self] reservation in self?.didReserve(reservation) }
        // Tables the customer already holds count against the restaurant's inventory.
        for reservation in bookings.reservations { diningService.count(reservation) }
        // The overlap demo: the customer already holds a 7:00 PM table that night.
        if scenario.dining == .overlap {
            let held = DiningSampleData.sample.overlapDemoReservation(
                customerId: bookings.customerId, tripId: bookings.existingTrip.tripId)
            if bookings.reservation(id: held.id) == nil {
                bookings.seed(held)
                diningService.count(held)
            }
        }
        dining.held = bookings.reservations
    }

    /// The device's pose: the debug override, or what the hinge reports.
    var pose: DeviceHinge.Status? { poseOverride ?? hingeStatus }
    /// Half folded: book pose side by side, tabletop when the panes are stacked.
    var isPartiallyFolded: Bool { pose == .partiallyOpen }
    /// iPhone Duo, closed: Lifestyle is on the cover display.
    var isOnCoverDisplay: Bool { pose == .closed }

    /// The hinge moved.
    func hingeChanged(from old: DeviceHinge.Status?, to new: DeviceHinge.Status?) {
        hingeStatus = new
        if old == .closed, let new, new != .closed { deviceOpened() }
    }

    /// The device was opened, so the cover display's hint has done its job.
    func deviceOpened() {
        openHintIsDone = true
    }

    // MARK: Loading

    /// Starts the section loads side by side. One failing never blocks the others.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        async let rewardsLoad: Void = rewards.load()
        async let carouselLoad: Void = carousel.load()
        async let tripsLoad: Void = trips.load()
        async let profileLoad: Void = profile.load()
        _ = await (rewardsLoad, carouselLoad, tripsLoad, profileLoad)
    }

    /// The landing page is showing again: fetch the bookings and rerun trip
    /// matching, so a new booking shows and titles change with it.
    func landingAppeared() {
        guard hasLoaded else { return }
        Task { await trips.load() }
    }

    // MARK: Navigation

    /// Opens a destination from the landing page or the Concierge. Flows opened
    /// this way start fresh.
    func open(_ route: LifestyleRoute?) {
        guard let route else { return }
        switch route {
        case .hotelSearch(let destination):
            hotel.balance = rewardsBalance
            hotel.begin(destination: destination)
        case .hotelDetails(let hotelId):
            hotel.balance = rewardsBalance
            hotel.begin()
            hotel.selectHotel(hotelId)
        case .restaurant:
            dining.balance = rewardsBalance
            dining.held = bookings.reservations
            dining.tripId = bookings.tripId(covering: dining.setup.date, through: dining.setup.date)
            dining.begin()
        default:
            break
        }
        path.append(route)
    }

    /// Opens a Fargo Concierge pick. A hotel opens with the chat's dates when
    /// they aren't the trip's, in its own destination.
    func open(_ pick: ConciergePick) {
        guard case .hotelDetails(let hotelId) = pick.route, concierge.hasCustomDates || concierge.idea != nil else {
            open(pick.route)
            return
        }
        hotel.balance = rewardsBalance
        hotel.begin(hotelId: hotelId, destination: HotelCatalog.hotel(id: hotelId)?.destination,
                    stay: (concierge.checkIn, concierge.checkOut), datesTag: "From Fargo Concierge")
        path.append(.hotelDetails(hotelId: hotelId))
    }

    /// Moves to the next step inside a flow, keeping every choice.
    func advance(to route: LifestyleRoute) {
        path.append(route)
    }

    /// Leaves the flow and returns to the Lifestyle landing page.
    func closeFlow() {
        if path.contains(where: \.isProfileSetup) { profile.leaveAll() }
        path.removeAll()
    }

    func back() {
        if !path.isEmpty { path.removeLast() }
    }

    /// "Edit" on the results: back to the search form, keeping what was entered.
    func editHotelSearch() {
        if let index = path.lastIndex(where: { if case .hotelSearch = $0 { true } else { false } }) {
            path.removeSubrange(path.index(after: index)...)
        } else {
            path.append(.hotelSearch(destination: .trip))
        }
    }

    /// Back to a step that is already on the path, keeping what was entered.
    func pop(to route: LifestyleRoute) {
        if let index = path.lastIndex(of: route) {
            path.removeSubrange(path.index(after: index)...)
        }
    }

    // MARK: Rewards

    /// The balance to pay from: the loaded rewards, or the customer record until they load.
    var rewardsBalance: Int {
        rewards.state.value?.points ?? scenario.startingPoints(content)
    }

    private func refreshBalances() {
        hotel.balance = rewardsBalance
        dining.balance = rewardsBalance
    }

    // MARK: Day 2 · hotel bookings

    /// Stores the confirmed booking and updates the rewards balance. A booking
    /// that is already stored changes nothing.
    private func didBook(_ booking: HotelBooking) {
        if bookings.record(booking) {
            rewards.spend(points: booking.tender?.points ?? 0)
            refreshBalances()
            trips.rebuild()
        }
        // The flow is finished: Back from the confirmation goes home.
        path = [.hotelConfirmed]
    }

    /// A hotel Inspire me suggested: opens Day 2's hotel details for it, with
    /// the suggested dates and travelers carried over.
    func open(_ pick: InspireHotel, stay: (start: Date, end: Date)?, travelers: Int?) {
        hotel.balance = rewardsBalance
        hotel.begin(inspired: pick, stay: stay, travelers: travelers)
        path.append(.hotelDetails(hotelId: pick.id))
    }

    // MARK: Day 3 · dining reservations

    /// Stores the confirmed reservation; only now do the points come off.
    private func didReserve(_ reservation: DiningReservation) {
        if bookings.record(reservation) {
            rewards.spend(points: reservation.pointsUsed)
            refreshBalances()
            dining.held = bookings.reservations
            trips.rebuild()
        }
        // The flow is finished: Back from the confirmation goes home.
        path = [.diningConfirmed]
    }

    // MARK: Day 4 · trips

    /// Selecting a plan on the landing page opens My Trip: that trip's itinerary.
    func open(_ trip: Trip) {
        open(.itinerary(bookingId: trip.id))
    }

    /// The booking whose details show beside an itinerary: the customer's pick,
    /// or the booking just added, or the trip's first.
    func selectedRef(in itinerary: TripItinerary, bookingId: String) -> ItineraryItem.Ref? {
        let items = itinerary.items
        if let picked = selectedBooking[bookingId], items.contains(where: { $0.ref == picked }) { return picked }
        return (items.first(where: \.isJustAdded) ?? items.first { $0.kind == .dining }
                ?? items.first { $0.kind == .hotelCheckIn } ?? items.first)?.ref
    }

    // MARK: Day 5 · travel profile

    /// The banner shows only to a customer with no saved preferences who hasn't opted out.
    var showsProfileBanner: Bool { profile.showsBanner }

    /// Whether the one-time "Travel profile saved" toast is due: something was
    /// saved and the customer is back on the landing page.
    var profileToastIsDue: Bool {
        path.isEmpty && profile.savedThisSession && !profileToastShown
    }

    /// Floats the toast for 4 seconds, once.
    func showProfileToast() {
        guard !profileToastShown else { return }
        profileToastShown = true
        showsProfileToast = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            self?.showsProfileToast = false
        }
    }

    /// Opt out on the intro: recorded against the ECN, then back to the landing page.
    func optOutOfProfile() {
        Task { await profile.optOut() }
        path.removeAll()
    }

    /// Done → "Try Inspire me": opens Concierge and sends "Inspire me".
    func tryInspireMe() {
        profile.leaveAll()
        concierge.newChat()
        path = [.concierge]
        concierge.inspireMe()
    }
}

// MARK: - Preview fixtures

extension LifestyleStore {

    enum Fixture {
        case loaded, loading, tripsFailed
    }

    static func preview(seed: BookingSeed = .none, _ fixture: Fixture = .loaded, tab: String? = nil,
                        profile: TravelPreferences? = nil) -> LifestyleStore {
        let content = LifestyleContent.sample
        var scenario = LifestyleScenario()
        scenario.seed = seed
        scenario.today = SeedBookings.sample.today
        let store: LifestyleStore
        switch fixture {
        case .loaded:
            store = LifestyleStore(scenario: scenario, rewards: .loaded(content.rewards),
                                   carousel: .loaded(content.carousel), trips: nil)
        case .loading:
            scenario.loading = .stuck
            store = LifestyleStore(scenario: scenario, rewards: .loading, carousel: .loading, trips: .loading)
        case .tripsFailed:
            store = LifestyleStore(scenario: scenario, rewards: .loaded(content.rewards),
                                   carousel: .loaded(content.carousel), trips: .failed)
        }
        store.profile.show(profile ?? TravelPreferences())
        if let tab { store.selectedTabID = tab }
        return store
    }
}
