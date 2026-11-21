//
//  HotelFlowModel.swift
//  Lifestyle · state of the hotel booking flow
//
//  Every choice lives here rather than in a view, so Back keeps it and so does
//  opening, closing or folding iPhone Duo: the selected hotel, the room and
//  rate, the points split and the acceptance of a price change.
//

import Foundation
import Observation

@Observable
final class HotelFlowModel: PaymentChoosing {

    enum RepriceState: Equatable {
        case idle, checking, failed
        case result(RepriceResult)
    }

    enum BookingState: Equatable {
        case idle
        /// 1…3: the step that is in progress.
        case inProgress(step: Int)
        case failed
        case done(HotelBooking)
    }

    enum Destination: String, CaseIterable, Identifiable {
        case trip, caribbean, skiResort
        var id: String { rawValue }
    }

    let service: AspireService
    let trip: TripRecord
    let customerId: String
    let limits: SearchLimits
    private let baseFilterOptions: HotelFilterOptions
    /// Destinations that have hotels, in the order the search offers them.
    let destinations: [String]
    let savedCard: PaymentCard
    private let tripSearch: HotelSearch
    let defaultPoints: Int
    let pointsStep: Int

    /// Rewards balance, kept current by the store.
    var balance: Int
    /// How long each step of the booking panel shows before the next.
    var bookingStepInterval: Duration = .milliseconds(900)
    /// Called once when a new booking is confirmed.
    var onBooked: (HotelBooking) -> Void = { _ in }

    // Step 1 · Hotel
    var search: HotelSearch
    /// Where the dates and travelers came from: "From your trip", "From Inspire me".
    private(set) var datesTag = HotelFlowModel.tripTag
    static let tripTag = "From your trip"
    private(set) var searched: HotelSearch?
    private(set) var results: LoadState<[HotelSummary]> = .loading
    var filters = HotelFilters()
    var sort: HotelSort = .recommended
    private(set) var selectedHotelId: String?
    private(set) var details: LoadState<HotelDetails> = .loading

    // Step 2 · Room
    private(set) var rooms: LoadState<[RoomType]> = .loading
    var selectedRateId: String?

    // Step 3 · Pay
    private(set) var reprice: RepriceState = .idle
    var acceptedChange = false
    var points = 0
    var card: PaymentCard
    /// A card entered in the simulated form.
    var otherCard: PaymentCard?

    // Step 4 · Review
    private(set) var idempotencyKey: UUID?
    private(set) var booking: BookingState = .idle
    private(set) var submissions = 0

    init(service: AspireService, data: HotelSampleData = .sample, balance: Int) {
        self.service = service
        self.balance = balance
        trip = data.trip
        customerId = data.customer.customerId
        limits = service.limits
        baseFilterOptions = service.filterOptions
        destinations = service.destinations
        savedCard = data.savedCard
        card = data.savedCard
        tripSearch = data.tripSearch
        search = data.tripSearch
        defaultPoints = data.payment.defaultPoints
        pointsStep = data.payment.pointsStep
    }

    // MARK: Entry

    /// Starts a fresh flow. Dates and travelers come from the trip.
    func begin(destination: Destination = .trip) {
        search = tripSearch
        search.destination = destinationName(destination)
        datesTag = Self.tripTag
        searched = nil
        loads = [:]
        results = .loading
        filters = HotelFilters()
        sort = .recommended
        selectedHotelId = nil
        details = .loading
        resetRoomChoice()
        card = savedCard
        otherCard = nil
        idempotencyKey = nil
        booking = .idle
    }

    /// Starts a flow at a hotel Inspire me suggested (Day 5), with the
    /// suggested dates and travelers carried over.
    func begin(inspired hotel: InspireHotel, stay: (start: Date, end: Date)?, travelers: Int?) {
        begin(hotelId: hotel.id, destination: hotel.city, stay: stay, travelers: travelers, datesTag: "From Inspire me")
    }

    /// Starts a flow at one hotel, with dates and travelers chosen somewhere
    /// else (Inspire me, or dates changed in Fargo Concierge).
    func begin(hotelId: String, destination: String? = nil, stay: (start: Date, end: Date)?, travelers: Int? = nil,
               datesTag: String) {
        begin()
        if let destination { search.destination = destination }
        if let stay {
            search.checkIn = stay.start
            search.checkOut = stay.end
        }
        if let travelers {
            search.adults = min(max(travelers, 1), limits.maxGuests)
            search.rooms = min(search.rooms, search.adults)
        }
        self.datesTag = datesTag
        selectHotel(hotelId)
    }

    /// The customer picked another destination: what was chosen for the last one no longer applies.
    func setDestination(_ name: String) {
        guard name != search.destination else { return }
        search.destination = name
        filters = HotelFilters()
        sort = .recommended
    }

