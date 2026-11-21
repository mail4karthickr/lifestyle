//
//  HotelCheckoutView.swift
//  Lifestyle · Step 3 · accept any change; how to pay
//
//  Reprices and rechecks availability on entry. A change has to be accepted
//  before Continue is enabled. Tender is card, points, or points + card at
//  100 points = $1; the card covers what the points don't.
//

import SwiftUI

struct HotelCheckoutView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isAddingCard = false
    /// The panes are one above the other (tabletop).
    @State private var isStacked = false

    /// "Hotel Solenne · Deluxe King", shown in the bar when the panes are stacked.
    private var stackedSubtitle: String? {
        guard horizontalSizeClass == .regular, isStacked else { return nil }
        return [store.hotel.selectedHotel?.name, store.hotel.selectedRoom?.name]
            .compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        let model = store.hotel

        Group {
            if horizontalSizeClass == .regular {
                GeometryReader { proxy in
                    // Side by side: payment controls beside the live order summary.
                    // Stacked (tabletop): price check and totals on the upright half,
                    // tender controls and Continue on the flat half.
                    let isStacked = proxy.size.height > proxy.size.width
                    FlowSplit {
                        FlowPane(spacing: 12) {
                            if isStacked {
                                RepriceCard(model: model)
                                if model.price != nil { TotalsCard(model: model) }
                            } else {
                                StepHeader(step: 3, title: "Checkout")
                                RepriceCard(model: model)
                                if model.price != nil {
                                    PayControls(model: model, isAddingCard: $isAddingCard)
                                }
                            }
                        }
                    } trailing: {
                        if isStacked {
                            FlowPane(spacing: 12) {
                                if model.price != nil {
                                    PayControls(model: model, isAddingCard: $isAddingCard, showsCards: false)
                                }
                            } footer: {
                                CheckoutBar(model: model) { store.advance(to: .hotelReview) }
                            }
                        } else {
                            FlowPane {
                                OrderSummaryPanel(model: model) { store.advance(to: .hotelReview) }
                            }
                        }
                    }
                    .onChange(of: isStacked, initial: true) { _, stacked in
                        self.isStacked = stacked
                    }
                }
            } else {
                FlowPage {
                    StepHeader(step: 3, title: "Checkout")
                    if let hotel = model.selectedHotel {
                        StaySummaryRow(imageName: hotel.imageName, title: hotel.name,
                                       line1: model.selectionText, line2: model.search.datesText)
                    }
                    RepriceCard(model: model)
                    if model.price != nil {
                        PayControls(model: model, isAddingCard: $isAddingCard)
                        CheckoutBreakdown(model: model)
                            .padding(14)
                            .cardSurface()
                    }
                } bar: {
                    CheckoutBar(model: model) { store.advance(to: .hotelReview) }
                }
            }
        }
        .flowChrome(title: "Checkout", barSubtitle: stackedSubtitle)
        .task(id: model.selectedRateId) {
            async let results: Void = model.loadResults()
            async let reprice: Void = model.repriceIfNeeded()
            _ = await (results, reprice)
        }
        .sheet(isPresented: $isAddingCard) {
            AnotherCardSheet { card in
                model.otherCard = card
                model.card = card
            }
        }
    }
}

/// "$795.05 / on card + 10,000 pts" and Continue.
private struct CheckoutBar: View {
    let model: HotelFlowModel
    var onContinue: () -> Void

    var body: some View {
        let summary = model.tenderSummary
        ActionBar(buttonTitle: "Continue", isEnabled: model.canContinueToReview,
                  disabledReason: model.continueBlocker, action: onContinue) {
            if model.price != nil {
                Text(summary.title)
                    .textStyle(.headline)
                    .contentTransition(.numericText())
                Text(summary.subtitle)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            } else {
                Text(model.continueBlocker ?? "")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
        }
        .lineLimit(1)
        .animation(Theme.Motion.select, value: model.points)
    }
}

// MARK: - Reprice

/// Checking, price changed, no change, or room unavailable.
struct RepriceCard: View {
    @Environment(LifestyleStore.self) private var store
    @Bindable var model: HotelFlowModel

