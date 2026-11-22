//
//  HotelPhotosView.swift
//  Lifestyle · a hotel's photos, full screen
//
//  An overlay arrangement: the photos fill the screen and a glass booking
//  panel sits on top of them. On iPhone Duo, half folded, the system moves the
//  two apart, so the photos take one side of the fold and the hotel's details
//  and the way to book take the other. Opened by tapping a hotel's photos.
//

import SwiftUI

struct HotelPhotosView: View {
    @Environment(LifestyleStore.self) private var store

    var body: some View {
        @Bindable var store = store
        let model = store.hotel
        let count = max(model.details.value?.photos ?? 1, 1)

        ArrangementView {
            HotelPhotoPanel(model: model, page: min(store.photoPage, count - 1), count: count)
                // Where the panel goes when the fold separates it from the photos.
                .overlayArrangementEdge(VerticalEdge.bottom)
                .overlayArrangementEdge(HorizontalEdge.trailing)
        } secondary: {
            HotelPhotoPager(imageNames: model.galleryImages, count: count, page: $store.photoPage)
        }
        .arrangementViewStyle(.overlay)
        .flowChrome(title: model.selectedHotel?.name ?? "Photos")
        .task(id: model.selectedHotelId) {
            async let details: Void = model.loadDetails()
            async let rooms: Void = model.loadRooms()
            _ = await (details, rooms)
        }
    }
}

// MARK: - Photos

/// Paging photos that fill whatever space they are given.
private struct HotelPhotoPager: View {
    let imageNames: [String]
    let count: Int
    @Binding var page: Int
    @State private var position: Int?

    init(imageNames: [String], count: Int, page: Binding<Int>) {
        self.imageNames = imageNames
        self.count = count
        _page = page
        _position = State(initialValue: min(page.wrappedValue, count - 1))
    }

    private var current: Int { min(max(position ?? 0, 0), count - 1) }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { index in
                    Color.clear
                        .containerRelativeFrame([.horizontal, .vertical])
                        .overlay {
                            if !imageNames.isEmpty {
                                Image(imageNames[index % imageNames.count])
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .clipped()
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $position)
        .scrollIndicators(.hidden)
        .background(Theme.Colors.ink)
        .ignoresSafeArea()
        .onChange(of: position) { _, new in
            if let new { page = new }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo \(current + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            position = min(max(current + (direction == .increment ? 1 : -1), 0), count - 1)
        }
    }
}

// MARK: - Panel

/// Over the photos it is a glass bar: which photo, the hotel, its price and
/// Choose a room. Across the fold from them it has the room for the hotel's
/// details as well.
private struct HotelPhotoPanel: View {
    @Environment(LifestyleStore.self) private var store
    let model: HotelFlowModel
    let page: Int
    let count: Int

    var body: some View {
        if store.isPartiallyFolded {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    HotelDetailsContent(model: model, isPane: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SplitPaneInsets.margin)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bar.padding(SplitPaneInsets.margin)
            }
            // Frosted, so the details read even where a photo is behind them.
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Theme.Colors.frostFill)
                    .ignoresSafeArea()
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TagPill(text: "\(page + 1) / \(count) photos", tone: .image, symbol: "photo")
                    Spacer(minLength: 0)
                    PhotoDots(page: page, count: count)
                }
                bar
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            // The panel keeps to the bottom; the rest of the photo stays clear
            // and takes the swipes.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var bar: some View {
        ActionBar(buttonTitle: "Choose a room", isEnabled: model.canBookSelectedHotel,
                  disabledReason: "This hotel can't be booked in this version",
                  action: { store.advance(to: .hotelRooms) }) {
            if let hotel = model.selectedHotel {
                Text(hotel.name)
                    .textStyle(.headline)
                    .lineLimit(1)
                RatingLine(rating: hotel.ratingText, word: hotel.ratingWord)
            }
            HotelFromPrice(hotel: model.selectedHotel, showsPoints: false)
        }
    }
}

/// Up to five dots; the long one marks the photo showing.
struct PhotoDots: View {
    let page: Int
    let count: Int

    var body: some View {
        if count > 1 {
            let dots = min(count, 5)
            let active = Int((Double(page) / Double(count - 1) * Double(dots - 1)).rounded())
            HStack(spacing: 4) {
                ForEach(0..<dots, id: \.self) { dot in
                    Capsule()
                        .fill(dot == active ? Theme.Colors.white : Theme.Colors.pageDotIdle)
                        .frame(width: dot == active ? 16 : 6, height: 6)
                }
            }
            .animation(Theme.Motion.select, value: active)
            .accessibilityHidden(true)
        }
    }
}

#Preview("Photos") {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    store.advance(to: .hotelPhotos)
    return LifestyleRootView(store: store)
}
