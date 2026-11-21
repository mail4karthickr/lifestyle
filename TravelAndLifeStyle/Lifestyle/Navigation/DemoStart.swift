//
//  DemoStart.swift
//  Lifestyle · start the POC at a given step
//
//  `-lifestyleStart <step>` opens the app part-way through a flow, with the
//  earlier steps already answered from the sample data. For demos and
//  screenshots; without the argument the app starts on the landing page.
//

import Foundation

enum DemoStart: String, CaseIterable {
    // Day 2 · book a hotel
    case hotelSearch, hotelResults, hotelDetails, hotelRooms
    /// Checkout, as it opens: the reprice result is showing and nothing is accepted.
    case hotelCheckout
    /// Checkout with the price change accepted.
    case hotelCheckoutAccepted
    case hotelReview
    /// Review with the booking in progress.
    case hotelBooking
    case hotelConfirmed
    /// The itinerary, opened from the home page after booking.
    case itinerary
    /// The landing page after the hotel is booked.
    case homeAfterBooking

    // Day 3 · reserve a table (the designs' answers: 4 guests at 8:00 PM)
    case restaurant, diningTable
    /// Choose a table with a party of 6.
    case diningTableParty6
    case diningDetails
    /// Your details with the phone number missing, after Continue.
    case diningDetailsErrors
    case diningDeposit
    case diningReview
    /// Review with the terms box checked.
    case diningReviewTerms
    /// Review with the reservation in progress (or its outcome, for a failing scenario).
    case diningReserving
    case diningConfirmed
    /// The itinerary, opened from the dining confirmation.
    case diningItinerary
    /// The landing page after the table is reserved.
    case homeAfterDinner

    // Day 4 · My Trip (uses the bookings from `-lifestyleSeed`)
    /// The first trip's itinerary.
    case tripItinerary
    /// The first trip's dinner, from its itinerary.
    case dinnerDetails
    /// The first trip's hotel, from its itinerary.
    case stayDetails

    // Day 5 · travel profile and Inspire me
    case profileIntro, profileBrands, profileDining, profileTraveler, profileDone
    /// Concierge with "Inspire me" sent.
    case inspire
    /// Inspire me after "More hotels".
    case inspireMoreHotels

    // Day 1 · Fargo Concierge
    /// The chat after "Find a great hotel near great food": the follow-up questions.
    case conciergeQuestions
    /// The chat after "Show my picks".
    case conciergePicks
    /// The chat after the first inspire-me card ("A beach week…") and "Show my picks".
    case conciergeIdeaPicks

    static var launch: DemoStart? {
        UserDefaults.standard.string(forKey: "lifestyleStart").flatMap(DemoStart.init(rawValue:))
    }
}

extension LifestyleStore {

    /// Walks a flow up to `step`, making the same calls the screens make.
    func start(at step: DemoStart) async {
        switch step {
        case .hotelSearch, .hotelResults, .hotelDetails, .hotelRooms, .hotelCheckout, .hotelCheckoutAccepted,
             .hotelReview, .hotelBooking, .hotelConfirmed, .itinerary, .homeAfterBooking:
            await startHotel(at: step)
        case .restaurant, .diningTable, .diningTableParty6, .diningDetails, .diningDetailsErrors, .diningDeposit,
             .diningReview, .diningReviewTerms, .diningReserving, .diningConfirmed, .diningItinerary, .homeAfterDinner:
            await startDining(at: step)
        case .tripItinerary, .dinnerDetails, .stayDetails:
            startTrip(at: step)
        case .profileIntro, .profileBrands, .profileDining, .profileTraveler, .profileDone:
            await startProfile(at: step)
        case .inspire, .inspireMoreHotels:
            await startInspire(at: step)
        case .conciergeQuestions, .conciergePicks, .conciergeIdeaPicks:
            startConcierge(at: step)
        }
    }

