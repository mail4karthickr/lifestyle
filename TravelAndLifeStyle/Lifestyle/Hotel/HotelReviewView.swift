//
//  HotelReviewView.swift
//  Lifestyle · Step 4 · confirm, then booking in progress
//
//  Booking needs an explicit tap on "Confirm and book". The request carries an
//  idempotency key made when this screen opens. The in-progress panel replaces
//  the button at once, so repeat taps can't book twice, and a retry after a
//  failure reuses the same key.
//

import SwiftUI

struct HotelReviewView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let model = store.hotel
        let isBusy = model.isBooking

        Group {
            if horizontalSizeClass == .regular {
                // Review details beside the money, tender and Confirm.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        Group {
                            StepHeader(step: 4, title: "Review and book")
                            ReviewDetailsCard(model: model)
                        }
                        .dimmedWhileBooking(isBusy)
                    }
                } trailing: {
                    FlowPane {
                        ReviewMoneyCard(model: model)
                        InfoNote(text: "Nothing is charged until you confirm.", symbol: "lock")
                    } footer: {
                        ReviewFooter(model: model)
                    }
                }
            } else {
                FlowPage {
                    Group {
                        StepHeader(step: 4, title: "Review and book")
                        ReviewDetailsCard(model: model)
                        ReviewMoneyCard(model: model)
                        InfoNote(text: "Nothing is charged until you confirm. Booking can’t be changed in the app after it’s confirmed.",
                                 symbol: "lock")
                    }
                    .dimmedWhileBooking(isBusy)
                } bar: {
                    ReviewFooter(model: model)
                }
            }
        }
        .flowChrome(title: "Review and book")
        .onAppear { model.prepareReview() }
        .animation(Theme.Motion.select, value: model.booking)
    }
}

private extension View {
    /// The page steps back while the booking is in flight.
    func dimmedWhileBooking(_ isBusy: Bool) -> some View {
        self
            .opacity(isBusy ? 0.45 : 1)
            .allowsHitTesting(!isBusy)
            .accessibilityHidden(isBusy)
    }
}

/// Confirm bar, the in-progress panel, or the retry panel.
private struct ReviewFooter: View {
    let model: HotelFlowModel

