//
//  TripBuilderTests.swift
//  TravelAndLifeStyleTests
//
//  Day 4: trips are worked out from confirmed bookings on every load. These
//  cover the five cases in docs/sample-data-day4.json, the removal date, and
//  the overlap rules.
//

import Foundation
import Testing
@testable import TravelAndLifeStyle

@MainActor
struct TripBuilderTests {
    private let seeds = SeedBookings.sample

    private var hotel: Booking { .hotel(seeds.hotelHouston) }
    private var dinner: Booking { .dining(seeds.dinnerHouston) }
    private var lodge: Booking { .hotel(seeds.hotelKesselhorn) }

    private func day(_ iso: String) -> Date { TripCalendar.date(iso) }

    /// A dinner on a given day, for the overlap rules.
    private func dinner(id: String, on iso: String, city: String = "Houston, TX") -> Booking {
        .dining(DiningReservation(
            reservationId: id, customerId: "CUST-0042", tripId: nil, restaurantId: "RST", restaurantName: "Table \(id)",
            city: city, address: "", imageName: "resto", offering: "Dinner", date: day(iso), time: "19:00", partySize: 2,
            accessibilityNeeds: [], specialRequests: nil, dietaryNotes: nil, depositTotal: 200, pointsUsed: 0,
            cardCharged: 200, cardLast4: "4821", policy: "", status: "Confirmed", createdAt: day(iso)))
    }

    /// A hotel stay between two days, for the overlap rules.
    private func stay(id: String, from checkIn: String, to checkOut: String, city: String = "Austin, TX") -> Booking {
        .hotel(HotelBooking(
            aspireBookingId: id, confirmationNumber: id, status: "Confirmed", timestamp: day(checkIn), tripId: nil,
            customerId: "CUST-0042", hotelId: id, hotelName: "Hotel \(id)", city: city, hotelAddress: "", imageName: "city",
            roomId: "", roomName: "King", rateId: "", rateName: "", cancellationTerms: "", cancellationSummary: "",
            checkIn: day(checkIn), checkOut: day(checkOut), checkInFrom: "15:00", checkOutBy: "11:00", adults: 2, rooms: 1,
            price: nil, tender: nil, cardLast4: ""))
    }

    // MARK: The five cases in the sample data

    @Test func nothingBookedHasNoTrips() {
        #expect(TripBuilder.trips(from: [], today: seeds.today).isEmpty)
    }

    @Test func dinnerOnlyIsADinnerTile() throws {
        let trips = TripBuilder.trips(from: [dinner], today: seeds.today)
        let trip = try #require(trips.first)
        #expect(trips.count == 1)
        #expect(trip.title == "Your dinner at Osteria Lume")
        #expect(trip.destination == "Houston, TX")
        #expect(trip.datesText == "Fri, Jan 1, 2027 · 8:00 PM")
        #expect(!trip.hasStay)
        #expect(trip.hasDining)
        #expect(trip.imageName == "houston")
    }

    @Test func hotelOnlyIsAStayTile() throws {
        let trips = TripBuilder.trips(from: [hotel], today: seeds.today)
        let trip = try #require(trips.first)
        #expect(trips.count == 1)
        #expect(trip.title == "Your stay at Hotel Solenne")
        #expect(trip.destination == "Houston, TX")
        #expect(trip.datesText == "Dec 30, 2026 – Jan 2, 2027")
        #expect(trip.hasStay)
        #expect(!trip.hasDining)
        #expect(trip.imageName == "houston")
    }

    @Test func hotelAndDinnerWithOverlappingDatesAreOneTrip() throws {
        let trips = TripBuilder.trips(from: [dinner, hotel], today: seeds.today)
        let trip = try #require(trips.first)
        #expect(trips.count == 1)
        #expect(trip.title == "Your trip in Houston")
        #expect(trip.destination == "Houston, TX")
        #expect(trip.datesText == "Dec 30, 2026 – Jan 2, 2027")
        #expect(trip.hasStay)
        #expect(trip.hasDining)
        #expect(trip.imageName == "houston")
    }

    @Test func twoTripsShowUpcomingFirst() {
        let trips = TripBuilder.trips(from: [lodge, dinner, hotel], today: seeds.today)
        #expect(trips.map(\.title) == ["Your trip in Houston", "Your stay at Kesselhorn Lodge"])
        #expect(trips.last?.destination == "Silver Basin, CO")
        #expect(trips.last?.datesText == "Feb 12 – 16, 2027")
        #expect(trips.last?.hasStay == true)
        #expect(trips.last?.hasDining == false)
        #expect(trips.last?.imageName == "alpine")
    }

    // MARK: Refresh and removal

