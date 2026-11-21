//
//  HotelCatalogTests.swift
//  TravelAndLifeStyleTests
//
//  Every hotel the search can return opens and books, in every destination,
//  and Fargo Concierge's dates carry into the hotel flow.
//

import Foundation
import Testing
import UIKit
@testable import TravelAndLifeStyle

@MainActor
struct HotelCatalogTests {
    private let service = MockAspireService(scenario: AspireScenario(reprice: .noChange, booking: .succeeds, delayScale: 0))
    private var trip: HotelSearch { HotelSampleData.sample.tripSearch }

    @Test func everyDestinationHasHotels() async throws {
        #expect(service.destinations.count >= 8)
        for destination in service.destinations {
            var search = trip
            search.destination = destination
            let hotels = try await service.search(search)
            #expect(hotels.count >= 4, "\(destination) should have hotels")
        }
    }

    /// Hotels show photographs, not the design artwork: every hotel and room
    /// photo is in the asset catalog, and a results list never repeats one.
    @Test func everyHotelAndRoomHasAPhoto() async throws {
        for hotel in HotelCatalog.hotels {
            #expect(hotel.imageName.hasPrefix("photo_"), "\(hotel.name) should show a photograph")
            #expect(UIImage(named: hotel.imageName) != nil, "\(hotel.imageName) is missing for \(hotel.name)")
            for photo in HotelCatalog.morePhotos(for: hotel.id) {
                #expect(UIImage(named: photo) != nil, "\(photo) is missing for \(hotel.name)")
            }
        }
        for destination in service.destinations {
            let photos = HotelCatalog.hotels(in: destination).map(\.imageName)
            #expect(Set(photos).count == photos.count, "\(destination) repeats a photo")
        }
        for hotel in HotelCatalog.hotels {
            for room in try await service.rooms(hotelId: hotel.id, search: trip) {
                #expect(UIImage(named: room.imageName) != nil, "\(room.imageName) is missing for \(room.name)")
            }
        }
        // The king room with a skyline in its window is for city hotels only.
        let resortRooms = try await service.rooms(hotelId: "HTL-CAR-0002", search: trip)
        #expect(!resortRooms.map(\.imageName).contains("photo_room_king"))
        let cityRooms = try await service.rooms(hotelId: HotelSampleData.sample.hotelDetails.hotelId, search: trip)
        #expect(cityRooms.first?.imageName == "photo_room_king")
        for hotel in InspireCatalog.hotels {
            #expect(hotel.imageName == HotelCatalog.hotel(id: hotel.id)?.imageName, "\(hotel.name) should use its catalog photo")
        }
    }

    @Test func houstonStillReturnsTheSampleResults() async throws {
        let hotels = try await service.search(trip)
        #expect(hotels.map(\.id) == HotelSampleData.sample.results.hotels.map(\.hotelId))
        #expect(hotels.first?.name == "Hotel Solenne")
        #expect(hotels.first?.cashPerNight == 250)
    }

    @Test func everyHotelHasDetailsAndRoomsToBook() async throws {
        for hotel in HotelCatalog.hotels {
            var search = trip
            search.destination = hotel.destination
            let details = try await service.details(hotelId: hotel.id)
            #expect(details.name == hotel.name)
            #expect(!details.address.isEmpty)
            #expect(!details.about.isEmpty)
            #expect(!details.amenities.isEmpty)

            let rooms = try await service.rooms(hotelId: hotel.id, search: search)
            #expect(rooms.count == 3)
            for room in rooms {
                #expect(!room.rates.isEmpty)
                // Free cancellation is offered exactly where the results say it is.
                #expect(room.rates.contains(where: \.refundable) == hotel.freeCancellation)
            }
            // The first rate is the price the results show.
            #expect(rooms.first?.rates.first?.cashPerNight == Decimal(hotel.cashPerNight))
        }
    }

    @Test func theSampleHotelKeepsItsSampleRates() async throws {
        let rooms = try await service.rooms(hotelId: "HTL-1001", search: trip)
        #expect(rooms.flatMap(\.rates).map(\.id) == ["RT-DK-FLEX", "RT-DK-SAVE", "RT-TQ-FLEX", "RT-JS-FLEX"])
        #expect(rooms.flatMap(\.rates).map(\.cashPerNight) == [250, 225, 265, 340])
    }