    var body: some View {
        switch model.booking {
        case .idle, .done:
            ActionBar(buttonTitle: "Confirm and book", isEnabled: model.tender != nil,
                      action: { Task { await model.confirmAndBook() } }) {
                Text(model.chargeText)
                    .textStyle(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Charged when you confirm")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
        case .inProgress(let step):
            BookingProgressPanel(model: model, step: step)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .failed:
            BookingFailedPanel { Task { await model.confirmAndBook() } }
                .transition(.opacity)
        }
    }
}

// MARK: - Review cards

/// Hotel, dates, room, guests and cancellation.
struct ReviewDetailsCard: View {
    let model: HotelFlowModel

    var body: some View {
        VStack(spacing: 0) {
            if let hotel = model.selectedHotel {
                HStack(spacing: 12) {
                    Thumbnail(name: hotel.imageName)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(hotel.name)
                            .textStyle(.headline)
                        Text(model.details.value?.shortAddress ?? hotel.neighborhood)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 68)
                .accessibilityElement(children: .combine)
            }

            DetailRow(label: "Dates", value: model.search.datesText, detail: datesDetail) {
                SymbolIcon(name: "calendar", size: 16)
            }
            DetailRow(label: "Room", value: model.selectionText) {
                SymbolIcon(name: "bed.double", size: 15)
            }
            DetailRow(label: "Guests", value: "\(model.search.adultsText) · \(model.search.roomsText)") {
                SymbolIcon(name: "person.2", size: 14)
            }
            DetailRow(label: "Cancellation", value: model.selectedRate?.policySummary ?? "") {
                SymbolIcon(name: "shield", size: 16)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .cardSurface()
    }

    /// "3 nights · check-in from 3:00 PM"
    private var datesDetail: String {
        guard let checkIn = model.details.value?.checkInFrom else { return model.search.nightsText }
        return "\(model.search.nightsText) · check-in from \(TripCalendar.clock(checkIn))"
    }
}

/// Price breakdown and how it is being paid.
struct ReviewMoneyCard: View {
    let model: HotelFlowModel

    var body: some View {
        if let price = model.price, let tender = model.tender {
            VStack(alignment: .leading, spacing: 8) {
                PriceBreakdown(price: price)
                Text("Paying with")
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                    .padding(.top, 4)
                if tender.points > 0 {
                    tenderLine("\(tender.points.grouped) points", amount: tender.pointsValue) {
                        PointsCoin(size: 24, starSize: 12)
                    }
                }
                if tender.cardAmount > 0 {
                    tenderLine(model.card.maskedText, amount: tender.cardAmount) {
                        CardSwatch(width: 34, height: 22)
                    }
                }
            }
            .padding(14)
            .cardSurface()
        }
    }

    private func tenderLine(_ label: String, amount: Decimal, @ViewBuilder icon: () -> some View) -> some View {
        HStack(spacing: 8) {
            icon()
            Text(label)
                .textStyle(.subhead)
            Spacer(minLength: 0)
            Text(amount.usd)
                .textStyle(.subheadEmphasis)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Booking in progress

/// Three steps that check off as the booking goes through, and a disabled button.
struct BookingProgressPanel: View {
    let model: HotelFlowModel
    /// The step in progress, 1…3.
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Booking your stay")
                    .textStyle(.headline)
                Text("This takes a few seconds. Please keep this screen open.")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .padding(.bottom, 4)
            .accessibilityElement(children: .combine)

            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                BookingStepRow(label: label, state: index + 1 < step ? .done : (index + 1 == step ? .active : .waiting))
            }

            // The confirm control is gone: there is nothing to tap twice.
            Button("Booking…") {}
                .buttonStyle(FilledButtonStyle(kind: .red))
                .disabled(true)
                .padding(.top, 6)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frostSurface(radius: 24)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var labels: [String] {
        let payment: String
        if let tender = model.tender, tender.points > 0 {
            payment = "\(tender.points.grouped) points applied"
        } else {
            payment = "\(model.card.maskedText) authorized"
        }
        return ["Price and room confirmed", payment, "Confirming with \(model.selectedHotel?.name ?? "the hotel")"]
    }
}

struct BookingStepRow: View {
    enum State { case done, active, waiting }

    let label: String
    let state: State
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                switch state {
                case .done:
                    SymbolIcon(name: "checkmark", size: 10, weight: .heavy)
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 24, height: 24)
                        .background(Theme.Colors.green, in: Circle())
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.7).combined(with: .opacity))
                case .active:
                    ProgressRing(size: 24)
                case .waiting:
                    Circle()
                        .strokeBorder(Theme.Colors.waitRing, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .animation(.spring(duration: 0.5, bounce: 0.4), value: state)

            Text(label)
                .textStyle(state == .active ? .subheadEmphasis : .subhead,
                           color: state == .waiting ? Theme.Colors.muted : Theme.Colors.ink)
        }
        .frame(minHeight: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(state == .done ? "Done" : (state == .active ? "In progress" : "Waiting"))
    }
}

/// The booking didn't confirm. Trying again reuses the same request.
private struct BookingFailedPanel: View {
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                IconCircle(fill: Theme.Colors.dangerIcon, foreground: Theme.Colors.red) {
                    SymbolIcon(name: "info.circle", size: 17)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("We couldn't confirm your booking")
                        .textStyle(.headline)
                    Text("Trying again sends the same request, so you won't be booked or charged twice.")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            Button("Try again", action: onRetry)
                .buttonStyle(FilledButtonStyle(kind: .red))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frostSurface(radius: 24)
    }
}

#Preview("Review · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    store.path += [.hotelRooms, .hotelCheckout, .hotelReview]
    return LifestyleRootView(store: store)
        .task {
            await store.hotel.loadResults()
            await store.hotel.loadDetails()
            await store.hotel.loadRooms()
            await store.hotel.repriceIfNeeded()
        }
}
