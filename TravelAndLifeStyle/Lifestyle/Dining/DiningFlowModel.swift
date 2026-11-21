//
//  DiningFlowModel.swift
//  Lifestyle · state of the reserve-a-table flow
//
//  Party, time, guest details, the points and card split and the terms box all
//  live here, so Back keeps every entry and so does opening, closing or folding
//  iPhone Duo.
//

import Foundation
import Observation

@Observable
final class DiningFlowModel: PaymentChoosing {

    enum Field: Hashable {
        case name, email, phone
    }

    enum ReserveState: Equatable {
        case idle
        case inProgress(ReserveStep?)
        case paymentFailed
        case failed
        case done(DiningReservation)
    }

    let service: DiningService
    let restaurant: Restaurant
    let setup: DiningSetup
    let policyText: String
    let customerId: String
    let savedCard: PaymentCard
    let defaultPoints: Int
    let pointsStep: Int
    let roundsMaxPointsToStep = true
    static let accessibilityOptions = ["Wheelchair access", "Step-free route", "Service animal", "Hearing support"]

    /// Rewards balance, kept current by the store.
    var balance: Int
    /// Reservations the customer already holds, kept current by the store.
    var held: [DiningReservation] = []
    /// The existing trip's ID when the dinner's date falls inside it.
    var tripId: String?
    /// Called once when a new reservation is confirmed.
    var onReserved: (DiningReservation) -> Void = { _ in }

    // Step 1 · Table
    private(set) var party: Int
    private(set) var allSlots: LoadState<[Slot]> = .loading
    private(set) var selectedTime: String?
    /// Set when the chosen time filled up before the customer confirmed.
    private(set) var soldOutNotice: String?

    // Step 2 · Details
    var name: String
    var email: String
    var phone: String
    var accessibilityNeeds: Set<String> = []
    var specialRequests = ""
    var dietaryNotes = ""
    private(set) var errors: [Field: String] = [:]
    /// The reservation that blocks this one, after Continue.
    private(set) var overlap: DiningReservation?

    // Step 3 · Pay
    var points = 0
    var card: PaymentCard
    var otherCard: PaymentCard?
    private var splitParty: Int?

    // Step 4 · Review
    var termsAccepted = false
    private(set) var idempotencyKey: UUID?
    private(set) var reserve: ReserveState = .idle
    private(set) var submissions = 0

    private let profile: DiningSampleData.Customer
    private let defaultParty: Int
    private var slotsTask: Task<Void, Never>?

    init(service: DiningService, data: DiningSampleData = .sample, payment: HotelSampleData = .sample,
         balance: Int, defaultParty: Int = 2) {
        self.service = service
        self.balance = balance
        self.defaultParty = defaultParty
        restaurant = service.restaurant
        setup = service.setup
        policyText = service.policyText
        profile = data.customer
        customerId = data.customer.customerId
        savedCard = payment.savedCard
        card = payment.savedCard
        defaultPoints = payment.payment.defaultPoints
        pointsStep = payment.payment.pointsStep
        party = min(max(defaultParty, 1), service.setup.maxPartySize)
        // Prefilled from the customer's profile; all three stay editable.
        name = data.customer.name
        email = data.customer.email
        phone = data.customer.phone
    }

    // MARK: Entry

    /// Starts a fresh reservation. A finished one is left behind; entries in
    /// progress are kept, so coming back to the restaurant loses nothing.
    func begin() {
        if case .done = reserve { reset() }
    }

    func reset() {
        party = min(max(defaultParty, 1), setup.maxPartySize)
        selectedTime = nil
        soldOutNotice = nil
        name = profile.name
        email = profile.email
        phone = profile.phone
        accessibilityNeeds = []
        specialRequests = ""
        dietaryNotes = ""
        errors = [:]
        overlap = nil
        points = 0
        splitParty = nil
        card = savedCard
        otherCard = nil
        termsAccepted = false
        idempotencyKey = nil
        reserve = .idle
    }

    /// The answers the designs show: a party of 4 at 8:00 PM, with a step-free
    /// route and two notes. For demos and screenshots.
    func fillSample(_ sample: DiningSampleData = .sample) {
        let request = sample.sampleRequest
        party = min(max(request.partySize, 1), setup.maxPartySize)
        if let slot = fittingSlots.first(where: { $0.id == request.time }) { select(slot) }
        accessibilityNeeds = Set(request.accessibilityNeeds)
        specialRequests = request.specialRequests ?? ""
        dietaryNotes = request.dietaryNotes ?? ""
    }

    // MARK: Table

