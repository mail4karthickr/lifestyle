//
//  ProfileModel.swift
//  Lifestyle · Day 5 · travel profile state and autosave
//
//  There is no Save button. Chips and the price range save on tap (debounced
//  per area); document fields save when the customer leaves them or the area.
//  Picks, typed text and save states live here, so they survive Back and every
//  iPhone Duo pose.
//

import Foundation
import Observation

enum SaveState: Equatable {
    case idle, saving, saved, failed
}

@Observable
final class ProfileModel {

    let service: PreferencesService
    let ecn: String
    let catalog: ProfileSampleData.Catalog
    let record: ProfileSampleData.Customer.Record

    /// Read with the landing page. Until it loads, the banner stays hidden.
    private(set) var isLoaded = false
    private(set) var preferences = TravelPreferences()
    /// The first successful save creates the profile.
    private(set) var hasProfile = false
    private(set) var optedOut = false
    /// Something was saved in this session; drives the one-time toast.
    private(set) var savedThisSession = false

    private(set) var areaStates: [ProfileArea: SaveState] = [:]
    private(set) var documentStates: [DocumentField: SaveState] = [:]
    private(set) var documentErrors: [DocumentField: String] = [:]
    /// Typed but not yet saved document text.
    var drafts: [DocumentField: String] = [:]
    /// Areas the customer has opened, and the ones they skipped.
    private(set) var visited: Set<ProfileArea> = []
    private(set) var skipped: Set<ProfileArea> = []

    /// How long quick taps are gathered into one request.
    var debounce: Duration = .milliseconds(700)

    private var pending: [ProfileArea: [String: PreferencePatch]] = [:]
    private var debounceTasks: [ProfileArea: Task<Void, Never>] = [:]
    private var failedPatches: [ProfileArea: [PreferencePatch]] = [:]

    init(service: PreferencesService, data: ProfileSampleData = .sample) {
        self.service = service
        ecn = data.customer.ecn
        catalog = data.catalog
        record = data.customer.record
    }

    // MARK: Loading

    func load() async {
        let service = service
        let ecn = ecn
        let outcome = await Task { try await service.load(ecn: ecn) }.result
        if case .success(let stored) = outcome {
            // Keep anything picked while the record was loading.
            if !savedThisSession { preferences = stored.preferences }
            hasProfile = hasProfile || stored.exists
            optedOut = stored.optedOut
            // What is already stored reads as saved.
            for area in ProfileArea.allCases where areaStates[area] == nil && !isEmpty(area) {
                areaStates[area] = .saved
            }
            for field in DocumentField.allCases where documentStates[field] == nil && storedDisplay(field) != nil {
                documentStates[field] = .saved
            }
        }
        isLoaded = true
    }

    /// The banner shows only to a customer with no saved preferences who hasn't
    /// opted out. A choice still on its way to the service counts as saved, so
    /// closing right after a tap doesn't bring the banner back for a moment.
    var showsBanner: Bool { isLoaded && !hasProfile && !optedOut && !isSaving }

    private var isSaving: Bool {
        areaStates.values.contains(.saving) || documentStates.values.contains(.saving)
    }

    // MARK: Setup

    func enter(_ area: ProfileArea) {
        visited.insert(area)
        skipped.remove(area)
    }

    /// Skip goes on without touching the area.
    func skip(_ area: ProfileArea) {
        if isEmpty(area) { skipped.insert(area) }
    }

    func isEmpty(_ area: ProfileArea) -> Bool {
        switch area {
        case .brands: preferences.brands.isEmpty
        case .dining: preferences.dining.isEmpty
        case .traveler: preferences.traveler.isEmpty
        }
    }

    func saveState(_ area: ProfileArea) -> SaveState { areaStates[area] ?? .idle }

    // MARK: Chips and price (save on tap, debounced per area)

    func isSelected(_ value: String, in keyPath: KeyPath<TravelPreferences, [String]>) -> Bool {
        preferences[keyPath: keyPath].contains(value)
    }

    func toggleHotelBrand(_ id: String) {
        preferences.brands.hotelBrandIds = toggled(id, in: preferences.brands.hotelBrandIds, order: catalog.hotelBrands.map(\.id))
        queue(.hotelBrands(preferences.brands.hotelBrandIds), area: .brands)
    }

    func toggleAirline(_ id: String) {
        preferences.brands.airlineIds = toggled(id, in: preferences.brands.airlineIds, order: catalog.airlines.map(\.id))
        queue(.airlines(preferences.brands.airlineIds), area: .brands)
    }

    func toggleVenue(_ id: String) {
        preferences.brands.venueIds = toggled(id, in: preferences.brands.venueIds, order: catalog.venues.map(\.id))
        queue(.venues(preferences.brands.venueIds), area: .brands)
    }