    @Test func addingAHotelTurnsADinnerIntoATrip() {
        let before = TripBuilder.trips(from: [dinner], today: seeds.today)
        let after = TripBuilder.trips(from: [dinner, hotel], today: seeds.today)
        #expect(before.map(\.title) == ["Your dinner at Osteria Lume"])
        #expect(after.map(\.title) == ["Your trip in Houston"])
    }

    @Test func aTileShowsThroughItsEndDateAndGoesTheDayAfter() {
        let bookings = [hotel, dinner, lodge]
        // Checkout day: still there.
        #expect(TripBuilder.trips(from: bookings, today: day("2027-01-02")).count == 2)
        // The day after checkout: Houston is gone, Kesselhorn remains.
        #expect(TripBuilder.trips(from: bookings, today: day("2027-01-03")).map(\.title) == ["Your stay at Kesselhorn Lodge"])
        #expect(TripBuilder.trips(from: bookings, today: day("2027-02-16")).count == 1)
        #expect(TripBuilder.trips(from: bookings, today: day("2027-02-17")).isEmpty)
    }

    @Test func aDinnerTileGoesTheDayAfterTheDinner() {
        #expect(TripBuilder.trips(from: [dinner], today: day("2027-01-01")).count == 1)
        #expect(TripBuilder.trips(from: [dinner], today: day("2027-01-02")).isEmpty)
    }

    // MARK: Matching rules

    @Test func checkInAndCheckoutDaysCountAsOverlap() {
        let onCheckIn = TripBuilder.trips(from: [stay(id: "A", from: "2027-03-10", to: "2027-03-12"), dinner(id: "D1", on: "2027-03-10")],
                                          today: day("2027-03-01"))
        let onCheckout = TripBuilder.trips(from: [stay(id: "A", from: "2027-03-10", to: "2027-03-12"), dinner(id: "D2", on: "2027-03-12")],
                                           today: day("2027-03-01"))
        let dayAfter = TripBuilder.trips(from: [stay(id: "A", from: "2027-03-10", to: "2027-03-12"), dinner(id: "D3", on: "2027-03-13")],
                                         today: day("2027-03-01"))
        #expect(onCheckIn.count == 1)
        #expect(onCheckout.count == 1)
        #expect(dayAfter.count == 2)
    }

    @Test func overlapsChainIntoOneTrip() throws {
        // A overlaps B and B overlaps C, so all three are one trip; D stands alone.
        let bookings = [
            stay(id: "C", from: "2027-03-14", to: "2027-03-16"),
            stay(id: "A", from: "2027-03-10", to: "2027-03-12"),
            stay(id: "B", from: "2027-03-12", to: "2027-03-14"),
            dinner(id: "D", on: "2027-03-20"),
        ]
        let trips = TripBuilder.trips(from: bookings, today: day("2027-03-01"))
        let first = try #require(trips.first)
        #expect(trips.count == 2)
        #expect(first.bookings.count == 3)
        #expect(first.start == day("2027-03-10"))
        #expect(first.end == day("2027-03-16"))
        // Stable: the trip is named by its earliest booking.
        #expect(first.id == "A")
        #expect(first.title == "Your trip in Austin")
        #expect(trips.last?.title == "Your dinner at Table D")
    }

    @Test func aDinnerWithNoOverlappingHotelGetsItsOwnTile() {
        let trips = TripBuilder.trips(from: [lodge, dinner], today: seeds.today)
        #expect(trips.map(\.title) == ["Your dinner at Osteria Lume", "Your stay at Kesselhorn Lodge"])
    }

    @Test func theSameBookingsInAnyOrderGiveTheSameTrips() {
        let one = TripBuilder.trips(from: [hotel, dinner, lodge], today: seeds.today)
        let other = TripBuilder.trips(from: [lodge, dinner, hotel], today: seeds.today)
        #expect(one.map(\.id) == other.map(\.id))
        #expect(one.map(\.title) == other.map(\.title))
    }

    // MARK: Itinerary

