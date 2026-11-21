//
//  ConciergeModel.swift
//  Lifestyle · simulated Concierge (scripted from sample-data.json, no network)
//

import Foundation
import Observation

@Observable
final class ConciergeModel {

    enum Stage: Int, Comparable {
        case start, questions, picks
        /// Day 5: picks from the saved travel profile.
        case inspired

        static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let content: ConciergeContent
    let firstName: String

    private(set) var stage: Stage = .start
    /// What the customer asked; shown as their bubble.
    private(set) var request: String?
    /// Concierge is "typing" before its next scripted line.
    private(set) var isTyping = false
    /// Concierge lines revealed so far (0…2).
    private(set) var revealedLines = 0

    var draft = ""

    // Follow-up answers. They survive stage changes, new layouts and display changes.
    var budget: String
    var vibes: Set<String>
    var dining: Set<String>

    /// Delay before each scripted reply; zero in previews and screenshots.
    var typingDelay: Duration = .milliseconds(900)

    private var replyTask: Task<Void, Never>?

    // Day 5 · Inspire me
    static let inspirePrompt = "Inspire me"
    private let inspire: InspireService
    private let profile: ProfileModel
    /// Nil while Concierge is "typing".
    private(set) var inspireResult: InspireResult?
    /// "More hotels" was asked for.
    private(set) var showsMoreHotels = false

    // Dates. They start as the trip's; the customer can change them.
    private(set) var checkIn: Date
    private(set) var checkOut: Date
    private let tripDates: (checkIn: Date, checkOut: Date)
    /// The date picker is showing.
    var isChoosingDates = false
    /// The latest night a stay can start, and its longest length, in the picker.
    static let maxNights = 14

    /// What the conversation is about when it started from an inspire-me
    /// prompt with its own destination. Nil for the sample's scripted request
    /// (a hotel near great food in Houston).
    private(set) var idea: Idea?

    init(content: ConciergeContent, firstName: String, inspire: InspireService, profile: ProfileModel,
         trip: HotelSearch = HotelSampleData.sample.tripSearch) {
        self.content = content
        self.firstName = firstName
        self.inspire = inspire
        self.profile = profile
        tripDates = (trip.checkIn, trip.checkOut)
        checkIn = trip.checkIn
        checkOut = trip.checkOut
        let followUps = content.followUps
        budget = followUps?.budgetPerNight.default ?? ""
        vibes = Set(followUps?.vibe.default ?? [])
        dining = Set(followUps?.dining.default ?? [])
    }

    // MARK: Script

    var followUps: ConciergeContent.FollowUps? { content.followUps }

    var introLine: String { content.conciergeLines.first ?? "" }

    /// The line over the picks. The sample's line is for its hotel and dinner;
    /// an idea is answered with two stays.
    var picksLine: String {
        idea == nil ? (content.conciergeLines.dropFirst().first ?? "") : "Two stays that fit. Tap one to see its rooms."
    }

    /// The same, where the picks sit across the fold from the chat.
    var picksReadyLine: String {
        idea == nil ? "Two picks that work together are ready. Tap one to start booking."
            : "Two stays that fit are ready. Tap one to see its rooms."
    }

    /// Where the conversation is looking: "Houston", "The Caribbean".
    var destination: String { Trip.cityName(idea?.destination ?? HotelCatalog.houston) }

    // MARK: Actions

    /// A prompt chip or inspire card was tapped. Every one starts the guided
    /// chat: "Inspire me" asks for picks from the travel profile, a prompt with
    /// its own destination is answered for that destination, and anything else
    /// gets the sample's request.
    func choose(prompt: String) {
        if prompt.caseInsensitiveCompare(Self.inspirePrompt) == .orderedSame {
            inspireMe()
        } else if let idea = Idea.matching(prompt) {
            begin(with: prompt, idea: idea)
        } else {
            begin(with: content.userRequest)
        }
    }

    /// The customer typed a request. Any request gets the follow-ups.
    func submitDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, stage == .start else { return }
        draft = ""
        if text.caseInsensitiveCompare(Self.inspirePrompt) == .orderedSame {
            inspireMe()
        } else {
            begin(with: text, idea: Idea.matching(text))
        }
    }

    func showPicks() {
        guard stage == .questions else { return }
        stage = .picks
        reply(revealing: 2)
    }

    /// "Edit" on the answers summary, and "Change dates".
    func editAnswers() {
        guard stage == .picks else { return }
        replyTask?.cancel()
        isTyping = false
        revealedLines = 1
        stage = .questions
    }

