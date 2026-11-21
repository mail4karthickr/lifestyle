//
//  DiningComponents.swift
//  Lifestyle · Day 3 · pieces of the reserve-a-table flow (Day 3 spec, section 3)
//

import SwiftUI

// MARK: - Restaurant

/// The dining room, with frost tags for the date and the menu.
struct RestaurantHero: View {
    let restaurant: Restaurant
    let setup: DiningSetup
    var height: CGFloat
    var tagLeading: CGFloat = 16
    var showsTags = true

    var body: some View {
        Color.clear
            .frame(height: height)
            .overlay {
                Image(restaurant.heroImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [Theme.Colors.heroFade.opacity(0), Theme.Colors.heroFade],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 90)
                    .accessibilityHidden(true)
            }
            .clipped()
            .overlay(alignment: .bottomLeading) {
                if showsTags {
                    HStack(spacing: 6) {
                        ImageTag(symbol: "calendar", text: "\(setup.dayText) · \(restaurant.offeringShort)")
                        ImageTag(symbol: "list.bullet.rectangle", text: "\(restaurant.menu.count)-course menu")
                    }
                    .padding(.leading, tagLeading)
                    .padding(.bottom, 14)
                }
            }
    }
}

/// Name, cuisine and chef, address and hours.
struct RestaurantTitle: View {
    let restaurant: Restaurant
    let setup: DiningSetup
    var style: Theme.TextStyle = .title1

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(restaurant.name)
                .textStyle(style)
                .accessibilityAddTraits(.isHeader)
            Text("\(restaurant.cuisine) · \(restaurant.chef)")
                .textStyle(.subhead, color: Theme.Colors.ink2)
            HStack(spacing: 5) {
                Glyph(shape: PinShape(), size: 16)
                    .foregroundStyle(Theme.Colors.muted)
                Text(restaurant.address)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
            HStack(spacing: 5) {
                SymbolIcon(name: "clock", size: 13)
                    .foregroundStyle(Theme.Colors.muted)
                    .frame(width: 16)
                Text("Open \(setup.hoursText)")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
        }
    }
}

/// "Available on Fri, Jan 1, 2027": the one date, its seatings and the deposit.
struct AvailabilityCard: View {
    let setup: DiningSetup

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(size: 40, fill: Theme.Colors.tintRed, foreground: Theme.Colors.red) {
                SymbolIcon(name: "calendar", size: 17)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Available on \(setup.dayWithYearText)")
                    .textStyle(.bodyEmphasis)
                Text("Seatings \(setup.seatingsText) · parties up to \(setup.maxPartySize)")
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                Text("\(setup.depositPerPerson.usdWhole) per person deposit, paid when you book")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// The offering and its numbered courses.
struct MenuCard: View {
    let restaurant: Restaurant
    var showsImage = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsImage {
                CardImage(name: restaurant.menuImage, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumbnailLarge, style: .continuous))
            }
            HStack(spacing: 8) {
                Text(restaurant.offering)
                    .textStyle(.bodyEmphasis)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                NeutralTag(text: restaurant.menu.count == 1 ? "1 course" : "\(restaurant.menu.count) courses")
            }
            .frame(minHeight: 40)
            .padding(.top, 4)

            ForEach(restaurant.menu) { course in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(course.course)")
                        .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(course.dish)
                            .textStyle(.subheadEmphasis)
                        Text(course.detail)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .overlay(alignment: .top) {
                    if course.id != restaurant.menu.first?.id { Hairline() }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Course \(course.course): \(course.dish), \(course.detail)")
            }

            Text(restaurant.menuNote)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .padding(.top, 6)
                .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .cardSurface()
    }
}

/// Neutral pill: "5 courses", "Only date".
struct NeutralTag: View {
    let text: String

    var body: some View {
        Text(text)
            .textStyle(.footnoteEmphasis, color: Theme.Colors.ink2)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minHeight: Theme.Size.imageTag)
            .background(Theme.Colors.tintNeutral, in: Capsule())
    }
}

/// The hotel a short walk away: the customer's stay, when it is booked.
struct NearbyHotelCard: View {
    let name: String
    let detail: String
    let walk: String

    var body: some View {
        HStack(spacing: 10) {
            IconCircle(fill: Theme.Colors.tintRed, foreground: Theme.Colors.red) {
                SymbolIcon(name: "bed.double", size: 15)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .textStyle(.subheadEmphasis)
                Text(detail)
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(walk)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.ink2)
                .lineLimit(1)
        }
        .frame(minHeight: 56)
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .cardSurface(radius: 18)
        .accessibilityElement(children: .combine)
    }
}