    func toggleRestaurant(_ id: String) {
        preferences.brands.restaurantIds = toggled(id, in: preferences.brands.restaurantIds, order: catalog.restaurants.map(\.id))
        queue(.restaurants(preferences.brands.restaurantIds), area: .brands)
    }

    func toggleCuisine(_ name: String) {
        preferences.dining.cuisines = toggled(name, in: preferences.dining.cuisines, order: catalog.cuisines)
        queue(.cuisines(preferences.dining.cuisines), area: .dining)
    }

    func toggleDietaryNeed(_ name: String) {
        preferences.dining.dietaryNeeds = toggled(name, in: preferences.dining.dietaryNeeds, order: catalog.dietaryNeeds)
        queue(.dietaryNeeds(preferences.dining.dietaryNeeds), area: .dining)
    }

    /// Single select; tapping the selected range again clears it.
    func choosePriceRange(_ range: String) {
        preferences.dining.priceRange = preferences.dining.priceRange == range ? nil : range
        queue(.priceRange(preferences.dining.priceRange), area: .dining)
    }

    /// Adds or removes a value, keeping the catalog's order.
    private func toggled(_ value: String, in list: [String], order: [String]) -> [String] {
        var set = Set(list)
        if !set.insert(value).inserted { set.remove(value) }
        return order.filter(set.contains)
    }

    private func queue(_ patch: PreferencePatch, area: ProfileArea) {
        skipped.remove(area)
        pending[area, default: [:]][patch.field] = patch
        areaStates[area] = .saving
        debounceTasks[area]?.cancel()
        let debounce = debounce
        debounceTasks[area] = Task { [weak self] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.flush(area)
        }
    }

    /// Sends what is waiting for an area now, as one run of requests.
    private func flush(_ area: ProfileArea) async {
        debounceTasks[area]?.cancel()
        debounceTasks[area] = nil
        let patches = Array((pending[area] ?? [:]).values) + (failedPatches[area] ?? [])
        pending[area] = nil
        failedPatches[area] = nil
        guard !patches.isEmpty else { return }
        areaStates[area] = .saving
        let failed = await send(patches)
        // Newer taps may be waiting already; their own save settles the pill.
        if !failed.isEmpty {
            failedPatches[area] = failed
            areaStates[area] = .failed
        } else if pending[area] == nil {
            areaStates[area] = .saved
        }
    }

    /// Returns the patches that didn't save.
    private func send(_ patches: [PreferencePatch]) async -> [PreferencePatch] {
        let service = service
        let ecn = ecn
        var failed: [PreferencePatch] = []
        for patch in patches {
            let outcome = await Task { try await service.save(ecn: ecn, patch: patch) }.result
            switch outcome {
            case .success:
                // The first saved choice counts as a profile.
                hasProfile = true
                savedThisSession = true
            case .failure:
                failed.append(patch)
            }
        }
        return failed
    }

    /// "Not saved · Retry"
    func retry(_ area: ProfileArea) {
        Task { await flush(area) }
    }

    // MARK: Documents (save on leaving the field or the area)

    func documentState(_ field: DocumentField) -> SaveState { documentStates[field] ?? .idle }

    /// What is stored for a document, as it may be shown: the last digits only.
    func storedDisplay(_ field: DocumentField) -> String? {
        switch field {
        case .ktn: preferences.traveler.ktnLast4.map(field.masked)
        case .passport: preferences.traveler.passportLast4.map(field.masked)
        case .redress: preferences.traveler.redressLast4.map(field.masked)
        case .country: preferences.traveler.passportCountry
        case .expiry: preferences.traveler.passportExpiry
        }
    }

    func clearDocumentError(_ field: DocumentField) { documentErrors[field] = nil }

    /// Checks and saves a document field. An empty field is left as it was.
    func commit(_ field: DocumentField) {
        let text = (drafts[field] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            drafts[field] = nil
            documentErrors[field] = nil
            return
        }
        if let problem = field.problem(with: text) {
            // Shown under the field; nothing is saved until it passes.
            documentErrors[field] = problem
            return
        }
        documentErrors[field] = nil
        // Only the last digits are kept here; the full number is never stored or logged.
        let display = field.isNumber ? String(text.suffix(4)).uppercased() : text
        drafts[field] = nil
        PreferencePatch.document(field, display: display).apply(to: &preferences)
        skipped.remove(.traveler)
        documentStates[field] = .saving
        areaStates[.traveler] = .saving
        Task { await saveDocument(field, display: display) }
    }

