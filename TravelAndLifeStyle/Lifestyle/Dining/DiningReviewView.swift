//
//  DiningReviewView.swift
//  Lifestyle · Day 3 · Review and reserve, then the confirmation
//
//  The terms box must be checked before Reserve works. Reserving shows each
//  step and has nothing to tap twice. Points come off only after the table is
//  confirmed.
//

import SwiftUI

// MARK: - Step 4 · Review

struct DiningReviewView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showsTerms = false

    var body: some View {
        let model = store.dining
        let isBusy = model.isReserving

        Group {
            if horizontalSizeClass == .regular {
                // Review details beside the money, the terms and Reserve.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        Group {
                            StepHeader.dining(step: 4, title: "Review and reserve")
                            DiningReviewDetailsCard(model: model)
                        }
                        .dimmedWhileReserving(isBusy)
                    }
                } trailing: {
                    FlowPane {
                        Group {
                            DiningMoneyCard(model: model)
                            TermsCard(model: model) { showsTerms = true }
                        }
                        .dimmedWhileReserving(isBusy)
                    } footer: {
                        DiningReviewFooter(model: model)
                    }
                }
            } else {
                FlowPage {
                    Group {
                        StepHeader.dining(step: 4, title: "Review and reserve")
                        DiningReviewDetailsCard(model: model)
                        DiningMoneyCard(model: model)
                        TermsCard(model: model) { showsTerms = true }
                    }
                    .dimmedWhileReserving(isBusy)
                } bar: {
                    DiningReviewFooter(model: model)
                }
            }
        }
        .flowChrome(title: "Review and reserve")
        .onAppear { model.prepareReview() }
        .animation(Theme.Motion.select, value: model.reserve)
        .animation(Theme.Motion.select, value: model.termsAccepted)
        // The time filled up: nothing was charged, and the times show it sold out.
        .onChange(of: model.soldOutNotice) { _, notice in
            if notice != nil { store.pop(to: .diningTable) }
        }
        // The service found an overlapping table: back to the details, where the banner says so.
        .onChange(of: model.overlap) { _, overlap in
            if overlap != nil { store.pop(to: .diningDetails) }
        }
        .onChange(of: model.reserve) { _, state in
            announce(state, model: model)
        }
        .sheet(isPresented: $showsTerms) {
            TermsSheet(model: model)
        }
    }

    /// Reserving announces each step; the failed panel is announced.
    private func announce(_ state: DiningFlowModel.ReserveState, model: DiningFlowModel) {
        switch state {
        case .inProgress(let step?):
            if let label = model.reserveSteps.first(where: { $0.step == step })?.label {
                AccessibilityNotification.Announcement("In progress: \(label)").post()
            }
        case .paymentFailed:
            AccessibilityNotification.Announcement("Payment didn’t go through. No points were deducted and no table was reserved.").post()
        default:
            break
        }
    }
}

private extension View {
    /// The page steps back while the reservation is in flight.
    func dimmedWhileReserving(_ isBusy: Bool) -> some View {
        self
            .opacity(isBusy ? 0.45 : 1)
            .allowsHitTesting(!isBusy)
            .accessibilityHidden(isBusy)
    }
}

/// Reserve bar, the in-progress panel, or the payment-failed panel.
private struct DiningReviewFooter: View {
    @Environment(LifestyleStore.self) private var store
    let model: DiningFlowModel