    @Test func theHoustonItineraryMatchesTheSample() throws {
        let trip = HotelSampleData.sample.trip
        let store = BookingStore(existingTrip: trip, customerId: "CUST-0042", seed: .hotelAndDinner)
        store.todayOverride = seeds.today
        let houston = try #require(store.trips().first)
        let itinerary = store.itinerary(for: houston)

        #expect(itinerary.trip.title == "Your trip in Houston")
        #expect(itinerary.datesLine == "Dec 30, 2026 – Jan 2, 2027 · Houston, TX")
        #expect(itinerary.tags.map(\.text) == ["3 nights", "1 stay", "1 dinner", "2 flights"])
        // Days with nothing booked are left out.
        #expect(itinerary.days.map(\.label) == ["Wed, Dec 30", "Fri, Jan 1", "Sat, Jan 2"])
        #expect(itinerary.days.map(\.dayOfTrip) == ["Day 1 of 4", "Day 3 of 4", "Day 4 of 4"])
        // Grouped by day and sorted by time.
        #expect(itinerary.items.map(\.title) == [
            "Flight SFO → IAH", "Check in · Hotel Solenne", "Dinner · Osteria Lume",
            "Check out · Hotel Solenne", "Flight IAH → SFO",
        ])
        #expect(itinerary.items.map(\.line) == [
            "Coast Air 1015 · arrives 4:05 PM", "Deluxe King · 3 nights · 2 guests", "Chef’s table · party of 4",
            "1200 Lamar Arcade, Houston", "Coast Air 1022 · arrives 8:55 PM",
        ])
    }

    @Test func seededFlightsNeverMakeATrip() {
        let trip = HotelSampleData.sample.trip
        let store = BookingStore(existingTrip: trip, customerId: "CUST-0042", seed: .none)
        store.todayOverride = seeds.today
        #expect(store.trips().isEmpty)
    }
}

/// Day 3: which start times fit a party, and what a booking does to the count.
@MainActor
struct DiningAvailabilityTests {
    private func model() async -> (DiningFlowModel, MockDiningService) {
        let service = MockDiningService(delayScale: 0)
        let model = DiningFlowModel(service: service, balance: 12_450)
        await model.loadSlots()
        return (model, service)
    }

    @Test func partyOfFourNeverSeesSevenOrTen() async {
        let (model, _) = await model()
        model.changeParty(by: 2)
        #expect(model.fittingSlots.map(\.id) == ["17:00", "18:00", "20:00", "21:00"])
        #expect(model.fittingSlots.map(\.tablesLeft) == [3, 4, 2, 0])
        #expect(model.hiddenTimesNote == "7:00 PM and 10:00 PM seat parties of 2 only.")
    }

    @Test func partyOfSixSeesOnlySixAndNine() async {
        let (model, _) = await model()
        model.changeParty(by: 4)
        #expect(model.fittingSlots.map(\.id) == ["18:00", "21:00"])
        #expect(model.hiddenTimesNote == "Parties of 5 or 6 sit at 6:00 PM or 9:00 PM only.")
    }

    @Test func aPartyChangeThatHidesTheChosenTimeClearsIt() async throws {
        let (model, _) = await model()
        let seven = try #require(model.fittingSlots.first { $0.id == "19:00" })
        model.select(seven)
        #expect(model.canContinueFromTable)
        model.changeParty(by: 1)
        #expect(model.selectedTime == nil)
        #expect(!model.canContinueFromTable)
    }

    @Test func depositIsOneHundredPerGuestAndPointsStayWithinTheBalance() async {
        let (model, _) = await model()
        model.changeParty(by: 2)
        model.prepareDeposit()
        #expect(model.deposit == 400)
        #expect(model.points == 10_000)
        #expect(model.maxPoints == 12_400)
        #expect(!model.canPayAllWithPoints)
        model.setPoints(99_999)
        #expect(model.points == 12_400)
    }

    @Test func reservingLowersTheCountOnceAndRepeatsChangeNothing() async throws {
        let (model, service) = await model()
        model.fillSample()
        #expect(model.validateDetails())
        model.prepareReview()
        var reserved: [DiningReservation] = []
        model.onReserved = { reserved.append($0) }

        // Not without the terms box.
        await model.reserveTable()
        #expect(reserved.isEmpty)

        model.termsAccepted = true
        await model.reserveTable()
        await model.reserveTable()
        #expect(reserved.count == 1)
        #expect(reserved.first?.pointsUsed == 10_000)
        #expect(reserved.first?.cardCharged == 300)

        let eight = try #require(try await service.slots().first { $0.id == "20:00" })
        #expect(eight.tablesLeft == 1)
    }

    @Test func aDeclinedCardReservesNothing() async throws {
        let service = MockDiningService(scenario: .paymentDeclined, delayScale: 0)
        let model = DiningFlowModel(service: service, balance: 12_450)
        await model.loadSlots()
        model.fillSample()
        model.prepareReview()
        model.termsAccepted = true
        var reserved = 0
        model.onReserved = { _ in reserved += 1 }

        await model.reserveTable()
        #expect(model.reserve == .paymentFailed)
        #expect(reserved == 0)
        let eight = try #require(try await service.slots().first { $0.id == "20:00" })
        #expect(eight.tablesLeft == 2)

        // Try again goes through, once.
        await model.reserveTable()
        #expect(reserved == 1)
    }