    func newChat() {
        replyTask?.cancel()
        isTyping = false
        revealedLines = 0
        inspireResult = nil
        showsMoreHotels = false
        checkIn = tripDates.checkIn
        checkOut = tripDates.checkOut
        isChoosingDates = false
        request = nil
        idea = nil
        draft = ""
        stage = .start
        budget = followUps?.budgetPerNight.default ?? ""
        vibes = Set(followUps?.vibe.default ?? [])
        dining = Set(followUps?.dining.default ?? [])
    }

    // MARK: Inspire me (Day 5)

    /// What Concierge says over the Inspire me picks.
    func inspireIntro(for result: InspireResult) -> String {
        result.isPersonal ? "Here are ideas picked from your travel profile."
            : "Here are a few ideas to start with. Save your favorite hotel brands and airlines in a travel profile and I'll pick from those."
    }

    /// Sends "Inspire me" and shows hotels, flights and a trip: matched to the
    /// saved profile where it has favorites, general ideas where it doesn't.
    func inspireMe() {
        replyTask?.cancel()
        request = Self.inspirePrompt
        idea = nil
        stage = .inspired
        inspireResult = nil
        showsMoreHotels = false
        isTyping = true
        let preferences = profile.preferences
        let inspire = inspire
        replyTask = Task { [weak self] in
            let outcome = await Task { try await inspire.recommendations(for: preferences) }.result
            guard !Task.isCancelled, let self else { return }
            self.isTyping = false
            if case .success(let result) = outcome {
                self.inspireResult = result
            } else {
                // The picks couldn't be loaded: back to the start.
                self.newChat()
            }
        }
    }

    /// "More hotels": adds the next hotels from the same favorite brands.
    func showMoreHotels() {
        guard stage == .inspired, inspireResult?.moreHotels.isEmpty == false else { return }
        showsMoreHotels = true
    }

    func toggleVibe(_ option: String) { vibes.formSymmetricDifference([option]) }
    func toggleDining(_ option: String) { dining.formSymmetricDifference([option]) }

    private func begin(with text: String, idea: Idea? = nil) {
        request = text
        self.idea = idea
        // An idea brings its own dates; the sample's request is for the trip's.
        checkIn = idea?.checkIn ?? tripDates.checkIn
        checkOut = TripCalendar.adding(days: idea?.nights ?? TripCalendar.nights(tripDates.checkIn, tripDates.checkOut), to: checkIn)
        stage = .questions
        reply(revealing: 1)
    }

    private func reply(revealing lines: Int) {
        replyTask?.cancel()
        guard typingDelay > .zero else {
            revealedLines = lines
            return
        }
        isTyping = true
        replyTask = Task { [weak self, typingDelay] in
            try? await Task.sleep(for: typingDelay)
            guard !Task.isCancelled, let self else { return }
            self.isTyping = false
            self.revealedLines = lines
        }
    }

    // MARK: Derived text

    /// "Dec 30 – Jan 2"
    var datesText: String { TripCalendar.shortRange(checkIn, checkOut) }
    var nights: Int { TripCalendar.nights(checkIn, checkOut) }
    var nightsText: String { nights == 1 ? "1 night" : "\(nights) nights" }
    /// The customer moved the dates away from the trip's.
    var hasCustomDates: Bool { checkIn != tripDates.checkIn || checkOut != tripDates.checkOut }

    /// Sets the stay. Checkout is kept at least a night after check-in and at
    /// most `maxNights` after it.
    func setDates(checkIn newCheckIn: Date, checkOut newCheckOut: Date) {
        checkIn = newCheckIn
        let earliest = TripCalendar.adding(days: 1, to: newCheckIn)
        let latest = TripCalendar.adding(days: Self.maxNights, to: newCheckIn)
        if newCheckOut.isOnOrBefore(newCheckIn) {
            checkOut = earliest
        } else if latest.isOnOrBefore(newCheckOut) {
            checkOut = latest
        } else {
            checkOut = newCheckOut
        }
    }

    /// Why a pick was chosen. The dinner is on one fixed night, so its reason
    /// only says "during your stay" when the dates include it.
    func reason(for pick: ConciergePick) -> String {
        guard idea == nil else { return pick.why }
        let dinner = DiningSampleData.sample.setup.date
        let includesDinner = checkIn.isOnOrBefore(dinner) && dinner.isOnOrBefore(checkOut)
        return includesDinner ? pick.why : pick.why.replacingOccurrences(of: ", during your stay", with: "")
    }
    var budgetText: String { budget.isEmpty ? "Any" : "\(budget) a night" }
    var vibeText: String { joined(vibes, in: followUps?.vibe.options) }
    var diningText: String { joined(dining, in: followUps?.dining.options) }
    var datesWithNightsText: String { "\(datesText) · \(nightsText)" }
    var picksSubtitle: String { "\(destination) · \(datesText)" }