/// "$100 per person / Deposit · points or card" and Find a table.
struct FindTableBar: View {
    let setup: DiningSetup
    var action: () -> Void

    var body: some View {
        ActionBar(buttonTitle: "Find a table", action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(setup.depositPerPerson.usdWhole)
                    .textStyle(.headline)
                Text("per person")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            Text("Deposit · points or card")
                .textStyle(.footnote, color: Theme.Colors.muted)
                .lineLimit(1)
        }
    }
}

// MARK: - Steps

/// Thumbnail, name, "Fri, Jan 1 · 8:00 PM · 4 guests", address. Tops every step.
struct MiniRestaurantRow: View {
    let model: DiningFlowModel

    var body: some View {
        StaySummaryRow(imageName: model.restaurant.heroImage, title: model.restaurant.name,
                       line1: summary, line2: model.restaurant.shortAddress)
    }

    private var summary: String {
        [model.setup.dayText, model.selectedTimeText, model.guestsText].compactMap { $0 }.joined(separator: " · ")
    }
}

/// The only date, in the restaurant's time zone.
struct DateRow: View {
    let setup: DiningSetup

    var body: some View {
        HStack(spacing: 10) {
            IconCircle {
                SymbolIcon(name: "calendar", size: 16)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(setup.dayWithYearText)
                    .textStyle(.subheadEmphasis)
                Text("Seatings in Houston time (CT)")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            NeutralTag(text: "Only date")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// "Party size / Up to 6 guests" with − and +.
struct PartyStepperCard: View {
    let model: DiningFlowModel

    var body: some View {
        HStack(spacing: 10) {
            IconCircle {
                SymbolIcon(name: "person.2", size: 14)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Party size")
                    .textStyle(.subheadEmphasis)
                Text("Up to \(model.setup.maxPartySize) guests")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            RoundIconButton(symbol: "minus", label: "Fewer guests", isEnabled: model.canRemoveGuest) {
                withAnimation(Theme.Motion.select) { model.changeParty(by: -1) }
            }
            Text("\(model.party)")
                .textStyle(.title2)
                .frame(width: 28)
                .contentTransition(.numericText())
                .accessibilityLabel(model.guestsText)
            RoundIconButton(symbol: "plus", label: "More guests", isEnabled: model.canAddGuest) {
                withAnimation(Theme.Motion.select) { model.changeParty(by: 1) }
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .cardSurface()
    }
}

/// One start time with the tables left at it.
private struct TimeSlotButton: View {
    let slot: Slot
    let isSelected: Bool
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(slot.timeText)
                        .textStyle(.headline, color: foreground)
                        .strikethrough(slot.isSoldOut)
                    Text(slot.leftText)
                        .textStyle(.footnoteEmphasis, color: detailColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Glyph(shape: CheckShape(), size: 14, lineWidth: 3)
                        .foregroundStyle(Theme.Colors.purple2)
                        .frame(width: 22, height: 22)
                        .background(Theme.Colors.white, in: Circle())
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .frame(minHeight: 64)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: Theme.Size.controlBorder)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .disabled(slot.isSoldOut)
        .accessibilityLabel("\(slot.timeText), \(slot.leftText.lowercased())")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var fill: Color {
        isSelected ? Theme.Colors.purple2 : (slot.isSoldOut ? Theme.Colors.slotSoldOutFill : Theme.Colors.imageTagFill)
    }

    private var border: Color {
        isSelected ? Theme.Colors.purple2 : (slot.isSoldOut ? Theme.Colors.hairline : Theme.Colors.slotBorder)
    }

    private var foreground: Color {
        isSelected ? Theme.Colors.white : (slot.isSoldOut ? Theme.Colors.slotSoldOutText : Theme.Colors.ink)
    }

    private var detailColor: Color {
        if isSelected { return Theme.Colors.white.opacity(0.88) }
        if slot.isSoldOut { return Theme.Colors.indicatorIdleNote }
        return slot.tablesLeft <= 2 ? Theme.Colors.amber : Theme.Colors.muted
    }
}

/// "Start time", the times that fit the party, and why the others are hidden.
struct TimeSlotPicker: View {
    let model: DiningFlowModel
    var showsTitle = true
    var showsHoldNote = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTitle {
                HStack(spacing: 8) {
                    Text("Start time")
                        .textStyle(.bodyEmphasis)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    if model.allSlots.value != nil {
                        Text(model.openCountText)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                }
            }

            // The time the customer chose filled up before they confirmed.
            if let notice = model.soldOutNotice {
                HStack(alignment: .top, spacing: 10) {
                    SymbolIcon(name: "exclamationmark.circle", size: 16)
                        .foregroundStyle(Theme.Colors.red)
                    Text(notice)
                        .textStyle(.subheadEmphasis)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .tintedCard(fill: Theme.Colors.dangerFill, border: Theme.Colors.dangerBorder, radius: 16)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isStaticText)
            }

            switch model.allSlots {
            case .loading:
                grid {
                    ForEach(0..<4, id: \.self) { _ in
                        ShimmerBlock(cornerRadius: 16).frame(height: 64)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading times")
            case .failed:
                SectionErrorCard(title: "Couldn't load times", message: "Your party size is saved.") {
                    Task { await model.loadSlots() }
                }
            case .loaded:
                grid {
                    ForEach(model.fittingSlots) { slot in
                        TimeSlotButton(slot: slot, isSelected: slot.id == model.selectedTime) {
                            withAnimation(Theme.Motion.select) { model.select(slot) }
                        }
                    }
                }
            }

            // Hidden times are explained, not just removed.
            if let note = model.hiddenTimesNote {
                InfoNote(text: note)
            }
            if showsHoldNote {
                InfoNote(text: "Tables aren’t held while you check out. The count drops when a booking is confirmed.")
            }
        }
    }

    private func grid(@ViewBuilder content: () -> some View) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8, content: content)
    }
}

/// "Fri, Jan 1 · 8:00 PM / 4 guests · $400 deposit" and Continue.
struct DiningStepBar: View {
    let model: DiningFlowModel
    var isEnabled = true
    var disabledReason: String?
    var action: () -> Void

    var body: some View {
        ActionBar(buttonTitle: "Continue", isEnabled: isEnabled, disabledReason: disabledReason, action: action) {
            Text(model.slotSummary)
                .textStyle(.headline)
            Text(model.partySummary)
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        .lineLimit(1)
    }
}

// MARK: - Details

/// A labeled field with Required or Optional, and an error under it.
struct GuestField: View {
    let label: String
    var isRequired = false
    @Binding var text: String
    var placeholder = ""
    var error: String?
    /// Requests and notes get two lines.
    var isMultiline = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(label)
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                Spacer(minLength: 0)
                Text(isRequired ? "Required" : "Optional")
                    .textStyle(.statusLabel, color: isRequired ? Theme.Colors.ink2 : Theme.Colors.muted)
            }
            .accessibilityHidden(true)

            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...3)
                        .padding(.vertical, 10)
                        .frame(minHeight: 64, alignment: .top)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(contentType)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : nil)
                        .autocorrectionDisabled(keyboard == .emailAddress)
                        .frame(minHeight: Theme.Size.touch)
                }
            }
            .font(Theme.TextStyle.body.font)
            .foregroundStyle(Theme.Colors.ink)
            .tint(Theme.Colors.purple2)
            .padding(.horizontal, 12)
            .background(Theme.Colors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(error == nil ? Theme.Colors.fieldBorder : Theme.Colors.red.opacity(0.85),
                                  lineWidth: Theme.Size.controlBorder)
            }
            .onChange(of: text) { onEdit() }
            .accessibilityLabel(label)
            .accessibilityValue(text)
            .accessibilityHint([isRequired ? "Required" : "Optional", error].compactMap { $0 }.joined(separator: ". "))

            if let error {
                HStack(spacing: 5) {
                    SymbolIcon(name: "exclamationmark.circle", size: 13)
                        .foregroundStyle(Theme.Colors.red)
                    Text(error)
                        .textStyle(.footnote, color: Theme.Colors.red)
                }
                .accessibilityHidden(true)
            }
        }
    }
}