    var body: some View {
        switch model.reprice {
        case .idle, .checking:
            HStack(spacing: 12) {
                ProgressRing(size: 28)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Checking the latest price")
                        .textStyle(.bodyEmphasis)
                    Text("Rechecking availability with the hotel…")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .cardSurface()
            .accessibilityElement(children: .combine)

        case .failed:
            SectionErrorCard(title: "Couldn't check the price", message: "Nothing has been charged.") {
                Task { await model.repriceIfNeeded(force: true) }
            }

        case .result(.unchanged):
            HStack(spacing: 10) {
                SymbolIcon(name: "checkmark", size: 10, weight: .heavy)
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 24, height: 24)
                    .background(Theme.Colors.green, in: Circle())
                Text("Price and availability confirmed just now")
                    .textStyle(.subheadEmphasis, color: Theme.Colors.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .tintedCard(fill: Theme.Colors.successFill, border: Theme.Colors.successBorder, radius: 18)
            .accessibilityElement(children: .combine)

        case .result(.changed(let old, let new, let changes)):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    IconCircle(fill: Theme.Colors.noticeIcon, foreground: Theme.Colors.amber) {
                        SymbolIcon(name: "arrow.triangle.2.circlepath", size: 15, weight: .semibold)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(changes.contains(.price) ? "The price changed" : "Your booking changed")
                            .textStyle(.bodyEmphasis)
                        Text("New total \(new.total.usd) (was \(old.total.usd))")
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)

                VStack(alignment: .leading, spacing: 0) {
                    changeRow("Nightly rate") {
                        if changes.contains(.price) {
                            Text(old.nightly.usd)
                                .textStyle(.footnote, color: Theme.Colors.muted)
                                .strikethrough()
                                .accessibilityLabel("was \(old.nightly.usd)")
                            Text(new.nightly.usd)
                                .textStyle(.footnoteEmphasis)
                        } else {
                            unchanged("No change")
                        }
                    }
                    changeRow("Room") {
                        if changes.contains(.room) {
                            Text("Changed").textStyle(.footnoteEmphasis)
                        } else {
                            unchanged("\(model.selectedRoom?.name ?? "Room"), no change")
                        }
                    }
                    changeRow("Cancellation") {
                        if changes.contains(.cancellationTerms) {
                            Text("Changed").textStyle(.footnoteEmphasis)
                        } else {
                            unchanged("No change")
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
                .padding(.leading, 48)

                // Any change has to be accepted before Continue is enabled.
                Button {
                    withAnimation(Theme.Motion.select) { model.acceptedChange.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(model.acceptedChange ? Theme.Colors.purple2 : Theme.Colors.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(model.acceptedChange ? Theme.Colors.purple2 : Theme.Colors.radioIdle,
                                                  lineWidth: 2)
                            }
                            .overlay {
                                SymbolIcon(name: "checkmark", size: 12, weight: .heavy)
                                    .foregroundStyle(Theme.Colors.white)
                                    .opacity(model.acceptedChange ? 1 : 0)
                            }
                            .frame(width: 24, height: 24)
                        Text("I accept the new total")
                            .textStyle(.subheadEmphasis)
                    }
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 48)
                .accessibilityAddTraits(model.acceptedChange ? [.isSelected] : [])
                .accessibilityHint("Required to continue")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tintedCard(fill: Theme.Colors.noticeFill, border: Theme.Colors.noticeBorder, radius: 20)

        case .result(.unavailable):
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    IconCircle(fill: Theme.Colors.dangerIcon, foreground: Theme.Colors.red) {
                        SymbolIcon(name: "info.circle", size: 17)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("This room is no longer available")
                            .textStyle(.bodyEmphasis)
                        Text("\(model.selectionText) sold out while you were choosing.")
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                // Back to room selection, with everything else kept.
                Button("Choose another room") { store.back() }
                    .buttonStyle(OutlineButtonStyle(horizontalPadding: 22))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tintedCard(fill: Theme.Colors.dangerFill, border: Theme.Colors.dangerBorder, radius: 20)
        }
    }

    private func changeRow(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(width: 92, alignment: .leading)
            HStack(spacing: 6) { value() }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 24)
        .accessibilityElement(children: .combine)
    }

    private func unchanged(_ text: String) -> some View {
        HStack(spacing: 4) {
            SymbolIcon(name: "checkmark", size: 10, weight: .bold)
                .foregroundStyle(Theme.Colors.green)
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.ink2)
                .lineLimit(1)
        }
    }
}

extension View {
    /// A tinted notice card: amber for a change, mint for confirmed, red for unavailable.
    func tintedCard(fill: Color, border: Color, radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background {
                shape.fill(fill)
                    .shadow(color: Theme.Colors.cardShadow, radius: 7, x: 0, y: 4)
            }
            .overlay { shape.strokeBorder(border, lineWidth: Theme.Size.border) }
    }
}

// MARK: - Pay controls

/// Card / Points / Points + card, the points control, the split and the card.
struct PayControls<Model: PaymentChoosing>: View {
    @Bindable var model: Model
    @Binding var isAddingCard: Bool
    var showsCards = true

    var body: some View {
        Text("Pay with")
            .textStyle(.bodyEmphasis)
            .accessibilityAddTraits(.isHeader)

        SegmentedControl(
            options: TenderMode.allCases.map {
                .init(value: $0, label: $0.label, isEnabled: model.isAvailable($0),
                      disabledReason: model.pointsOnlyNote)
            },
            selection: model.tenderMode) { model.choose($0) }

        // Why Points only is unavailable; VoiceOver reads it with the control.
        if let note = model.pointsOnlyNote {
            InfoNote(text: note)
        }

        pointsCard

        if showsCards {
            splitTiles
            cardPicker
        }
    }

    private var pointsCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("Points to use")
                    .textStyle(.subhead, color: Theme.Colors.muted)
                Spacer(minLength: 0)
                PointsCoin(size: 20, starSize: 10)
                Text("\(model.balance.pointsText) available")
                    .textStyle(.footnote, color: Theme.Colors.ink2)
            }

            HStack(spacing: 8) {
                RoundIconButton(symbol: "minus", label: "Use 1,000 fewer points", isEnabled: model.points > 0) {
                    withAnimation(Theme.Motion.select) { model.changePoints(by: -1000) }
                }
                VStack(spacing: 0) {
                    Text(model.points.pointsText)
                        .textStyle(.title2)
                        .contentTransition(.numericText())
                    Text("= \(Decimal(cents: model.points).usd)")
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                RoundIconButton(symbol: "plus", label: "Use 1,000 more points",
                                isEnabled: model.points < model.maxPoints) {
                    withAnimation(Theme.Motion.select) { model.changePoints(by: 1000) }
                }
            }

            Slider(value: Binding(get: { Double(model.points) }, set: { model.setPoints(Int($0)) }),
                   in: 0...Double(max(model.maxPoints, 1)))
                .tint(Theme.Colors.purple2)
                .frame(minHeight: 32)
                .disabled(model.maxPoints == 0)
                .accessibilityLabel("Points to use")
                .accessibilityValue("\(model.points.pointsText), worth \(Decimal(cents: model.points).usd)")

            HStack(spacing: 8) {
                Text("100 points = $1")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Spacer(minLength: 0)
                Text("\(model.pointsLeft.pointsText) left after booking")
                    .textStyle(.footnote, color: Theme.Colors.ink2)
            }
        }
        .padding(14)
        .cardSurface()
    }

    private var splitTiles: some View {
        HStack(spacing: 8) {
            splitTile(label: "Points", amount: Decimal(cents: model.points)) {
                PointsCoin(size: 34, starSize: 16)
            }
            splitTile(label: model.card.maskedText, amount: model.tender?.cardAmount ?? 0) {
                IconCircle(size: 34) { SymbolIcon(name: "creditcard", size: 14) }
            }
        }
    }

    private func splitTile(label: String, amount: Decimal, @ViewBuilder icon: () -> some View) -> some View {
        HStack(spacing: 10) {
            icon()
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
                Text(amount.usd)
                    .textStyle(.headline)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .cardSurface(radius: 16)
        .accessibilityElement(children: .combine)
    }

    /// Card entry is simulated: the saved card, or one from the simulated form.
    private var cardPicker: some View {
        let cards = [model.savedCard] + (model.otherCard.map { [$0] } ?? [])
        return VStack(spacing: 0) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                Button {
                    withAnimation(Theme.Motion.select) { model.card = card }
                } label: {
                    HStack(spacing: 12) {
                        RadioMark(isOn: model.card == card)
                        CardSwatch(width: 44, height: 28)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(card.label)
                                .textStyle(.subheadEmphasis)
                            Text("···· \(card.last4) · \(cardRole)")
                                .textStyle(.footnote, color: Theme.Colors.muted)
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 60)
                    .overlay(alignment: .top) { if index > 0 { Hairline() } }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(model.card == card ? [.isSelected] : [])
            }

            Button {
                isAddingCard = true
            } label: {
                HStack(spacing: 12) {
                    IconCircle(size: 30, fill: Theme.Colors.ink2.opacity(0.07), foreground: Theme.Colors.ink2) {
                        SymbolIcon(name: "plus", size: 13, weight: .semibold)
                    }
                    Text("Use another card")
                        .textStyle(.subheadEmphasis, color: Theme.Colors.purple)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 4)
                .frame(minHeight: 52)
                .overlay(alignment: .top) { Hairline() }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .cardSurface(radius: 18)
    }

    private var cardRole: String {
        guard let tender = model.tender else { return "" }
        if tender.cardAmount == 0 { return "not charged" }
        return tender.points > 0 ? "pays what points don’t" : "pays the total"
    }
}

/// The retail card's colours, as a small swatch.
struct CardSwatch: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(LinearGradient(colors: Theme.Colors.cardArt, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

// MARK: - Totals

/// Nightly line, taxes and fees, total, points applied and what's due on the card.
struct CheckoutBreakdown: View {
    let model: HotelFlowModel
    var showsNightly = true

    var body: some View {
        if let price = model.price, let tender = model.tender {
            VStack(spacing: 8) {
                if showsNightly {
                    PriceBreakdown(price: price)
                }
                PriceRow(label: "Points applied (\(tender.points.pointsText))",
                         value: tender.points > 0 ? "−\(tender.pointsValue.usd)" : Decimal(0).usd,
                         valueColor: Theme.Colors.green)
                PriceRow(label: "Due on card", value: tender.cardAmount.usd, isTotal: true)
            }
        }
    }
}

/// How the total divides between points and card.
struct SplitBar: View {
    let pointsShare: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.yellow)
                    .frame(width: geo.size.width * min(max(pointsShare, 0), 1))
                Rectangle()
                    .fill(Theme.Colors.purple2)
            }
        }
        .frame(height: 10)
        .background(Theme.Colors.splitTrack)
        .clipShape(Capsule())
        .animation(Theme.Motion.select, value: pointsShare)
        .accessibilityHidden(true)
    }
}

/// Tabletop: total, split bar, points applied and due on card.
private struct TotalsCard: View {
    let model: HotelFlowModel

    var body: some View {
        if let price = model.price {
            VStack(spacing: 8) {
                PriceRow(label: "Total", value: price.total.usd, isTotal: true)
                SplitBar(pointsShare: model.pointsShare)
                CheckoutBreakdown(model: model, showsNightly: false)
            }
            .padding(14)
            .cardSurface()
        }
    }
}

/// Regular width: hotel, breakdown, the points and card split, and Continue.
private struct OrderSummaryPanel: View {
    let model: HotelFlowModel
    var onContinue: () -> Void

    var body: some View {
        SummaryPanel(spacing: 8) {
            Text("Order summary")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)

            if let hotel = model.selectedHotel {
                StaySummaryRow(imageName: hotel.imageName, title: hotel.name,
                               line1: model.selectionText, line2: model.search.datesText)
                    .padding(.bottom, 6)
            }

            if let price = model.price {
                PriceBreakdown(price: price)
                SplitBar(pointsShare: model.pointsShare)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                HStack(spacing: 6) {
                    legend("Points", color: Theme.Colors.yellow)
                    Spacer(minLength: 0)
                    legend("Card", color: Theme.Colors.purple2)
                }
                CheckoutBreakdown(model: model, showsNightly: false)
            } else if let listed = model.listedPrice {
                // Until reprice answers, the listed price.
                PriceBreakdown(price: listed)
                    .opacity(0.5)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(FilledButtonStyle(kind: .red))
                .disabled(!model.canContinueToReview)
                .accessibilityHint(model.continueBlocker ?? "")
                .padding(.top, 8)
        }
    }

    private func legend(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.ink2)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Another card (simulated)

/// A simulated card form. Nothing is validated with a network or charged.
struct AnotherCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onUse: (PaymentCard) -> Void
    @State private var name = ""
    @State private var number = ""
    @State private var expiry = ""
    @State private var code = ""

    private var digits: String { number.filter(\.isNumber) }
    private var isValid: Bool { digits.count >= 12 && !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name on card", text: $name)
                        .textContentType(.name)
                    TextField("Card number", text: $number)
                        .keyboardType(.numberPad)
                    TextField("Expiry (MM/YY)", text: $expiry)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Security code", text: $code)
                        .keyboardType(.numberPad)
                } footer: {
                    Text("Card entry is simulated in this version. No card is charged.")
                }
            }
            .navigationTitle("Use another card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use card") {
                        let card = PaymentCard(label: "Card ending \(digits.suffix(4))",
                                               last4: String(digits.suffix(4)), isSaved: false)
                        onUse(card)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Checkout · compact") {
    let store = LifestyleStore.preview()
    store.open(.hotelDetails(hotelId: HotelSampleData.sample.hotelDetails.hotelId))
    store.advance(to: .hotelRooms)
    store.advance(to: .hotelCheckout)
    return LifestyleRootView(store: store)
        .task { await store.hotel.loadRooms() }
}