    var body: some View {
        switch model.reserve {
        case .idle, .done:
            ActionBar(buttonTitle: "Reserve", isEnabled: model.canReserve,
                      disabledReason: "Agree to the terms to reserve",
                      action: { Task { await model.reserveTable() } }) {
                Text(model.chargeText)
                    .textStyle(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if model.termsAccepted {
                    Text("Points come off after it’s confirmed")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                        .lineLimit(1)
                } else {
                    Text("Agree to the terms to reserve")
                        .textStyle(.footnote, color: Theme.Colors.red)
                        .lineLimit(1)
                }
            }
        case .inProgress(let step):
            ReservingPanel(model: model, step: step)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .paymentFailed:
            PaymentFailedPanel(
                message: "\(model.card.maskedText) was declined. No points were deducted and no table was reserved.",
                onChangeCard: {
                    model.dismissPaymentFailure()
                    store.pop(to: .diningDeposit)
                },
                onRetry: { Task { await model.reserveTable() } })
                .transition(.opacity)
        case .failed:
            PaymentFailedPanel(
                title: "We couldn’t reserve your table",
                message: "Nothing was charged and no points were deducted. Trying again sends the same request.",
                onChangeCard: nil,
                onRetry: { Task { await model.reserveTable() } })
                .transition(.opacity)
        }
    }
}

// MARK: - Review cards

/// Restaurant, date and time, party, needs, requests and the guest.
private struct DiningReviewDetailsCard: View {
    let model: DiningFlowModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Thumbnail(name: model.restaurant.heroImage)
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.restaurant.name)
                        .textStyle(.headline)
                    Text(model.restaurant.shortAddress)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 68)
            .accessibilityElement(children: .combine)

            DetailRow(label: "Date and time",
                      value: "\(model.setup.dayWithYearText) · \(model.selectedTimeText ?? "")",
                      detail: "Houston time (CT)") {
                SymbolIcon(name: "calendar", size: 16)
            }
            DetailRow(label: "Party size", value: model.guestsText) {
                SymbolIcon(name: "person.2", size: 14)
            }
            DetailRow(label: "Accessibility needs",
                      value: model.accessibilityList.isEmpty ? "None" : model.accessibilityList.joined(separator: ", ")) {
                SymbolIcon(name: "figure.roll", size: 15)
            }
            DetailRow(label: "Requests and dietary notes", value: model.requestLines.first ?? "None",
                      detail: model.requestLines.dropFirst().first) {
                SymbolIcon(name: "note.text", size: 15)
            }
            DetailRow(label: "Guest", value: model.name, detail: "\(model.phone) · \(model.email)") {
                SymbolIcon(name: "person", size: 15)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

/// The deposit and how it is being paid.
private struct DiningMoneyCard: View {
    let model: DiningFlowModel

    var body: some View {
        if let tender = model.tender {
            VStack(alignment: .leading, spacing: 8) {
                PriceRow(label: model.depositLabel, value: model.deposit.usd, isTotal: true)
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

/// The policy, and the box that must be checked before Reserve works.
private struct TermsCard: View {
    @Bindable var model: DiningFlowModel
    var onReadTerms: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    SymbolIcon(name: "shield", size: 15)
                        .foregroundStyle(Theme.Colors.green)
                    Text("Cancellation policy")
                        .textStyle(.subheadEmphasis)
                }
                Text(model.policyText)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
            }
            .accessibilityElement(children: .combine)

            Hairline()

            // A real toggle: VoiceOver reads it as a checkbox-style switch.
            Toggle(isOn: $model.termsAccepted) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("I agree to the deposit terms and cancellation policy")
                        .textStyle(.subheadEmphasis)
                    Text("Required to confirm")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
            }
            .toggleStyle(CheckboxToggleStyle())

            Button(action: onReadTerms) {
                HStack(spacing: 4) {
                    Text("Read the full terms")
                        .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                    SymbolIcon(name: "arrow.up.right.square", size: 12, weight: .semibold)
                        .foregroundStyle(Theme.Colors.purple)
                }
                .frame(minHeight: Theme.Size.touch)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, -8)
            .padding(.bottom, -6)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

/// A 24pt box that fills purple with a check.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isOn ? Theme.Colors.purple2 : Theme.Colors.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(configuration.isOn ? Theme.Colors.purple2 : Theme.Colors.checkboxBorder, lineWidth: 2)
                    }
                    .overlay {
                        if configuration.isOn {
                            Glyph(shape: CheckShape(), size: 16, lineWidth: 3)
                                .foregroundStyle(Theme.Colors.white)
                                .transition(.scale(scale: 0.4).combined(with: .opacity))
                        }
                    }
                    .frame(width: 24, height: 24)
                    .padding(.top, 1)
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(Theme.Motion.select, value: configuration.isOn)
        .accessibilityAddTraits(configuration.isOn ? [.isSelected] : [])
        .accessibilityValue(configuration.isOn ? "Checked" : "Not checked")
    }
}

/// "Read the full terms": the deposit terms and the cancellation policy.
private struct TermsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let model: DiningFlowModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    section("Deposit",
                            "\(model.restaurant.name) takes a deposit of \(model.setup.depositPerPerson.usd) per guest when you reserve. You can pay it with rewards points, a card, or both. 100 points = $1.")
                    section("When you're charged",
                            "Your card is charged when you tap Reserve. Points come off your balance only after the reservation is confirmed. If the payment fails or the table is no longer open, nothing is charged and no points are used.")
                    section("Cancellation policy", model.policyText)
                    InfoNote(text: "Shown for your information; cancellations aren’t available in the app yet.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background { AmbientBackground() }
            .navigationTitle("Deposit terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textStyle(.bodyEmphasis)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .textStyle(.subhead, color: Theme.Colors.ink2)
        }
    }
}

// MARK: - Reserving

/// The steps check off as the reservation goes through, over a disabled button.
private struct ReservingPanel: View {
    let model: DiningFlowModel
    /// The step in progress; nil while availability is rechecked.
    let step: ReserveStep?