    /// "Dec 30 – Jan 2 · $200–300 a night · Lively · Italian, chef's table"
    var answersSummary: String {
        [datesText, budgetText, sentenceCased(vibeText), sentenceCased(diningText)].joined(separator: " · ")
    }

    /// Selected options in their scripted order.
    private func joined(_ selection: Set<String>, in options: [String]?) -> String {
        let ordered = (options ?? []).filter(selection.contains)
        return ordered.isEmpty ? "Any" : ordered.joined(separator: ", ")
    }

    /// Keeps the first item's capital and lowercases the rest of the list.
    private func sentenceCased(_ list: String) -> String {
        let parts = list.components(separatedBy: ", ")
        guard let first = parts.first else { return list }
        return ([first] + parts.dropFirst().map { $0.lowercased() }).joined(separator: ", ")
    }
}

// MARK: - Inspire-me ideas

extension ConciergeModel {

    /// What an inspire-me prompt asks for. The chat is simulated, so each
    /// prompt that names a kind of trip has a destination and dates to answer
    /// with; its picks come from the hotel catalog.
    struct Idea: Equatable {
        /// A destination of `HotelCatalog`.
        let destination: String
        /// Nil: the dates of the customer's trip.
        let checkIn: Date?
        let nights: Int?
        /// "Under $3,000": the most the stay may cost, before taxes.
        let stayBudget: Int?

        /// The idea a prompt or a typed request is asking for, if it names one.
        static func matching(_ text: String) -> Idea? {
            let text = text.lowercased()
            func idea(_ destination: String, from date: String? = nil, nights: Int? = nil, under budget: Int? = nil) -> Idea {
                Idea(destination: destination, checkIn: date.map { TripCalendar.date($0) }, nights: nights, stayBudget: budget)
            }
            if text.contains("beach") { return idea(HotelCatalog.caribbean, from: "2027-01-09", nights: 7, under: 3_000) }
            if text.contains("ski") { return idea(HotelCatalog.skiResorts, from: "2027-01-15", nights: 2) }
            if text.contains("new york") { return idea("New York, NY") }
            if text.contains("relaxed weekend") { return idea("Austin, TX", from: "2027-01-22", nights: 2, under: 900) }
            return nil
        }
    }

    /// The picks Concierge answers with: the sample's hotel and dinner for its
    /// own request, or two stays for an idea.
    var picks: [ConciergePick] {
        guard let idea else { return content.picks }
        let hotels = HotelCatalog.hotels(in: idea.destination)
        let band = Self.nightlyRange(of: budget)
        func fitsStay(_ hotel: CatalogHotel) -> Bool {
            idea.stayBudget.map { hotel.cashPerNight * nights <= $0 } ?? true
        }
        func fitsBand(_ hotel: CatalogHotel) -> Bool { band.contains(hotel.cashPerNight) }

        // Best first: inside both budgets, then inside one, then by rating.
        let ranked = hotels.sorted { first, second in
            let scores = [first, second].map { (fitsStay($0) ? 2 : 0) + (fitsBand($0) ? 1 : 0) }
            if scores[0] != scores[1] { return scores[0] > scores[1] }
            return first.rating > second.rating
        }
        return ranked.prefix(2).map { hotel in
            var reasons: [String] = []
            reasons.append(fitsBand(hotel) && !budget.isEmpty
                ? "Inside your \(budget) budget, with a \(hotel.summary.ratingText) rating."
                : "A \(hotel.summary.ratingText) rating\(budget.isEmpty ? "." : "; the closest here to your \(budget) budget.")")
            if let stayBudget = idea.stayBudget {
                let total = Decimal(hotel.cashPerNight * nights).usdWhole
                reasons.append(fitsStay(hotel)
                    ? "\(nightsText.capitalizedFirst) come to \(total) before taxes, under your \(Decimal(stayBudget).usdWhole)."
                    : "\(nightsText.capitalizedFirst) come to \(total) before taxes.")
            }
            return ConciergePick(
                kind: "Stay", title: hotel.name,
                meta: "\(hotel.neighborhood) · \(Decimal(hotel.cashPerNight).usdWhole) a night · \(hotel.summary.ratingText) rating",
                why: reasons.joined(separator: " "), cta: "View rooms", image: hotel.imageName, opens: nil,
                hotelId: hotel.id)
        }
    }

    /// "Under $200" → …199, "$200–300" → 200…300, "$300+" → 300…; anything else → any price.
    static func nightlyRange(of option: String) -> ClosedRange<Int> {
        let numbers = option.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let first = numbers.first else { return 0...Int.max }
        if option.lowercased().hasPrefix("under") { return 0...(first - 1) }
        if let second = numbers.dropFirst().first { return first...max(first, second) }
        return first...Int.max
    }
}

private extension String {
    /// "7 nights" stays "7 nights"; "three nights" becomes "Three nights".
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
