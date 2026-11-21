//
//  HotelSearchView.swift
//  Lifestyle · Step 1 · where, when, who
//
//  Prefilled from the existing trip. Guest and room limits come from Aspire.
//

import SwiftUI

struct HotelSearchView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let model = store.hotel

        Group {
            if horizontalSizeClass == .regular {
                // Search beside the trip the hotel will join.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        HotelSearchForm(model: model) { store.advance(to: .hotelResults) }
                    }
                } trailing: {
                    FlowPane {
                        TripPreviewPanel(bookings: store.bookings)
                    }
                }
            } else {
                FlowPage {
                    HotelSearchForm(model: model) { store.advance(to: .hotelResults) }
                }
            }
        }
        .flowChrome(title: "Find a hotel")
    }
}

/// Destination, dates, guests and rooms, then Search hotels.
private struct HotelSearchForm: View {
    @Bindable var model: HotelFlowModel
    var onSearch: () -> Void

    var body: some View {
        StepHeader(step: 1, title: "Find a hotel",
                   subtitle: model.isTripDestination
                       ? "\(model.search.city) · for your trip"
                       : "\(model.search.city) · dates from your trip")

        VStack(spacing: 0) {
            Menu {
                ForEach(model.destinations, id: \.self) { destination in
                    Button(destination) { model.setDestination(destination) }
                }
            } label: {
                DetailRow(label: "Destination", value: model.search.destination, isLarge: true, showsDivider: false) {
                    Glyph(shape: PinShape(), size: 20, lineWidth: 1.9)
                } trailing: {
                    SymbolIcon(name: "chevron.right", size: 13, weight: .semibold)
                        .foregroundStyle(Theme.Colors.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Changes the destination")

            DetailRow(label: "Dates", value: model.search.datesText, isLarge: true) {
                SymbolIcon(name: "calendar", size: 17)
            } trailing: {
                TagPill(text: model.datesTag)
            }

            DetailRow(label: "Guests", value: model.search.adultsText, isLarge: true) {
                SymbolIcon(name: "person.2", size: 15)
            } trailing: {
                StepperControl(value: model.search.adults, name: "guests",
                               canDecrease: model.canRemoveGuest, canIncrease: model.canAddGuest) {
                    model.changeGuests(by: $0)
                }
            }

            DetailRow(label: "Rooms", value: model.search.roomsText, isLarge: true) {
                SymbolIcon(name: "bed.double", size: 15)
            } trailing: {
                StepperControl(value: model.search.rooms, name: "rooms",
                               canDecrease: model.canRemoveRoom, canIncrease: model.canAddRoom) {
                    model.changeRooms(by: $0)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .cardSurface(radius: Theme.Radius.groupCard)

        InfoNote(text: "Dates and travelers come from \(model.trip.title). Up to \(model.limits.maxGuests) guests and \(model.limits.maxRooms) rooms per booking.")

        Button(action: onSearch) {
            HStack(spacing: 6) {
                Text("Search hotels")
                SymbolIcon(name: "magnifyingglass", size: 15, weight: .bold)
            }
        }
        .buttonStyle(FilledButtonStyle(kind: .red))
    }
}

/// "Your trip in Houston": the flights, with an empty slot where the hotel will go.
struct TripPreviewPanel: View {
    let bookings: BookingStore

    var body: some View {
        SummaryPanel(spacing: 8) {
            Text(bookings.existingTrip.title)
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Text("Hotels you book here join this trip")
                .textStyle(.footnote, color: Theme.Colors.muted)
                .padding(.bottom, 10)
            ItineraryTimeline(days: bookings.existingTripItems(), showsReference: false,
                              showsHotelSlot: !bookings.existingTripHasHotel)
        }
    }
}

#Preview("Search · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelSearch(destination: .trip))
    return LifestyleRootView(store: store)
}

#Preview("Search · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview()
    store.open(.hotelSearch(destination: .trip))
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}