/// "You already have a table that night", with a way back to the times.
struct OverlapBanner: View {
    let message: String
    var onChangeTime: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                IconCircle(fill: Theme.Colors.dangerIcon, foreground: Theme.Colors.red) {
                    SymbolIcon(name: "exclamationmark.circle", size: 17)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("You already have a table that night")
                        .textStyle(.bodyEmphasis)
                    Text(message)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            Button("Change time", action: onChangeTime)
                .buttonStyle(OutlineButtonStyle(horizontalPadding: 22))
                .padding(.leading, 48)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tintedCard(fill: Theme.Colors.dangerFill, border: Theme.Colors.dangerBorder, radius: Theme.Radius.card)
    }
}

/// Name, email and phone, prefilled from the customer's profile.
struct ContactCard: View {
    @Bindable var model: DiningFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Contact")
                    .textStyle(.bodyEmphasis)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                TagPill(text: "From your profile")
            }
            GuestField(label: "Name on the reservation", isRequired: true, text: $model.name,
                       error: model.errors[.name], contentType: .name) { model.clearError(.name) }
            GuestField(label: "Email", isRequired: true, text: $model.email, placeholder: "For your confirmation",
                       error: model.errors[.email], contentType: .emailAddress, keyboard: .emailAddress) {
                model.clearError(.email)
            }
            GuestField(label: "Mobile phone", isRequired: true, text: $model.phone,
                       placeholder: "For updates from the restaurant", error: model.errors[.phone],
                       contentType: .telephoneNumber, keyboard: .phonePad) { model.clearError(.phone) }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