    private func startHotel(at step: DemoStart) async {
        let hotelId = HotelSampleData.sample.hotelDetails.hotelId
        hotel.balance = rewardsBalance
        hotel.begin()
        path = [.hotelSearch(destination: .trip)]
        if step == .hotelSearch { return }

        await hotel.loadResults()
        path.append(.hotelResults)
        if step == .hotelResults { return }

        hotel.selectHotel(hotelId)
        await hotel.loadDetails()
        await hotel.loadRooms()
        path.append(.hotelDetails(hotelId: hotelId))
        if step == .hotelDetails { return }

        path.append(.hotelRooms)
        if step == .hotelRooms { return }

        path.append(.hotelCheckout)
        await hotel.repriceIfNeeded()
        if step == .hotelCheckout { return }

        hotel.acceptedChange = true
        if step == .hotelCheckoutAccepted { return }
        guard hotel.canContinueToReview else { return }

        path.append(.hotelReview)
        hotel.prepareReview()
        if step == .hotelReview { return }

        if step == .hotelBooking {
            Task { await hotel.confirmAndBook() }
            return
        }
        // Booking moves to the confirmation by itself.
        await hotel.confirmAndBook()
        switch step {
        case .itinerary:
            if let booking = hotel.confirmedBooking { path = [.itinerary(bookingId: booking.id)] }
        case .homeAfterBooking: path = []
        default: break
        }
    }

    private func startDining(at step: DemoStart) async {
        path = []
        open(.restaurant)
        if step == .restaurant { return }

        await dining.loadSlots()
        dining.fillSample()
        if step == .diningTableParty6 { dining.changeParty(by: dining.setup.maxPartySize) }
        path.append(.diningTable)
        if step == .diningTable || step == .diningTableParty6 { return }

        path.append(.diningDetails)
        if step == .diningDetailsErrors {
            dining.phone = ""
            _ = dining.validateDetails()
            return
        }
        if step == .diningDetails { return }
        // An overlapping table stops here, with the banner showing.
        guard dining.validateDetails() else { return }

        dining.prepareDeposit()
        path.append(.diningDeposit)
        if step == .diningDeposit { return }

        path.append(.diningReview)
        dining.prepareReview()
        if step == .diningReview { return }

        dining.termsAccepted = true
        if step == .diningReviewTerms { return }

        if step == .diningReserving {
            Task { await dining.reserveTable() }
            return
        }
        // Reserving moves to the confirmation by itself.
        await dining.reserveTable()
        guard let reservation = dining.confirmedReservation else { return }
        switch step {
        case .diningItinerary: path = [.diningConfirmed, .itinerary(bookingId: reservation.id)]
        case .homeAfterDinner: path = []
        default: break
        }
    }

    private func startTrip(at step: DemoStart) {
        guard let trip = bookings.trips().first else { return }
        path = [.itinerary(bookingId: trip.id)]
        switch step {
        case .dinnerDetails:
            if let dinner = trip.dinners.first {
                selectedBooking[trip.id] = .dining(dinner.id)
                path.append(.bookingDetails(.dining(dinner.id)))
            }
        case .stayDetails:
            if let stay = trip.hotels.first {
                selectedBooking[trip.id] = .hotel(stay.id)
                path.append(.bookingDetails(.hotel(stay.id)))
            }
        default:
            break
        }
    }

    private func startProfile(at step: DemoStart) async {
        await profile.load()
        path = [.profileIntro]
        if step == .profileIntro { return }
        path.append(.profileArea(.brands))
        if step == .profileBrands { return }
        path.append(.profileArea(.dining))
        if step == .profileDining { return }
        path.append(.profileArea(.traveler))
        if step == .profileTraveler { return }
        path = [.profileIntro, .profileDone]
    }

    private func startConcierge(at step: DemoStart) {
        path = [.concierge]
        concierge.typingDelay = .zero
        let ideaPrompt = concierge.content.inspireMe.first?.prompt
        concierge.choose(prompt: step == .conciergeIdeaPicks ? ideaPrompt ?? "" : concierge.content.userRequest)
        if step != .conciergeQuestions { concierge.showPicks() }
    }

    private func startInspire(at step: DemoStart) async {
        await profile.load()
        path = [.concierge]
        concierge.typingDelay = .zero
        concierge.inspireMe()
        if step == .inspireMoreHotels {
            // Wait for the picks, then ask for more.
            for _ in 0..<40 where concierge.inspireResult == nil {
                try? await Task.sleep(for: .milliseconds(100))
            }
            concierge.showMoreHotels()
        }
    }
}
