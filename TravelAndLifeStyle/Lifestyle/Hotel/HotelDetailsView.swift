//
//  HotelDetailsView.swift
//  Lifestyle · Step 1 · is this the one
//
//  Name, address, photos, amenities and ratings. Trip dates and travelers carry
//  over and the hotel ID is kept. On regular width this is the trailing pane of
//  the results.
//

import SwiftUI

struct HotelDetailsView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            // Results and details share the screen.
            HotelResultsView()
        } else {
            HotelDetailsCompact(model: store.hotel)
        }
    }
}

// MARK: - Compact

/// The photo runs full width, under the bars; everything else keeps to the safe area.
private struct HotelDetailsCompact: View {
    @Environment(LifestyleStore.self) private var store
    let model: HotelFlowModel

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let container = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                   height: proxy.size.height + insets.top + insets.bottom)
            let margin = LandingMetrics.margin(forWidth: container.width)
            let leading = max(insets.leading, margin)
            let trailing = max(insets.trailing, margin)

            ScrollView {
                VStack(spacing: 0) {
                    HotelGallery(imageNames: model.galleryImages, photoCount: model.details.value?.photos ?? 1,
                                 height: container.height < 760 ? 220 : 300, tagLeading: leading,
                                 onOpen: { store.openPhotos(at: $0) })
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28,
                                                          style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        HotelDetailsContent(model: model, isPane: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HotelChooseRoomBar(model: model)
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .padding(.bottom, insets.bottom > 0 ? 0 : 12)
            }
            .ignoresSafeArea(.container, edges: [.top, .horizontal])
        }
        .flowChrome(title: model.selectedHotel?.name ?? "Hotel details")
        .task(id: model.selectedHotelId) {
            // Arriving straight from a Concierge pick, the results aren't loaded yet.
            async let results: Void = model.loadResults()
            async let details: Void = model.loadDetails()
            async let rooms: Void = model.loadRooms()
            _ = await (results, details, rooms)
        }
    }
}

/// "From $250 a night" and Choose a room, in the sticky glass bar.
private struct HotelChooseRoomBar: View {
    @Environment(LifestyleStore.self) private var store
    let model: HotelFlowModel

    var body: some View {
        ActionBar(buttonTitle: "Choose a room", isEnabled: model.canBookSelectedHotel,
                  disabledReason: "This hotel can't be booked in this version",
                  action: { store.advance(to: .hotelRooms) }) {
            HotelFromPrice(hotel: model.selectedHotel)
        }
    }
}

struct HotelFromPrice: View {
    let hotel: HotelSummary?
    var showsPoints = true

    var body: some View {
        if let hotel {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("From \(Decimal(hotel.cashPerNight).usdWhole)")
                    .textStyle(.headline)
                Text("a night")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            if showsPoints {
                Text("or \(hotel.pointsPerNight.pointsText) · taxes extra")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
        } else {
            ShimmerBlock().frame(width: 120, height: 16)
        }
    }
}

// MARK: - Regular (trailing pane of the results)

struct HotelDetailsPane: View {
    @Environment(LifestyleStore.self) private var store
    let model: HotelFlowModel

    var body: some View {
        FlowPane {
            if model.selectedHotel != nil {
                HotelGallery(imageNames: model.galleryImages, photoCount: model.details.value?.photos ?? 1,
                             height: 150, tagLeading: 12, onOpen: { store.openPhotos(at: $0) })
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .id(model.selectedHotelId)
                HotelDetailsContent(model: model, isPane: true)
            } else if model.results.isLoading {
                CardListSkeleton(count: 2, height: 150)
            } else {
                // Nothing in the list to show details for.
                InfoNote(text: "Choose a hotel to see its photos, amenities and what's nearby.")
                    .padding(14)
                    .cardSurface(radius: Theme.Radius.note)
            }
        } footer: {
            VStack(spacing: 10) {
                Hairline()
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        HotelFromPrice(hotel: model.selectedHotel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    Button("Choose a room") { store.advance(to: .hotelRooms) }
                        .buttonStyle(FilledButtonStyle(kind: .red, fullWidth: false))
                        .disabled(!model.canBookSelectedHotel)
                }
            }
        }
    }
}

// MARK: - Content

/// Name, rating and address, then amenities, about and nearby.
struct HotelDetailsContent: View {
    @Environment(LifestyleStore.self) private var store
    let model: HotelFlowModel
    /// The pane shows the essentials; the full screen adds section titles, the trip chip and About.
    var isPane: Bool

