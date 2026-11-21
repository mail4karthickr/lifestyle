//
//  SectionModels.swift
//  Lifestyle · one view model per independently loading section
//

import Foundation
import Observation

enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

/// Hero points (rewards).
@Observable
final class RewardsModel {
    private(set) var state: LoadState<Rewards>
    private let service: RewardsService

    init(service: RewardsService, state: LoadState<Rewards> = .loading) {
        self.service = service
        self.state = state
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await service.fetchRewards())
        } catch is CancellationError {
            // Left loading; the next appearance reloads.
        } catch {
            state = .failed
        }
    }
}

extension RewardsModel {
    /// Takes points off the balance after a booking that used them.
    func spend(points: Int) {
        guard let rewards = state.value, points > 0 else { return }
        state = .loaded(Rewards(points: max(rewards.points - points, 0), pointValueUSD: rewards.pointValueUSD))
    }
}

/// Travel and Dining carousel content.
@Observable
final class CarouselModel {
    private(set) var state: LoadState<CarouselContent>
    private let service: CarouselService

    init(service: CarouselService, state: LoadState<CarouselContent> = .loading) {
        self.service = service
        self.state = state
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await service.fetchCarousel())
        } catch is CancellationError {
        } catch {
            state = .failed
        }
    }
}

/// My plans: the customer's trips, built from their confirmed bookings on every load.
@Observable
final class TripsModel {
    private(set) var state: LoadState<[Trip]>
    private let service: BookingsService
    private let store: BookingStore

    init(service: BookingsService, store: BookingStore, state: LoadState<[Trip]> = .loading) {
        self.service = service
        self.store = store
        self.state = state
    }

    /// Fetches the latest bookings and reruns trip matching and tile logic.
    /// Tiles already showing stay up while a refresh is in flight.
    func load() async {
        if state.value == nil { state = .loading }
        let service = service
        let outcome = await Task { try await service.fetchBookings() }.result
        switch outcome {
        case .success(let bookings):
            state = .loaded(TripBuilder.trips(from: bookings, today: store.today))
        case .failure:
            state = .failed
        }
    }

    /// Reruns the rules over what is already in the store, without a fetch.
    func rebuild() {
        state = .loaded(store.trips())
    }
}