    @Test func anotherHoustonHotelBooksEndToEnd() async throws {
        let model = HotelFlowModel(service: service, balance: 12_450)
        var booked: [HotelBooking] = []
        model.onBooked = { booked.append($0) }

        model.begin()
        await model.loadResults()
        model.selectHotel("HTL-1002")
        await model.loadDetails()
        await model.loadRooms()
        #expect(model.canBookSelectedHotel)

        await model.repriceIfNeeded()
        #expect(model.canContinueToReview)
        model.prepareReview()
        await model.confirmAndBook()

        let booking = try #require(booked.first)
        #expect(booking.hotelName == "The Wrenfield")
        #expect(booking.city == "Houston, TX")
        #expect(booking.hotelAddress == "5410 Fannin Court, Houston, TX 77004")
        // In Houston, inside the trip's dates: it joins the trip.
        #expect(booking.tripId == HotelSampleData.sample.trip.tripId)
        // 3 nights at $219 plus 17%.
        #expect(booking.price?.total == Decimal(string: "768.69"))
    }

    @Test func aHotelInAnotherDestinationBooksOnItsOwn() async throws {
        let model = HotelFlowModel(service: service, balance: 12_450)
        var booked: [HotelBooking] = []
        model.onBooked = { booked.append($0) }

        model.begin(destination: .caribbean)
        await model.loadResults()
        #expect(model.allHotels.count == 4)
        // "Your dinner" is a distance only in Houston.
        #expect(!model.filterOptions.distanceFrom.contains(HotelFilters.dinnerOrigin))

        model.selectHotel("HTL-CAR-0002")
        await model.loadDetails()
        await model.loadRooms()
        await model.repriceIfNeeded()
        model.prepareReview()
        await model.confirmAndBook()

        let booking = try #require(booked.first)
        #expect(booking.hotelName == "Solenne Palm Cay")
        #expect(booking.city == "Palm Cay, Caribbean")
        // Not in the trip's city, so it isn't linked to the Houston trip.
        #expect(booking.tripId == nil)

        // And the Houston flights stay out of its itinerary.
        let store = BookingStore(existingTrip: HotelSampleData.sample.trip, customerId: "CUST-0042")
        store.todayOverride = SeedBookings.sample.today
        store.record(booking)
        let own = try #require(store.trips().first)
        #expect(own.title == "Your stay at Solenne Palm Cay")
        #expect(own.imageName == "beach")
        #expect(store.itinerary(for: own).items.map(\.kind) == [.hotelCheckIn, .hotelCheckOut])
    }

    @Test func changingDestinationClearsTheFilters() {
        let model = HotelFlowModel(service: service, balance: 12_450)
        model.begin()
        model.filters.distanceFrom = HotelFilters.dinnerOrigin
        model.filters.brands = ["Meridian"]
        model.setDestination("Seattle, WA")
        #expect(model.search.destination == "Seattle, WA")
        #expect(model.filters == HotelFilters())
        #expect(!model.isTripDestination)
    }

    @Test func inspireHotelsAreInTheCatalogAtTheSamePrice() {
        for pick in InspireCatalog.hotels {
            let hotel = HotelCatalog.hotel(id: pick.id)
            #expect(hotel?.name == pick.name)
            #expect(hotel.map { Decimal($0.cashPerNight) } == pick.pricePerNight)
            // A search for the pick's own city finds it.
            #expect(HotelCatalog.hotels(in: pick.city).contains { $0.id == pick.id })
        }
    }
}

/// Fargo Concierge's dates can be changed, and they carry into the hotel.
/// Day 1: every inspire-me prompt starts the guided chat and is answered with picks.
@MainActor
struct ConciergePromptTests {
    private func model() -> ConciergeModel {
        let store = LifestyleStore.preview()
        store.concierge.typingDelay = .zero
        return store.concierge
    }

    @Test func everyInspireCardAndPromptChipStartsAConversation() {
        let content = LifestyleContent.sample.concierge
        for prompt in content.inspireMe.map(\.prompt) + content.promptChips {
            let model = model()
            model.choose(prompt: prompt)
            #expect(model.stage != .start, "\(prompt) should start the chat")
            if model.stage == .questions {
                model.showPicks()
                #expect(model.picks.count == 2, "\(prompt) should be answered with two picks")
                #expect(model.picks.allSatisfy { $0.route != nil }, "every pick for \(prompt) should open something")
                #expect(model.picks.allSatisfy { !model.reason(for: $0).isEmpty })
            }
        }
    }