    /// What the filters offer here. "Your dinner" is a distance only where the dinner is.
    var filterOptions: HotelFilterOptions {
        var options = baseFilterOptions
        if !isTripDestination {
            options.distanceFrom.removeAll { $0 == HotelFilters.dinnerOrigin }
        }
        return options
    }

    func destinationName(_ destination: Destination) -> String {
        switch destination {
        case .trip: tripSearch.destination
        case .caribbean: HotelCatalog.caribbean
        case .skiResort: HotelCatalog.skiResorts
        }
    }

    var isTripDestination: Bool { search.destination == tripSearch.destination }

    /// The existing trip's ID when the stay is in its city and falls inside its
    /// dates; otherwise the booking stands alone and no trip is linked.
    var linkedTripId: String? {
        isTripDestination && trip.start.isOnOrBefore(search.checkIn) && search.checkOut.isOnOrBefore(trip.end)
            ? trip.tripId : nil
    }

    // MARK: Search

    var canAddGuest: Bool { search.adults < limits.maxGuests }
    var canRemoveGuest: Bool { search.adults > 1 }
    /// Rooms can't outnumber guests.
    var canAddRoom: Bool { search.rooms < min(limits.maxRooms, search.adults) }
    var canRemoveRoom: Bool { search.rooms > 1 }

    func changeGuests(by delta: Int) {
        search.adults = min(max(search.adults + delta, 1), limits.maxGuests)
        search.rooms = min(search.rooms, search.adults)
    }

    func changeRooms(by delta: Int) {
        search.rooms = min(max(search.rooms + delta, 1), min(limits.maxRooms, search.adults))
    }

    // Each load runs once per request, in its own task: a screen going away or
    // reloading can't cancel it, and a second caller waits for the same run.

    private enum Slot { case results, details, rooms, reprice }
    private var loads: [Slot: (key: String, task: Task<Void, Never>)] = [:]

    private func load(_ slot: Slot, key: String, retry: Bool, _ work: @escaping () async -> Void) async {
        if let running = loads[slot], running.key == key, !retry {
            await running.task.value
            return
        }
        let task = Task { await work() }
        loads[slot] = (key, task)
        await task.value
    }

    /// Whether `key` is still the request this slot is waiting for.
    private func isCurrent(_ slot: Slot, _ key: String) -> Bool { loads[slot]?.key == key }

    /// Loads results for the current search, unless they are already showing.
    func loadResults(force: Bool = false) async {
        let request = search
        let key = "\(request.hashValue)"
        await load(.results, key: key, retry: force || results.isFailed) { [self] in
            // A changed search clears the hotel and room choice. The first search
            // has nothing to clear, and may arrive with a hotel already chosen.
            if let previous = searched, previous != request {
                selectedHotelId = nil
                resetRoomChoice()
            }
            searched = request
            results = .loading
            let outcome = await Task { try await self.service.search(request) }.result
            guard isCurrent(.results, key) else { return }
            switch outcome {
            case .success(let hotels): results = .loaded(hotels)
            case .failure: results = .failed
            }
        }
    }

    var allHotels: [HotelSummary] { results.value ?? [] }
    var visibleHotels: [HotelSummary] { filters.apply(to: allHotels, sort: sort) }

    func matchCount(for filters: HotelFilters) -> Int { allHotels.filter(filters.matches).count }

    // MARK: Hotel

    var selectedHotel: HotelSummary? { allHotels.first { $0.id == selectedHotelId } }

    func selectHotel(_ id: String) {
        guard id != selectedHotelId else { return }
        selectedHotelId = id
        details = .loading
        loads[.details] = nil
        resetRoomChoice()
    }

    func loadDetails() async {
        guard let id = selectedHotelId else { return }
        await load(.details, key: id, retry: details.isFailed) { [self] in
            details = .loading
            let outcome = await Task { try await self.service.details(hotelId: id) }.result
            guard isCurrent(.details, id) else { return }
            switch outcome {
            case .success(let loaded): details = .loaded(loaded)
            case .failure: details = .failed
            }
        }
    }

    /// Whether the selected hotel can be booked: the sample has one hotel's details.
    var canBookSelectedHotel: Bool { details.value != nil }

    // MARK: Room and rate

    private func resetRoomChoice() {
        rooms = .loading
        loads[.rooms] = nil
        selectedRateId = nil
        resetCheckout()
    }