    /// Loads every start time with its open tables. Runs in its own task, so a
    /// screen going away can't leave the times stuck loading.
    func loadSlots() async {
        slotsTask?.cancel()
        let service = service
        let task = Task { [weak self] in
            let outcome = await Task { try await service.slots() }.result
            guard let self, !Task.isCancelled else { return }
            switch outcome {
            case .success(let slots):
                self.allSlots = .loaded(slots)
                self.dropSelectionIfGone()
            case .failure:
                if self.allSlots.value == nil { self.allSlots = .failed }
            }
        }
        slotsTask = task
        await task.value
    }

    var canAddGuest: Bool { party < setup.maxPartySize }
    var canRemoveGuest: Bool { party > 1 }

    func changeParty(by delta: Int) {
        party = min(max(party + delta, 1), setup.maxPartySize)
        dropSelectionIfGone()
    }

    /// Only times whose table is big enough for the party.
    var fittingSlots: [Slot] { (allSlots.value ?? []).filter { $0.tableSize >= party } }
    var hiddenSlots: [Slot] { (allSlots.value ?? []).filter { $0.tableSize < party } }

    /// "3 of 4 times open"
    var openCountText: String {
        let fitting = fittingSlots
        let open = fitting.filter { !$0.isSoldOut }.count
        return "\(open) of \(fitting.count) \(fitting.count == 1 ? "time" : "times") open"
    }

    /// Names the times that are hidden, so they aren't just missing:
    /// "7:00 PM and 10:00 PM seat parties of 2 only." or
    /// "Parties of 5 or 6 sit at 6:00 PM or 9:00 PM only."
    var hiddenTimesNote: String? {
        let hidden = hiddenSlots
        guard !hidden.isEmpty else { return nil }
        let sizes = Set(hidden.map(\.tableSize))
        if sizes.count == 1, let size = sizes.first {
            return "\(Self.list(hidden.map(\.timeText), joiner: "and")) seat parties of \(size) only."
        }
        let smallest = (sizes.max() ?? 0) + 1
        let parties = smallest >= setup.maxPartySize
            ? "Parties of \(setup.maxPartySize)"
            : "Parties of \(smallest) or \(setup.maxPartySize)"
        return "\(parties) sit at \(Self.list(fittingSlots.map(\.timeText), joiner: "or")) only."
    }

    private static func list(_ items: [String], joiner: String) -> String {
        switch items.count {
        case 0: ""
        case 1: items[0]
        case 2: "\(items[0]) \(joiner) \(items[1])"
        default: items.dropLast().joined(separator: ", ") + ", \(joiner) \(items[items.count - 1])"
        }
    }

    func select(_ slot: Slot) {
        guard !slot.isSoldOut, slot.tableSize >= party else { return }
        selectedTime = slot.id
        soldOutNotice = nil
        overlap = nil
    }

    /// A party change, or a table selling out, can take the chosen time away.
    private func dropSelectionIfGone() {
        guard let selectedTime else { return }
        if !fittingSlots.contains(where: { $0.id == selectedTime && !$0.isSoldOut }) {
            self.selectedTime = nil
        }
    }

    var selectedSlot: Slot? { fittingSlots.first { $0.id == selectedTime } }
    var selectedTimeText: String? { selectedTime.map { TripCalendar.clock($0) } }
    var canContinueFromTable: Bool { selectedSlot != nil }

    var guestsText: String { party == 1 ? "1 guest" : "\(party) guests" }

    /// "Fri, Jan 1 · 8:00 PM", or "Choose a time".
    var slotSummary: String {
        selectedTimeText.map { "\(setup.dayText) · \($0)" } ?? "Choose a time"
    }

    /// "4 guests · $400 deposit"
    var partySummary: String { "\(guestsText) · \(deposit.usdWhole) deposit" }

    // MARK: Details