    @Test func aPromptWithItsOwnDestinationGetsStaysThere() {
        let model = model()
        model.choose(prompt: "A beach week under $3,000")
        #expect(model.destination == "The Caribbean")
        #expect(model.nights == 7)
        let hotels = model.picks.compactMap { $0.hotelId.flatMap(HotelCatalog.hotel(id:)) }
        #expect(hotels.count == 2)
        #expect(hotels.allSatisfy { $0.destination == HotelCatalog.caribbean })
        // Under $3,000 for the week, before taxes.
        #expect(hotels.allSatisfy { $0.cashPerNight * 7 <= 3_000 })
    }

    @Test func theBudgetAnswerChangesThePicks() {
        let model = model()
        model.choose(prompt: "A ski weekend in January")
        model.budget = "Under $200"
        let cheapest = HotelCatalog.hotels(in: HotelCatalog.skiResorts).map(\.cashPerNight).min()
        // Nothing at a ski resort is under $200, so the picks say so instead of pretending.
        #expect(cheapest.map { $0 >= 200 } == true)
        #expect(model.picks.allSatisfy { $0.why.contains("closest") })
        model.budget = "$300+"
        #expect(model.picks.first?.title == "Hotel Solenne Summit")
    }

    @Test func theSampleRequestStillGetsItsHotelAndDinner() {
        let model = model()
        model.choose(prompt: "Find a great hotel near great food")
        #expect(model.destination == "Houston")
        #expect(model.picks.map(\.title) == ["Hotel Solenne", "Osteria Lume"])
    }

    @Test func inspireMeAnswersEvenWithNoProfile() async {
        let model = model()
        model.choose(prompt: "Inspire me")
        #expect(model.stage == .inspired)
    }

    @Test func nightlyBudgetsAreReadFromTheirLabels() {
        #expect(ConciergeModel.nightlyRange(of: "Under $200") == 0...199)
        #expect(ConciergeModel.nightlyRange(of: "$200–300") == 200...300)
        #expect(ConciergeModel.nightlyRange(of: "$300+").contains(365))
        #expect(!ConciergeModel.nightlyRange(of: "$300+").contains(299))
    }
}

@MainActor
struct ConciergeDatesTests {
    private func day(_ iso: String) -> Date { TripCalendar.date(iso) }

    @Test func datesStartAsTheTripsAndCanBeChanged() {
        let model = LifestyleStore.preview().concierge
        #expect(model.datesText == "Dec 30 – Jan 2")
        #expect(model.nightsText == "3 nights")
        #expect(!model.hasCustomDates)

        model.setDates(checkIn: day("2027-01-08"), checkOut: day("2027-01-10"))
        #expect(model.datesText == "Jan 8 – Jan 10")
        #expect(model.nightsText == "2 nights")
        #expect(model.hasCustomDates)

        model.newChat()
        #expect(model.datesText == "Dec 30 – Jan 2")
    }

    @Test func checkoutStaysAfterCheckInAndWithinTheLongestStay() {
        let model = LifestyleStore.preview().concierge
        model.setDates(checkIn: day("2027-03-10"), checkOut: day("2027-03-10"))
        #expect(model.checkOut == day("2027-03-11"))
        model.setDates(checkIn: day("2027-03-10"), checkOut: day("2027-05-01"))
        #expect(model.nights == ConciergeModel.maxNights)
    }

    @Test func theDinnerReasonOnlySaysDuringYourStayWhenItIs() throws {
        let store = LifestyleStore.preview()
        let model = store.concierge
        let dinner = try #require(store.content.concierge.picks.first { $0.kind == "Dining" })
        #expect(model.reason(for: dinner).contains("during your stay"))
        model.setDates(checkIn: day("2027-01-08"), checkOut: day("2027-01-10"))
        #expect(!model.reason(for: dinner).contains("during your stay"))
    }

    @Test func aHotelPickOpensWithTheChangedDates() throws {
        let store = LifestyleStore.preview()
        let stay = try #require(store.content.concierge.picks.first { $0.kind == "Stay" })

        // Unchanged: the trip's dates.
        store.open(stay)
        #expect(store.hotel.search.checkIn == day("2026-12-30"))
        #expect(store.hotel.datesTag == "From your trip")

        store.path = []
        store.concierge.setDates(checkIn: day("2027-01-08"), checkOut: day("2027-01-10"))
        store.open(stay)
        #expect(store.hotel.search.checkIn == day("2027-01-08"))
        #expect(store.hotel.search.checkOut == day("2027-01-10"))
        #expect(store.hotel.datesTag == "From Fargo Concierge")
        #expect(store.path.last == .hotelDetails(hotelId: "HTL-1001"))
        // Outside the trip's dates, so the booking would stand alone.
        #expect(store.hotel.linkedTripId == nil)
    }
}
