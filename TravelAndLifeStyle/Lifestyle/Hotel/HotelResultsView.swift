//
//  HotelResultsView.swift
//  Lifestyle · Step 1 · which hotel
//
//  The first ten hotels, sorted by relevance, with filters and sort kept above
//  the results they affect. On regular width the selected hotel's details sit
//  beside the list.
//

import SwiftUI

struct HotelResultsView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var filterFocus: FilterSection?

    private var isRegular: Bool { horizontalSizeClass == .regular }

    var body: some View {
        let model = store.hotel

        Group {
            if isRegular {
                FlowSplit {
                    FlowPane {
                        HotelResultsList(model: model, selectedId: model.selectedHotelId, filterFocus: $filterFocus) { hotel in
                            withAnimation(Theme.Motion.select) { model.selectHotel(hotel.id) }
                        }
                    }
                } trailing: {
                    HotelDetailsPane(model: model)
                }
            } else {
                FlowPage(spacing: 10) {
                    // iPhone Duo, closed: the inner display shows a hotel beside the list.
                    OpenForMoreHint(text: "See each hotel beside the list.")
                    HotelResultsList(model: model, selectedId: nil, filterFocus: $filterFocus) { hotel in
                        model.selectHotel(hotel.id)
                        store.advance(to: .hotelDetails(hotelId: hotel.id))
                    }
                }
            }
        }
        .flowChrome(title: "Hotels in \(model.search.cityInSentence)")
        .task(id: model.search) {
            await model.loadResults()
            selectFirstIfNeeded()
        }
        .task(id: model.selectedHotelId) {
            guard isRegular else { return }
            async let details: Void = model.loadDetails()
            async let rooms: Void = model.loadRooms()
            _ = await (details, rooms)
        }
        .onChange(of: isRegular) { selectFirstIfNeeded() }
        .onChange(of: model.visibleHotels.map(\.id)) { selectFirstIfNeeded() }
        .sheet(item: $filterFocus) { focus in
            HotelFiltersSheet(model: model, focus: focus)
        }
    }

    /// With details beside the list, a hotel is always selected.
    private func selectFirstIfNeeded() {
        let model = store.hotel
        guard isRegular else { return }
        let visible = model.visibleHotels
        if let first = visible.first, !visible.contains(where: { $0.id == model.selectedHotelId }) {
            model.selectHotel(first.id)
        }
    }
}

// MARK: - List

struct HotelResultsList: View {
    @Environment(LifestyleStore.self) private var store
    @Bindable var model: HotelFlowModel
    /// Outlined in purple when details show beside the list.
    var selectedId: String?
    @Binding var filterFocus: FilterSection?
    var onSelect: (HotelSummary) -> Void

    var body: some View {
        StepHeader(step: 1, title: "Hotels in \(model.search.cityInSentence)")

        TripChip(search: model.search) {
            Button("Edit") { store.editHotelSearch() }
                .buttonStyle(.plain)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                .frame(minWidth: 36, minHeight: Theme.Size.touch)
                .contentShape(Rectangle())
                .accessibilityLabel("Edit search")
        }

        // Filters and sort stay with the results they affect.
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(FilterSection.allCases) { section in
                    FilterChip(section: section, isActive: section.isActive(in: model.filters, options: model.filterOptions)) {
                        filterFocus = section
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()

        SegmentedControl(options: HotelSort.allCases.map { .init(value: $0, label: $0.rawValue) },
                         selection: model.sort) { model.sort = $0 }
            .accessibilityLabel("Sort")

        switch model.results {
        case .loading:
            CardListSkeleton()
        case .failed:
            SectionErrorCard(title: "Couldn't load hotels", message: "Check your connection and try again.") {
                Task { await model.loadResults(force: true) }
            }
        case .loaded(let hotels):
            let visible = model.visibleHotels
            HStack(spacing: 6) {
                Text(visible.count == 1 ? "1 hotel" : "\(visible.count) hotels")
                    .textStyle(.footnoteEmphasis)
                Text(model.sort.note)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .accessibilityElement(children: .combine)

            if hotels.isEmpty {
                ResultsNote(title: "No hotels to show for \(model.search.cityInSentence)",
                            message: "Try the destination your trip is in.",
                            actionTitle: "Search \(model.destinationName(.trip))") {
                    model.setDestination(model.destinationName(.trip))
                }
            } else if visible.isEmpty {
                ResultsNote(title: "No hotels match these filters",
                            message: "Try a wider price range or fewer filters.",
                            actionTitle: "Clear filters") {
                    withAnimation(Theme.Motion.select) { model.filters = HotelFilters() }
                }
            } else {
                ForEach(visible) { hotel in
                    HotelCard(hotel: hotel, distanceFrom: model.filters.distanceFrom,
                              isSelected: hotel.id == selectedId) {
                        onSelect(hotel)
                    }
                }
            }
        }
    }
}

/// Image · name · neighborhood · distance · rating · cancellation · price and points per night.
struct HotelCard: View {
    let hotel: HotelSummary
    var distanceFrom = "City center"
    var isSelected = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Thumbnail(name: hotel.imageName, size: 92, radius: Theme.Radius.thumbnailLarge)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hotel.name)
                        .textStyle(.headline)
                    Text(hotel.locationText(from: distanceFrom))
                        .textStyle(.footnote, color: Theme.Colors.muted)
                    RatingLine(rating: hotel.ratingText, word: hotel.ratingWord)
                    if hotel.freeCancellation {
                        TagPill(text: "Free cancellation", tone: .mint)
                    } else {
                        Text("Non-refundable rates")
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(Decimal(hotel.cashPerNight).usdWhole)
                        .textStyle(.headline)
                    Text("per night")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                    Text(hotel.pointsPerNight.pointsText)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                .fixedSize()
            }
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .cardSurface()
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(Theme.Colors.purple2, lineWidth: 2)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Star · "4.7" · "Exceptional"
struct RatingLine: View {
    let rating: String
    let word: String
    var reviews: String?
    var style: Theme.TextStyle = .footnote
    var emphasis: Theme.TextStyle = .footnoteEmphasis

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.yellow)
                .overlay {
                    Image(systemName: "star")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.star)
                }
                .accessibilityHidden(true)
            Text(rating)
                .textStyle(emphasis)
            Text(word)
                .textStyle(style, color: Theme.Colors.muted)
            if let reviews {
                Text("· \(reviews)")
                    .textStyle(style, color: Theme.Colors.muted)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating), \(word)\(reviews.map { ", \($0)" } ?? "")")
    }
}

