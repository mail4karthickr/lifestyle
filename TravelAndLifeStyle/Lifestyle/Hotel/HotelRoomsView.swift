//
//  HotelRoomsView.swift
//  Lifestyle · Step 2 · exactly one room and rate
//
//  Every rate shows its cash price, points price, taxes and fees, and the
//  cancellation policy the API returned, before it is selected.
//

import SwiftUI

struct HotelRoomsView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let model = store.hotel
        let canContinue = model.selectedRate != nil

        Group {
            if horizontalSizeClass == .regular {
                // The room list beside the live "Your stay" summary.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        RoomList(model: model)
                    }
                } trailing: {
                    FlowPane {
                        YourStayPanel(model: model) { store.advance(to: .hotelCheckout) }
                    }
                }
            } else {
                FlowPage {
                    RoomList(model: model)
                } bar: {
                    ActionBar(buttonTitle: "Continue", isEnabled: canContinue,
                              disabledReason: "Choose a room and rate to continue",
                              action: { store.advance(to: .hotelCheckout) }) {
                        if let price = model.listedPrice {
                            Text(model.selectionText)
                                .textStyle(.subheadEmphasis)
                                .lineLimit(1)
                            Text("\(price.total.usd) total")
                                .textStyle(.headline)
                                .contentTransition(.numericText())
                            Text("\(model.search.nightsText) · taxes and fees included")
                                .textStyle(.footnote, color: Theme.Colors.muted)
                                .lineLimit(1)
                        } else {
                            ShimmerBlock().frame(width: 140, height: 16)
                        }
                    }
                    .animation(Theme.Motion.select, value: model.selectedRateId)
                }
            }
        }
        .flowChrome(title: "Choose a room")
        .task(id: model.selectedHotelId) {
            async let results: Void = model.loadResults()
            async let rooms: Void = model.loadRooms()
            _ = await (results, rooms)
        }
    }
}

// MARK: - Room list

private struct RoomList: View {
    let model: HotelFlowModel

    var body: some View {
        StepHeader(step: 2, title: "Choose a room")
        TripChip(search: model.search, tag: model.datesTag)

        switch model.rooms {
        case .loading:
            CardListSkeleton(count: 3, height: 170)
        case .failed:
            SectionErrorCard(title: "Couldn't load rooms", message: "Your search and hotel are still selected.") {
                Task { await model.loadRooms() }
            }
        case .loaded(let rooms):
            ForEach(rooms) { room in
                RoomCard(room: room, selectedRateId: model.selectedRateId) { rate in
                    withAnimation(Theme.Motion.select) { model.selectRate(rate.id) }
                }
            }
        }
    }
}

/// Image · name · beds, occupancy and size · features, then the room's rates.
struct RoomCard: View {
    let room: RoomType
    let selectedRateId: String?
    var onSelect: (Rate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Thumbnail(name: room.imageName, size: 76, radius: Theme.Radius.thumbnailLarge)
                VStack(alignment: .leading, spacing: 1) {
                    Text(room.name)
                        .textStyle(.headline)
                    Text(room.summaryText)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                    Text(room.featuresText)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 10)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ForEach(room.rates) { rate in
                RateRow(rate: rate, isSelected: rate.id == selectedRateId) { onSelect(rate) }
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .cardSurface()
    }
}

/// A rate, as a radio row: name, cancellation policy, taxes and fees, and price.
struct RateRow: View {
    let rate: Rate
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RadioMark(isOn: isSelected)
                VStack(alignment: .leading, spacing: 0) {
                    Text(rate.name)
                        .textStyle(.subheadEmphasis)
                    // Green when cancellation is free, grey when non-refundable.
                    Text(rate.policySummary)
                        .textStyle(.footnote, color: rate.refundable ? Theme.Colors.green : Theme.Colors.muted)
                    Text("+ \(rate.taxesAndFeesTotal.usd) taxes and fees")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(rate.cashPerNight.usdWhole)
                        .textStyle(.headline)
                    Text("per night")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                    Text(rate.pointsPerNight.pointsText)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                .fixedSize()
            }
            .padding(.vertical, 8)
            .frame(minHeight: 72)
            .overlay(alignment: .top) { Hairline() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(rate.cancellationPolicy)
    }
}

// MARK: - Your stay (regular width)

/// Hotel, dates and party, the selected room and rate, and the total, with Continue.
private struct YourStayPanel: View {
    let model: HotelFlowModel
    var onContinue: () -> Void

    var body: some View {
        SummaryPanel {
            Text("Your stay")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)

            if let hotel = model.selectedHotel {
                CardImage(name: hotel.imageName, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 10)
                VStack(alignment: .leading, spacing: 0) {
                    Text(hotel.name)
                        .textStyle(.headline)
                    Text("\(model.search.datesText) · \(model.search.nightsText)")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                    Text("\(model.search.guestsText) · \(model.search.roomsText)")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .padding(.top, 10)
                .accessibilityElement(children: .combine)
            }

            if let room = model.selectedRoom, let rate = model.selectedRate, let price = model.listedPrice {
                Hairline().padding(.vertical, 12)
                VStack(alignment: .leading, spacing: 0) {
                    Text(room.name)
                        .textStyle(.bodyEmphasis)
                    Text(rate.name)
                        .textStyle(.subhead, color: Theme.Colors.ink2)
                    Text(rate.policySummary)
                        .textStyle(.footnote, color: rate.refundable ? Theme.Colors.green : Theme.Colors.muted)
                }
                .accessibilityElement(children: .combine)
                Hairline().padding(.vertical, 12)
                VStack(spacing: 6) {
                    PriceBreakdown(price: price, spacing: 6, showsDivider: false)
                    Text("or \(price.totalInPoints.pointsText)")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .animation(Theme.Motion.select, value: rate.id)
            } else {
                ShimmerBlock(cornerRadius: 12)
                    .frame(height: 120)
                    .padding(.top, 12)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(FilledButtonStyle(kind: .red))
                .disabled(model.selectedRate == nil)
                .padding(.top, 14)
        }
    }
}

#Preview("Rooms · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    store.advance(to: .hotelRooms)
    return LifestyleRootView(store: store)
}

#Preview("Rooms · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    store.advance(to: .hotelRooms)
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}