/// Accessibility needs, special requests and dietary notes. All optional.
struct RestaurantNotesCard: View {
    @Bindable var model: DiningFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("For the restaurant")
                .textStyle(.bodyEmphasis)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 6) {
                Text("Accessibility needs")
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                    .accessibilityAddTraits(.isHeader)
                FlowLayout(spacing: 8) {
                    ForEach(DiningFlowModel.accessibilityOptions, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: model.accessibilityNeeds.contains(option)) {
                            model.accessibilityNeeds.formSymmetricDifference([option])
                        }
                    }
                }
            }

            GuestField(label: "Special requests", text: $model.specialRequests,
                       placeholder: "Celebration, seating preference…", isMultiline: true)
            // Not prefilled from the travel profile's dietary needs.
            GuestField(label: "Dietary notes", text: $model.dietaryNotes,
                       placeholder: "Allergies or needs for anyone in your party", isMultiline: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

// MARK: - Deposit

/// "Deposit due now $400.00 / 4 guests × $100.00" and the points available.
struct DepositDueCard: View {
    let model: DiningFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Deposit due now")
                    .textStyle(.bodyEmphasis)
                Spacer(minLength: 0)
                Text(model.deposit.usd)
                    .textStyle(.headline)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 8) {
                Text(model.depositLine)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Spacer(minLength: 0)
                HStack(spacing: 5) {
                    PointsCoin(size: 18, starSize: 9)
                    Text("\(model.balance.pointsText) available")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
            }
            .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// Deposit, points applied and what's due on the card.
struct DepositBreakdown: View {
    let model: DiningFlowModel
    var showsTotal = true

    var body: some View {
        if let tender = model.tender {
            VStack(spacing: 8) {
                if showsTotal {
                    PriceRow(label: model.depositLabel, value: model.deposit.usd)
                }
                PriceRow(label: "Points (\(tender.points.pointsText))",
                         value: tender.points > 0 ? "−\(tender.pointsValue.usd)" : Decimal(0).usd,
                         valueColor: Theme.Colors.green)
                if showsTotal { Hairline() }
                PriceRow(label: "Due on card", value: tender.cardAmount.usd, isTotal: true)
            }
        }
    }
}

/// The cancellation policy. Display only.
struct PolicyCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconCircle(fill: Theme.Colors.tintGreen, foreground: Theme.Colors.green) {
                SymbolIcon(name: "shield", size: 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Cancellation policy")
                    .textStyle(.subheadEmphasis)
                Text(text)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                Text("Shown for your information; cancellations aren’t available in the app yet.")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

#Preview("Dining components") {
    let store = LifestyleStore.preview()
    let model = store.dining
    return ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            MiniRestaurantRow(model: model)
            AvailabilityCard(setup: model.setup)
            DateRow(setup: model.setup)
            PartyStepperCard(model: model)
            TimeSlotPicker(model: model)
            ContactCard(model: model)
            RestaurantNotesCard(model: model)
            OverlapBanner(message: "Osteria Lume · Fri, Jan 1 · 7:00 PM. Reservations can’t overlap.") {}
            PolicyCard(text: model.policyText)
            MenuCard(restaurant: model.restaurant)
        }
        .padding(16)
    }
    .background(AmbientBackground())
    .task { await model.loadSlots() }
}