    func loadRooms() async {
        guard let id = selectedHotelId else { return }
        let request = search
        let key = "\(id)|\(request.hashValue)"
        await load(.rooms, key: key, retry: rooms.isFailed) { [self] in
            rooms = .loading
            let outcome = await Task { try await self.service.rooms(hotelId: id, search: request) }.result
            guard isCurrent(.rooms, key) else { return }
            switch outcome {
            case .success(let loaded):
                rooms = .loaded(loaded)
                // Exactly one room and rate is selected at all times.
                if selectedRate == nil { selectedRateId = loaded.first?.rates.first?.id }
            case .failure:
                rooms = .failed
            }
        }
    }

    var selectedRoom: RoomType? {
        rooms.value?.first { room in room.rates.contains { $0.id == selectedRateId } }
    }

    var selectedRate: Rate? {
        rooms.value?.flatMap(\.rates).first { $0.id == selectedRateId }
    }

    func selectRate(_ id: String) {
        guard id != selectedRateId else { return }
        selectedRateId = id
        resetCheckout()
    }

    /// The price of the selected rate as listed, before reprice.
    var listedPrice: StayPrice? {
        guard let rate = selectedRate else { return nil }
        return StayPrice(nightly: rate.cashPerNight, nights: search.nights, rooms: search.rooms,
                         taxesAndFees: rate.taxesAndFeesTotal)
    }

    /// "Deluxe King · Flexible rate"
    var selectionText: String {
        [selectedRoom?.name, selectedRate?.name].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: Reprice and pay

    private func resetCheckout() {
        reprice = .idle
        loads[.reprice] = nil
        acceptedChange = false
        points = 0
        idempotencyKey = nil
        if case .done = booking {} else { booking = .idle }
    }

    /// Reprices and rechecks availability when checkout opens.
    func repriceIfNeeded(force: Bool = false) async {
        guard let rateId = selectedRateId else { return }
        let request = search
        let key = "\(rateId)|\(request.hashValue)"
        await load(.reprice, key: key, retry: force || reprice == .failed) { [self] in
            reprice = .checking
            acceptedChange = false
            let outcome = await Task { try await self.service.reprice(rateId: rateId, search: request) }.result
            guard isCurrent(.reprice, key) else { return }
            switch outcome {
            case .success(let result):
                reprice = .result(result)
                // Default split: the sample's points, as far as the balance and the total allow.
                if result.price != nil { applyDefaultSplit() }
            case .failure:
                reprice = .failed
            }
        }
    }

    var repriceResult: RepriceResult? {
        if case .result(let result) = reprice { return result }
        return nil
    }

    /// The price to pay, once reprice has confirmed it.
    var price: StayPrice? { repriceResult?.price }

    /// What the points and card split has to cover.
    var amountDue: Decimal? { price?.total }
    let roundsMaxPointsToStep = false

    /// Continue needs a confirmed price, and acceptance of any change.
    var canContinueToReview: Bool {
        guard let result = repriceResult, result.price != nil else { return false }
        return !result.requiresAcceptance || acceptedChange
    }

    /// Why Continue is disabled, for VoiceOver.
    var continueBlocker: String? {
        switch reprice {
        case .idle, .checking: "Checking the latest price"
        case .failed: "The price couldn't be checked"
        case .result(let result):
            if result.price == nil { "This room is no longer available" }
            else if result.requiresAcceptance && !acceptedChange { "Accept the new total to continue" }
            else { nil }
        }
    }

    // MARK: Review and submit

    /// Called when the review screen opens: one key per review, reused by retries.
    func prepareReview() {
        if idempotencyKey == nil { idempotencyKey = UUID() }
    }

    var isBooking: Bool {
        if case .inProgress = booking { return true }
        return false
    }

    var confirmedBooking: HotelBooking? {
        if case .done(let booking) = booking { return booking }
        return nil
    }

    /// Submits the booking. Repeat taps while one is in flight are ignored, and a
    /// retry after a failure reuses the same key, so no duplicate is created.
    func confirmAndBook() async {
        guard !isBooking, confirmedBooking == nil,
              let hotelId = selectedHotelId, let room = selectedRoom, let rate = selectedRate,
              let price, let tender, let key = idempotencyKey else { return }
        submissions += 1
        booking = .inProgress(step: 1)
        let request = BookingRequest(hotelId: hotelId, roomId: room.id, rateId: rate.id, search: search,
                                     price: price, tender: tender, card: card,
                                     tripId: linkedTripId, customerId: customerId)
        // The panel's first two steps tick over while Aspire works.
        let ticker = Task { [weak self, bookingStepInterval] in
            for step in 2...3 {
                try? await Task.sleep(for: bookingStepInterval)
                guard let self, !Task.isCancelled, self.isBooking else { return }
                self.booking = .inProgress(step: step)
            }
        }
        do {
            let confirmed = try await service.book(request, idempotencyKey: key)
            ticker.cancel()
            booking = .done(confirmed)
            onBooked(confirmed)
        } catch {
            ticker.cancel()
            booking = .failed
        }
    }
}