    /// Checks the required fields and blocks a table that overlaps one the
    /// customer already holds. Returns whether the customer can move on.
    func validateDetails() -> Bool {
        var found: [Field: String] = [:]
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            found[.name] = "Enter the name for the reservation."
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            found[.email] = "Enter an email for your confirmation."
        } else if trimmedEmail.wholeMatch(of: #/[^@\s]+@[^@\s]+\.[^@\s]+/#) == nil {
            found[.email] = "Check the email address."
        }
        let digits = phone.filter(\.isNumber)
        if digits.isEmpty {
            found[.phone] = "Enter a mobile number so the restaurant can reach you."
        } else if digits.count != 10 {
            found[.phone] = "Enter a 10-digit mobile number."
        }
        errors = found
        overlap = selectedTime.flatMap(overlapping)
        return found.isEmpty && overlap == nil
    }

    func clearError(_ field: Field) { errors[field] = nil }

    private func overlapping(_ time: String) -> DiningReservation? {
        held.first { MockDiningService.overlaps($0, date: setup.date, time: time, hours: setup.seatingLengthHours) }
    }

    /// "Osteria Lume · Fri, Jan 1 · 7:00 PM. Reservations can’t overlap, so choose
    /// a time at least 2 hours apart."
    var overlapMessage: String? {
        guard let overlap else { return nil }
        return "\(overlap.restaurantName) · \(TripCalendar.day(overlap.date)) · \(overlap.timeText). Reservations can’t overlap, so choose a time at least \(setup.seatingLengthHours) hours apart."
    }

    /// "Requests and dietary notes" for the review, in the order entered.
    var requestLines: [String] {
        [specialRequests, dietaryNotes]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Chosen needs, in the order they are offered.
    var accessibilityList: [String] { Self.accessibilityOptions.filter(accessibilityNeeds.contains) }

    // MARK: Deposit

    /// $100 per person.
    var deposit: Decimal { setup.depositPerPerson * Decimal(party) }
    var amountDue: Decimal? { deposit }

    /// "4 guests × $100.00"
    var depositLine: String { "\(guestsText) × \(setup.depositPerPerson.usd)" }
    /// "Deposit · 4 × $100.00"
    var depositLabel: String { "Deposit · \(party) × \(setup.depositPerPerson.usd)" }

    /// Sets the default split the first time, and again if the party changed.
    func prepareDeposit() {
        if splitParty != party {
            splitParty = party
            applyDefaultSplit()
        } else if points > maxPoints {
            points = maxPoints
        }
    }

    /// "Deposit for 4 · card ···· 4821"
    var depositSummary: String {
        guard let tender else { return "" }
        return tender.cardAmount > 0 ? "Deposit for \(party) · card ···· \(card.last4)" : "Deposit for \(party) · paid with points"
    }

    // MARK: Review and reserve

    /// One key per review, reused by retries.
    func prepareReview() {
        prepareDeposit()
        if idempotencyKey == nil { idempotencyKey = UUID() }
    }

    var isReserving: Bool {
        if case .inProgress = reserve { return true }
        return false
    }

    var confirmedReservation: DiningReservation? {
        if case .done(let reservation) = reserve { return reservation }
        return nil
    }

    var canReserve: Bool { termsAccepted && selectedTime != nil && !isReserving }

    /// The steps the panel shows: a card charge only when the card pays something,
    /// a points step only when points are used.
    var reserveSteps: [(step: ReserveStep, label: String)] {
        guard let tender, let time = selectedTimeText else { return [] }
        var steps: [(ReserveStep, String)] = []
        if tender.cardAmount > 0 { steps.append((.chargingCard, "\(card.maskedText) charged \(tender.cardAmount.usd)")) }
        steps.append((.confirmingTable, "Table for \(party) at \(time) confirmed"))
        if tender.points > 0 { steps.append((.deductingPoints, "\(tender.points.grouped) points deducted")) }
        return steps
    }

    /// Reserves the table. Needs the terms box. Repeat taps while one is in
    /// flight are ignored, and a retry reuses the same key, so there is never
    /// more than one reservation.
    func reserveTable() async {
        guard canReserve, confirmedReservation == nil, let time = selectedTime, let tender,
              let key = idempotencyKey else { return }
        submissions += 1
        reserve = .inProgress(nil)
        let request = ReservationRequest(
            restaurantId: restaurant.id, date: setup.date, time: time, partySize: party,
            guestName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            guestEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
            guestPhone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            accessibilityNeeds: accessibilityList,
            specialRequests: specialRequests.isEmpty ? nil : specialRequests,
            dietaryNotes: dietaryNotes.isEmpty ? nil : dietaryNotes,
            tender: tender, card: card, customerId: customerId, tripId: tripId)
        let service = service
        let held = held
        let progress: (ReserveStep) -> Void = { [weak self] step in
            self?.reserve = .inProgress(step)
        }
        let outcome = await Task { @MainActor in
            try await service.reserve(request, holding: held, idempotencyKey: key, progress: progress)
        }.result
        switch outcome {
        case .success(let reservation):
            reserve = .done(reservation)
            onReserved(reservation)
        case .failure(DiningError.paymentDeclined):
            // Nothing reserved, no count change, no points deducted.
            reserve = .paymentFailed
        case .failure(DiningError.soldOut(let time)):
            // Nothing charged. Back to the times, where it now shows Sold out.
            reserve = .idle
            idempotencyKey = nil
            selectedTime = nil
            soldOutNotice = "\(TripCalendar.clock(time)) just filled up. Choose another time."
            await loadSlots()
        case .failure(DiningError.overlap(let existingId)):
            reserve = .idle
            overlap = held.first { $0.id == existingId }
        case .failure:
            reserve = .failed
        }
    }

    /// "Change card" on the payment-failed panel: back to the confirm bar.
    func dismissPaymentFailure() {
        if reserve == .paymentFailed || reserve == .failed { reserve = .idle }
    }
}