    var body: some View {
        let steps = model.reserveSteps
        let active = steps.firstIndex { $0.step == step } ?? 0

        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Reserving your table")
                    .textStyle(.headline)
                Text("This takes a few seconds. Please keep this screen open.")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .padding(.bottom, 4)
            .accessibilityElement(children: .combine)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                BookingStepRow(label: item.label,
                               state: index < active ? .done : (index == active ? .active : .waiting))
            }

            // The Reserve control is gone: there is nothing to tap twice.
            Button("Reserving…") {}
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
}

/// Nothing was reserved and no points were deducted.
private struct PaymentFailedPanel: View {
    var title = "Payment didn’t go through"
    let message: String
    var onChangeCard: (() -> Void)?
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                IconCircle(size: 40, fill: Theme.Colors.dangerIcon, foreground: Theme.Colors.red) {
                    SymbolIcon(name: "exclamationmark.circle", size: 18)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .textStyle(.headline)
                    Text(message)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 8) {
                if let onChangeCard {
                    Button(action: onChangeCard) {
                        Text("Change card")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButtonStyle(horizontalPadding: 12))
                }
                Button("Try again", action: onRetry)
                    .buttonStyle(FilledButtonStyle(kind: .red, compact: true))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frostSurface(radius: 24)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.Colors.dangerBorder, lineWidth: Theme.Size.border)
        }
    }
}

// MARK: - Reserved

/// The reservation ID, when, party and status, the updated rewards balance, and
/// the dinner in the trip's itinerary.
struct DiningConfirmationView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let reservation = store.dining.confirmedReservation ?? store.bookings.reservations.last

        Group {
            if let reservation, let trip = store.bookings.trip(containing: reservation.id) {
                let itinerary = store.bookings.itinerary(for: trip)
                if horizontalSizeClass == .regular {
                    // The confirmation beside the trip itinerary, with the dinner added.
                    FlowSplit {
                        FlowPane(spacing: 12) {
                            ReservedSummary(reservation: reservation, balance: store.rewardsBalance)
                        }
                    } trailing: {
                        FlowPane(spacing: 8) {
                            TripItinerarySection(itinerary: itinerary)
                        }
                    }
                } else {
                    FlowPage {
                        ReservedSummary(reservation: reservation, balance: store.rewardsBalance)
                        AddedToTripSection(itinerary: itinerary, bookingId: reservation.id)
                    }
                }
            } else {
                ContentUnavailableView("No reservation yet", systemImage: "fork.knife")
            }
        }
        .flowChrome(title: "Your table is reserved")
    }
}

/// The check, "Your table is reserved", the reservation details and the rewards balance.
private struct ReservedSummary: View {
    let reservation: DiningReservation
    let balance: Int

    var body: some View {
        StepHeader.dining(step: 5)

        VStack(alignment: .leading, spacing: 8) {
            ConfirmationCheck()
            Text("Your table is reserved")
                .textStyle(.largeTitle)
                .accessibilityAddTraits(.isHeader)
            Text("\(reservation.restaurantName) · \(when)")
                .textStyle(.subhead, color: Theme.Colors.ink2)
        }
        .riseIn()

        VStack(alignment: .leading, spacing: 0) {
            row("Reservation ID") {
                Text(reservation.reservationId)
                    .textStyle(.code)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
                CopyButton(text: reservation.reservationId, name: "reservation ID")
            }
            .frame(minHeight: 52)
            Hairline()
            row("When") {
                Text(when)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Theme.Size.touch)
            Hairline()
            row("Party") {
                Text(reservation.guestsText)
                    .textStyle(.subheadEmphasis)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Theme.Size.touch)
            Hairline()
            row("Status") {
                Spacer(minLength: 0)
                TagPill(text: reservation.status, tone: .mint, symbol: "checkmark")
            }
            .frame(minHeight: Theme.Size.touch)
            Hairline()
            Text("Show this ID when you arrive.")
                .textStyle(.footnote, color: Theme.Colors.muted)
                .padding(.top, 4)
                .padding(.bottom, 10)
        }
        .padding(.top, 4)
        .padding(.horizontal, 14)
        .cardSurface()

        RewardsBalanceCard(balance: balance, used: reservation.pointsUsed)
    }

    /// "Fri, Jan 1 · 8:00 PM"
    private var when: String { "\(TripCalendar.day(reservation.date)) · \(reservation.timeText)" }

    private func row(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(width: 110, alignment: .leading)
            value()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Review · compact") {
    let store = LifestyleStore.preview(seed: .hotelOnly)
    store.open(.restaurant)
    store.path += [.diningTable, .diningDetails, .diningDeposit, .diningReview]
    return LifestyleRootView(store: store)
        .task {
            await store.dining.loadSlots()
            store.dining.fillSample()
        }
}