/// A note in place of results, with one way forward.
private struct ResultsNote: View {
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                NoteIcon(fill: Theme.Colors.tintPurple, foreground: Theme.Colors.purple) {
                    SymbolIcon(name: "magnifyingglass", size: 18)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .textStyle(.bodyEmphasis)
                    Text(message)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            Button(actionTitle, action: action)
                .buttonStyle(OutlineButtonStyle(horizontalPadding: 18))
                .padding(.leading, 56)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

// MARK: - Filter chips

/// The filter groups, in the order of the chips.
enum FilterSection: String, CaseIterable, Identifiable {
    case all = "Filters"
    case brand = "Brand"
    case price = "Price"
    case rating = "Rating"
    case amenities = "Amenities"
    case distance = "Distance"
    case accessibility = "Accessibility"

    var id: String { rawValue }

    func isActive(in filters: HotelFilters, options: HotelFilterOptions) -> Bool {
        switch self {
        case .all: filters != HotelFilters()
        case .brand: !filters.brands.isEmpty
        case .price: filters.price != nil && filters.price != options.priceRange
        case .rating: filters.minimumRating != nil
        case .amenities: !filters.amenities.isEmpty
        case .distance: filters.distanceFrom != HotelFilters().distanceFrom
        case .accessibility: !filters.accessibility.isEmpty
        }
    }
}

private struct FilterChip: View {
    let section: FilterSection
    let isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if section == .all {
                    SymbolIcon(name: "slider.horizontal.3", size: 14, weight: .semibold)
                }
                Text(section.rawValue)
                    .textStyle(.subheadEmphasis, color: foreground)
                    .lineLimit(1)
                if section != .all {
                    SymbolIcon(name: "chevron.down", size: 10, weight: .bold)
                        .foregroundStyle(isActive ? Theme.Colors.purple : Theme.Colors.ink2)
                }
            }
            .foregroundStyle(foreground)
            .padding(.leading, 14)
            .padding(.trailing, 12)
            .frame(minHeight: Theme.Size.touch)
            .background(isActive ? Theme.Colors.chipSelectedFill : Theme.Colors.cardFill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(isActive ? Theme.Colors.purple2 : Theme.Colors.chipBorder,
                                       lineWidth: Theme.Size.controlBorder)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(section == .all ? "Filters" : "\(section.rawValue) filter")
        .accessibilityValue(isActive ? "On" : "")
    }

    private var foreground: Color { isActive ? Theme.Colors.purple : Theme.Colors.ink }
}

#Preview("Results · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelSearch(destination: .trip))
    store.advance(to: .hotelResults)
    return LifestyleRootView(store: store)
}

#Preview("Results · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview()
    store.open(.hotelSearch(destination: .trip))
    store.advance(to: .hotelResults)
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}