    private func saveDocument(_ field: DocumentField, display: String) async {
        let failed = await send([.document(field, display: display)])
        documentStates[field] = failed.isEmpty ? .saved : .failed
        let states = DocumentField.allCases.map(documentState)
        if states.contains(.failed) {
            failedPatches[.traveler] = (failedPatches[.traveler] ?? []) + failed
            areaStates[.traveler] = .failed
        } else if !states.contains(.saving) {
            areaStates[.traveler] = .saved
        }
    }

    func retryDocument(_ field: DocumentField) {
        guard let display = failedPatches[.traveler]?.compactMap({ patch -> String? in
            if case .document(field, let display) = patch { return display }
            return nil
        }).last else { return }
        failedPatches[.traveler]?.removeAll { $0 == .document(field, display: display) }
        documentStates[field] = .saving
        areaStates[.traveler] = .saving
        Task { await saveDocument(field, display: display) }
    }

    // MARK: Leaving an area

    /// Next, Skip and Back all save what is waiting.
    func leave(_ area: ProfileArea) {
        if area == .traveler {
            for field in DocumentField.allCases where drafts[field] != nil { commit(field) }
        }
        if pending[area] != nil {
            Task { await flush(area) }
        }
    }

    func leaveAll() {
        ProfileArea.allCases.forEach(leave)
    }

    // MARK: Opt out

    /// Records the opt-out against the ECN, so the customer isn't asked again.
    func optOut() async {
        optedOut = true
        let service = service
        let ecn = ecn
        _ = await Task { try await service.optOut(ecn: ecn) }.result
    }

    // MARK: Summary

    struct SummaryRow: Identifiable, Hashable {
        let label: String
        let value: String
        var id: String { label }
    }

    private func names(_ ids: [String], in options: [CatalogOption]) -> String {
        let chosen = options.filter { ids.contains($0.id) }.map(\.name)
        return chosen.isEmpty ? "Not set" : chosen.joined(separator: ", ")
    }

    private func list(_ values: [String]) -> String { values.isEmpty ? "Not set" : values.joined(separator: ", ") }

    func summary(_ area: ProfileArea) -> [SummaryRow] {
        switch area {
        case .brands:
            return [
                SummaryRow(label: "Hotels", value: names(preferences.brands.hotelBrandIds, in: catalog.hotelBrands)),
                SummaryRow(label: "Airlines", value: names(preferences.brands.airlineIds, in: catalog.airlines)),
                SummaryRow(label: "Venues", value: names(preferences.brands.venueIds, in: catalog.venues)),
                SummaryRow(label: "Restaurants", value: names(preferences.brands.restaurantIds, in: catalog.restaurants)),
            ]
        case .dining:
            return [
                SummaryRow(label: "Cuisines", value: list(preferences.dining.cuisines)),
                SummaryRow(label: "Dietary", value: list(preferences.dining.dietaryNeeds)),
                SummaryRow(label: "Price", value: preferences.dining.priceRange ?? "Not set"),
            ]
        case .traveler:
            let traveler = preferences.traveler
            var passport = "Not added"
            if let last4 = traveler.passportLast4 {
                let extras = [traveler.passportCountry, traveler.passportExpiry.map { "exp \($0)" }].compactMap { $0 }
                passport = extras.isEmpty ? "Saved · ending \(last4)" : "Saved · \(extras.joined(separator: ", "))"
            } else if traveler.passportCountry != nil || traveler.passportExpiry != nil {
                passport = [traveler.passportCountry, traveler.passportExpiry.map { "exp \($0)" }]
                    .compactMap { $0 }.joined(separator: ", ")
            }
            return [
                SummaryRow(label: "KTN", value: traveler.ktnLast4.map { "Saved · ending \($0)" } ?? "Not added"),
                SummaryRow(label: "Passport", value: passport),
                SummaryRow(label: "Redress", value: traveler.redressLast4.map { "Saved · ending \($0)" } ?? "Not added"),
            ]
        }
    }

    /// What an area collects, shown before the customer reaches it.
    func teaser(_ area: ProfileArea) -> String {
        switch area {
        case .brands: "Hotels, airlines, venues and restaurants you like"
        case .dining: "Cuisines, dietary needs, price range"
        case .traveler: "Name and contact from your profile; KTN, passport, redress"
        }
    }

    // MARK: Debug

    /// Replaces the profile in place, for demos and screenshots.
    func show(_ preferences: TravelPreferences) {
        self.preferences = preferences
        hasProfile = !preferences.isEmpty
        isLoaded = true
        for area in ProfileArea.allCases {
            visited.insert(area)
            areaStates[area] = isEmpty(area) ? .idle : .saved
        }
        for field in DocumentField.allCases {
            documentStates[field] = storedDisplay(field) == nil ? .idle : .saved
        }
    }
}