    @Test func anOverlappingTableIsBlocked() async {
        let (model, _) = await model()
        model.held = [DiningSampleData.sample.overlapDemoReservation(customerId: "CUST-0042", tripId: nil)]
        model.fillSample()
        #expect(!model.validateDetails())
        #expect(model.overlap != nil)
    }
}

/// Day 5: Inspire me recommends hotels, flights and a trip from the saved brands and airlines.
@MainActor
struct InspireMatchingTests {
    @Test func theSampleProfileGetsTheSampleResponse() {
        let result = MockInspireService.match(ProfileSampleData.sample.afterSetup)
        #expect(result.basedOn == ["Solenne Collection", "Meridian Hotels", "Coast Air"])
        #expect(result.hotels.map(\.name) == ["Hotel Solenne Miami Beach", "Meridian Austin"])
        #expect(result.flights.map(\.flight) == ["Coast Air 1408", "Coast Air 2210"])
        #expect(result.trip?.title == "Miami long weekend")
        #expect(result.trip?.estimateText == "Est. $1,650 for 2")
        #expect(result.trip?.because == ["Your airline", "Your hotel brand"])
        #expect(result.followUpChips == ["Build the Miami trip", "More hotels"])
    }

    /// Day 5: "recommend hotels, flights, and trips". All three, whatever is saved.
    @Test func inspireMeAlwaysRecommendsHotelsFlightsAndATrip() {
        var brandsOnly = TravelPreferences()
        brandsOnly.brands.hotelBrandIds = ["hb-solenne"]
        var airlinesOnly = TravelPreferences()
        airlinesOnly.brands.airlineIds = ["al-pacific"]
        var diningOnly = TravelPreferences()
        diningOnly.dining.cuisines = ["Italian"]
        var noSharedCity = TravelPreferences()
        noSharedCity.brands.hotelBrandIds = ["hb-larkspur"]   // Denver
        noSharedCity.brands.airlineIds = ["al-pacific"]       // flies to Seattle

        for preferences in [brandsOnly, airlinesOnly, diningOnly, noSharedCity, TravelPreferences()] {
            let result = MockInspireService.match(preferences)
            #expect(!result.hotels.isEmpty)
            #expect(!result.flights.isEmpty)
            let trip = result.trip
            #expect(trip != nil)
            // The trip's flight goes where its hotel is.
            if let trip {
                #expect(InspireCatalog.flight(to: trip.hotel.city, in: [trip.flight]) != nil)
            }
        }
    }

    @Test func hotelsMatchFavoriteBrandsAndFlightsMatchFavoriteAirlines() {
        var preferences = TravelPreferences()
        preferences.brands.hotelBrandIds = ["hb-solenne"]
        var result = MockInspireService.match(preferences)
        #expect(result.hotels.allSatisfy { $0.brandId == "hb-solenne" })
        #expect(result.hotels.allSatisfy(result.isFavorite))
        // No airline is saved, so the flights are suggestions, not matches.
        #expect(!result.flights.contains(where: result.isFavorite))
        #expect(result.trip?.because == ["Your hotel brand"])
        #expect(result.basedOn == ["Solenne Collection"])

        preferences = TravelPreferences()
        preferences.brands.airlineIds = ["al-pacific"]
        result = MockInspireService.match(preferences)
        #expect(result.flights.allSatisfy { $0.airlineId == "al-pacific" })
        // No brand is saved: the first hotel is where the airline flies.
        #expect(result.hotels.first?.city == "Seattle, WA")
        #expect(!result.hotels.contains(where: result.isFavorite))
        #expect(result.trip?.because == ["Your airline"])
    }

    @Test func nothingSavedStillGetsIdeasButNotAsMatches() {
        let result = MockInspireService.match(TravelPreferences())
        #expect(!result.isPersonal)
        #expect(result.basedOn.isEmpty)
        #expect(result.trip?.because == [])
    }

    @Test func documentChecksCatchTypos() {
        #expect(DocumentField.ktn.problem(with: "1234567") != nil)
        #expect(DocumentField.ktn.problem(with: "TT1234417") == nil)
        #expect(DocumentField.passport.problem(with: "X12") != nil)
        #expect(DocumentField.passport.problem(with: "X1238823") == nil)
        #expect(DocumentField.redress.problem(with: "12345678") != nil)
        #expect(DocumentField.expiry.problem(with: "13/2031") != nil)
        #expect(DocumentField.expiry.problem(with: "09/2020", today: TripCalendar.date("2026-11-21")) != nil)
        #expect(DocumentField.expiry.problem(with: "09/2031", today: TripCalendar.date("2026-11-21")) == nil)
    }
}