    var body: some View {
        let hotel = model.selectedHotel
        let details = model.details.value

        VStack(alignment: .leading, spacing: 2) {
            Text(details?.name ?? hotel?.name ?? " ")
                .textStyle(.title1)
                .accessibilityAddTraits(.isHeader)
            if let hotel {
                RatingLine(rating: hotel.ratingText, word: hotel.ratingWord,
                           reviews: details.flatMap { $0.reviews > 0 ? "\($0.reviews.grouped) reviews" : nil },
                           style: .subhead, emphasis: .subheadEmphasis)
            }
            HStack(spacing: 5) {
                Glyph(shape: PinShape(), size: 16)
                    .foregroundStyle(Theme.Colors.muted)
                Text(details?.address ?? hotel.map { "\($0.neighborhood), \(model.search.destination)" } ?? " ")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
        }

        if !isPane {
            TripChip(search: model.search, tag: model.datesTag)
        }

        switch model.details {
        case .loading:
            CardListSkeleton(count: 2, height: 124)
        case .failed:
            SectionErrorCard(title: "Couldn't load this hotel", message: "Your dates and guests are saved.") {
                Task { await model.loadDetails() }
            }
        case .loaded(let details):
            if !isPane { sectionTitle("Amenities") }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(details.amenities, id: \.self) { amenity in
                    HStack(spacing: 8) {
                        SymbolIcon(name: Self.symbol(for: amenity), size: 15)
                            .foregroundStyle(Theme.Colors.purple)
                            .frame(width: 20)
                        Text(amenity)
                            .textStyle(.footnoteEmphasis)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .cardSurface(radius: 14)
                }
            }

            if !isPane {
                sectionTitle("About")
                Text(details.about)
                    .textStyle(.subhead, color: Theme.Colors.ink2)
            }

            // A hotel Inspire me suggested has nothing nearby in the sample data.
            if !details.nearby.isEmpty {
                if !isPane { sectionTitle("Nearby") }
                VStack(spacing: 0) {
                    ForEach(Array(details.nearby.enumerated()), id: \.element.id) { index, place in
                        NearbyRow(place: place, showsDivider: index > 0) {
                            // Dining nearby links to Day 3's reservation flow.
                            if place.isDining { store.open(.restaurant) }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 14)
                .cardSurface(radius: 18)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .textStyle(.section)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private static func symbol(for amenity: String) -> String {
        let name = amenity.lowercased()
        if name.contains("wi-fi") { return "wifi" }
        if name.contains("pool") { return "figure.pool.swim" }
        if name.contains("fitness") { return "dumbbell" }
        if name.contains("parking") { return "parkingsign.square" }
        if name.contains("restaurant") { return "fork.knife" }
        if name.contains("accessible") { return "figure.roll" }
        return "checkmark.circle"
    }
}

private struct NearbyRow: View {
    let place: HotelDetails.Nearby
    let showsDivider: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                IconCircle(fill: place.isDining ? Theme.Colors.tintPurple : Theme.Colors.tintMagenta,
                           foreground: place.isDining ? Theme.Colors.purple : Theme.Colors.magenta) {
                    SymbolIcon(name: place.isDining ? "fork.knife" : "ticket", size: 15)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(place.name)
                        .textStyle(.subheadEmphasis)
                    Text(place.detail)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(place.walkText)
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.ink2)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(minHeight: 56)
            .overlay(alignment: .top) {
                if showsDivider { Hairline() }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private extension HotelDetails.Nearby {
    /// Restaurants link to the Day 3 reservation flow.
    var isDining: Bool {
        let text = detail.lowercased()
        return text.contains("table") || text.contains("italian") || text.contains("restaurant")
    }
}

// MARK: - Gallery

/// Paging photos with an "n / 8 photos" tag and page dots. Tapping a photo
/// opens the photos full screen, at that photo.
struct HotelGallery: View {
    let imageNames: [String]
    let photoCount: Int
    var height: CGFloat
    var tagLeading: CGFloat
    var onOpen: ((Int) -> Void)?
    @State private var page: Int? = 0

    private var count: Int { max(photoCount, 1) }
    private var current: Int { min(max(page ?? 0, 0), count - 1) }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { index in
                    Color.clear
                        .containerRelativeFrame(.horizontal)
                        .frame(height: height)
                        .overlay {
                            if !imageNames.isEmpty {
                                Image(imageNames[index % imageNames.count])
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { onOpen?(index) }
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .frame(height: height)
        .overlay(alignment: .bottomLeading) {
            TagPill(text: "\(current + 1) / \(count) photos", tone: .image, symbol: "photo")
                .padding(.leading, tagLeading)
                .padding(.bottom, 14)
        }
        .overlay(alignment: .bottom) {
            PhotoDots(page: current, count: count)
                .padding(.bottom, 22)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo \(current + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            let next = current + (direction == .increment ? 1 : -1)
            page = min(max(next, 0), count - 1)
        }
        .accessibilityAction(named: "View full screen") { onOpen?(current) }
    }
}

extension LifestyleStore {
    /// Opens the selected hotel's photos full screen, at the photo that was showing.
    func openPhotos(at page: Int) {
        photoPage = page
        advance(to: .hotelPhotos)
    }
}

extension HotelFlowModel {
    /// Photos for the gallery: the hotel, any more of it, then its rooms.
    var galleryImages: [String] {
        guard let hotel = selectedHotel else { return [] }
        guard details.value != nil else { return [hotel.imageName] }
        return [hotel.imageName] + HotelCatalog.morePhotos(for: hotel.id) + (rooms.value ?? []).map(\.imageName)
    }
}

#Preview("Details · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    return LifestyleRootView(store: store)
}
