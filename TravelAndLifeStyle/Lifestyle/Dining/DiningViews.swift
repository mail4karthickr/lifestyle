//
//  DiningViews.swift
//  Lifestyle · Day 3 · Restaurant, Choose a table, Your details, Deposit
//
//  One decision per screen on compact width. Regular width pairs each decision
//  with the next level of detail in a split arrangement.
//

import SwiftUI

// MARK: - Restaurant

/// Is this the place: the room, the chef, the one date and the menu.
struct RestaurantView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let model = store.dining

        Group {
            if horizontalSizeClass == .regular {
                // Restaurant, availability and nearby beside the menu and Find a table.
                FlowSplit {
                    FlowPane {
                        RestaurantHero(restaurant: model.restaurant, setup: model.setup, height: 190, tagLeading: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .riseIn()
                        RestaurantTitle(restaurant: model.restaurant, setup: model.setup, style: .paneTitle)
                        AvailabilityCard(setup: model.setup)
                        Text(model.restaurant.about)
                            .textStyle(.footnote, color: Theme.Colors.ink2)
                        nearby
                    }
                } trailing: {
                    FlowPane {
                        MenuCard(restaurant: model.restaurant, showsImage: false)
                            .riseIn(order: 1)
                    } footer: {
                        FindTableBar(setup: model.setup) { store.advance(to: .diningTable) }
                    }
                }
            } else {
                RestaurantCompact(model: model) { nearby }
            }
        }
        .flowChrome(title: model.restaurant.name)
        .task { await model.loadSlots() }
    }

    /// Hotel Solenne is a short walk away: the customer's stay, once it is booked.
    private var nearby: some View {
        let model = store.dining
        let stay = store.bookings.hotel(named: model.restaurant.nearbyName)
        let detail = stay.map { "Your stay, \(TripCalendar.shortRange($0.checkIn, $0.checkOut))" } ?? "Near the restaurant"
        return NearbyHotelCard(name: model.restaurant.nearbyName, detail: detail, walk: model.restaurant.nearbyWalk)
    }
}

/// The photo runs full width, under the bars; everything else keeps to the safe area.
private struct RestaurantCompact<Nearby: View>: View {
    @Environment(LifestyleStore.self) private var store
    let model: DiningFlowModel
    @ViewBuilder var nearby: Nearby

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
                    RestaurantHero(restaurant: model.restaurant, setup: model.setup,
                                   height: container.height < 760 ? 220 : 300, tagLeading: leading)
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28,
                                                          style: .continuous))
                        .riseIn()

                    VStack(alignment: .leading, spacing: 12) {
                        RestaurantTitle(restaurant: model.restaurant, setup: model.setup)
                        AvailabilityCard(setup: model.setup)
                            .riseIn(order: 1)
                        sectionTitle("About")
                        Text(model.restaurant.about)
                            .textStyle(.subhead, color: Theme.Colors.ink2)
                        sectionTitle("Menu")
                        MenuCard(restaurant: model.restaurant)
                            .riseIn(order: 2)
                        sectionTitle("Nearby")
                        nearby
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
                FindTableBar(setup: model.setup) { store.advance(to: .diningTable) }
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .padding(.bottom, insets.bottom > 0 ? 0 : 12)
            }
            .ignoresSafeArea(.container, edges: [.top, .horizontal])
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .textStyle(.section)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Step 1 · Table

/// Party size and start time. Only times whose table fits the party are shown.
struct DiningTableView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// The panes are one above the other (tabletop).
    @State private var isStacked = false

    private static let needsTime = "Choose a start time to continue"

    var body: some View {
        let model = store.dining

        Group {
            if horizontalSizeClass == .regular {
                GeometryReader { proxy in
                    // Side by side: the choice beside a live summary of the table.
                    // Stacked (tabletop): restaurant and Your table on the upright
                    // half; party size, times and Continue on the flat half.
                    let isStacked = proxy.size.height > proxy.size.width
                    FlowSplit {
                        if isStacked {
                            FlowPane {
                                // The restaurant beside the table so far.
                                HStack(alignment: .top, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        RestaurantHero(restaurant: model.restaurant, setup: model.setup, height: 200, showsTags: false)
                                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                        Text(model.restaurant.name)
                                            .textStyle(.cardTitle)
                                            .padding(.top, 4)
                                        Text("\(model.restaurant.cuisine) · \(model.restaurant.chef)")
                                            .textStyle(.footnote, color: Theme.Colors.ink2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    YourTableCard(model: model)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        } else {
                            FlowPane {
                                StepHeader.dining(step: 1, title: "Choose a table")
                                DateRow(setup: model.setup)
                                PartyStepperCard(model: model)
                                TimeSlotPicker(model: model)
                            }
                        }
                    } trailing: {
                        if isStacked {
                            FlowPane {
                                PartyStepperCard(model: model)
                                TimeSlotPicker(model: model, showsTitle: false, showsHoldNote: false)
                            } footer: {
                                DiningStepBar(model: model, isEnabled: model.canContinueFromTable,
                                              disabledReason: Self.needsTime, action: goOn)
                            }
                        } else {
                            FlowPane(spacing: 8) {
                                YourTablePanel(model: model)
                            } footer: {
                                Button("Continue", action: goOn)
                                    .buttonStyle(FilledButtonStyle(kind: .red))
                                    .disabled(!model.canContinueFromTable)
                                    .accessibilityHint(model.canContinueFromTable ? "" : Self.needsTime)
                            }
                        }
                    }
                    .onChange(of: isStacked, initial: true) { _, stacked in
                        self.isStacked = stacked
                    }
                }
            } else {
                FlowPage {
                    StepHeader.dining(step: 1, title: "Choose a table")
                    MiniRestaurantRow(model: model)
                    DateRow(setup: model.setup)
                    PartyStepperCard(model: model)
                    TimeSlotPicker(model: model)
                } bar: {
                    DiningStepBar(model: model, isEnabled: model.canContinueFromTable,
                                  disabledReason: Self.needsTime, action: goOn)
                }
            }
        }
        .flowChrome(title: "Choose a table",
                    barSubtitle: horizontalSizeClass == .regular && isStacked
                        ? "\(model.restaurant.name) · \(model.setup.dayText)" : nil)
        .task { await model.loadSlots() }
    }

    private func goOn() {
        guard store.dining.canContinueFromTable else { return }
        store.advance(to: .diningDetails)
    }
}

/// Regular width: "Your table", updating as the customer chooses.
private struct YourTablePanel: View {
    let model: DiningFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your table")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Text("Updates as you choose")
                .textStyle(.footnote, color: Theme.Colors.muted)
        }

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Thumbnail(name: model.restaurant.heroImage, size: 48)
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.restaurant.name)
                        .textStyle(.headline)
                    Text(model.restaurant.cuisine)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)

            row("Date", model.setup.dayWithYearText, symbol: "calendar")
            row("Time", model.selectedTimeText ?? "Choose a time", symbol: "clock")
            row("Party", model.guestsText, symbol: "person.2")
        }
        .padding(.top, 10)
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
        .cardSurface()
        .padding(.top, 6)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("Deposit")
                    .textStyle(.subheadEmphasis)
                Spacer(minLength: 0)
                Text(model.deposit.usd)
                    .textStyle(.subheadEmphasis)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 12) {
                Text("\(model.party) × \(model.setup.depositPerPerson.usd)")
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Spacer(minLength: 0)
                Text("or \(model.deposit.cents.pointsText)")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private func row(_ label: String, _ value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            IconCircle(size: 34) {
                SymbolIcon(name: symbol, size: 14)
            }
            Text(label)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .textStyle(.subheadEmphasis)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
        }
        .frame(minHeight: 50)
        .overlay(alignment: .top) { Hairline() }
        .accessibilityElement(children: .combine)
    }
}

/// Tabletop: date, time, party and deposit, on the upright half.
private struct YourTableCard: View {
    let model: DiningFlowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your table")
                .textStyle(.bodyEmphasis)
                .accessibilityAddTraits(.isHeader)
            PriceRow(label: "Date", value: model.setup.dayText)
            PriceRow(label: "Time", value: model.selectedTimeText ?? "Choose a time")
            PriceRow(label: "Party", value: model.guestsText)
            Hairline()
            PriceRow(label: "Deposit", value: model.deposit.usd, isTotal: true)
            Text("or \(model.deposit.cents.pointsText)")
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

// MARK: - Step 2 · Details

/// Contact details, accessibility needs, requests and dietary notes.
struct DiningDetailsView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private static let top = "details-top"

    var body: some View {
        let model = store.dining

        ScrollViewReader { scroll in
            Group {
                if horizontalSizeClass == .regular {
                    // Contact beside "For the restaurant".
                    FlowSplit {
                        FlowPane(spacing: 12) {
                            StepHeader.dining(step: 2, title: "Your details")
                                .id(Self.top)
                            overlapBanner(model)
                            ContactCard(model: model)
                        }
                    } trailing: {
                        FlowPane(spacing: 12) {
                            RestaurantNotesCard(model: model)
                            InfoNote(text: "Your entries stay here if you go back a step.", symbol: "lock")
                        } footer: {
                            DiningStepBar(model: model) { goOn(scroll) }
                        }
                    }
                } else {
                    FlowPage {
                        StepHeader.dining(step: 2, title: "Your details")
                            .id(Self.top)
                        MiniRestaurantRow(model: model)
                        overlapBanner(model)
                        ContactCard(model: model)
                        RestaurantNotesCard(model: model)
                        InfoNote(text: "Your entries stay here if you go back a step.", symbol: "lock")
                    } bar: {
                        DiningStepBar(model: model) { goOn(scroll) }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .flowChrome(title: "Your details")
        .animation(Theme.Motion.select, value: model.overlap)
        .animation(Theme.Motion.select, value: model.errors)
    }

    @ViewBuilder
    private func overlapBanner(_ model: DiningFlowModel) -> some View {
        if let message = model.overlapMessage {
            OverlapBanner(message: message) { store.pop(to: .diningTable) }
                .transition(.opacity)
        }
    }

    /// Checks the required fields and the overlap rule before moving on.
    private func goOn(_ scroll: ScrollViewProxy) {
        let model = store.dining
        if model.validateDetails() {
            model.prepareDeposit()
            store.advance(to: .diningDeposit)
        } else {
            // Bring the problem into view and tell VoiceOver about it.
            withAnimation(Theme.Motion.select) { scroll.scrollTo(Self.top, anchor: .top) }
            let message = model.overlapMessage.map { "You already have a table that night. \($0)" }
                ?? model.errors.values.sorted().joined(separator: " ")
            AccessibilityNotification.Announcement(message).post()
        }
    }
}

// MARK: - Step 3 · Deposit

/// $100 per person, paid with points, a card or both.
struct DiningDepositView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isAddingCard = false

    private static let pointsNote = "Points come off your balance only after the reservation is confirmed."

    var body: some View {
        let model = store.dining

        Group {
            if horizontalSizeClass == .regular {
                // Pay controls beside the order summary and its points and card split.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        StepHeader.dining(step: 3, title: "Deposit")
                        DepositDueCard(model: model)
                        PayControls(model: model, isAddingCard: $isAddingCard)
                    }
                } trailing: {
                    FlowPane {
                        DepositSummaryPanel(model: model, action: goOn)
                    }
                }
            } else {
                FlowPage {
                    StepHeader.dining(step: 3, title: "Deposit")
                    MiniRestaurantRow(model: model)
                    DepositDueCard(model: model)
                    PayControls(model: model, isAddingCard: $isAddingCard)
                    VStack(alignment: .leading, spacing: 8) {
                        DepositBreakdown(model: model)
                        Text(Self.pointsNote)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                    .padding(14)
                    .cardSurface()
                    PolicyCard(text: model.policyText)
                } bar: {
                    ActionBar(buttonTitle: "Continue", action: goOn) {
                        Text(model.chargeText)
                            .textStyle(.headline)
                            .contentTransition(.numericText())
                        Text(model.depositSummary)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                    .lineLimit(1)
                    .animation(Theme.Motion.select, value: model.points)
                }
            }
        }
        .flowChrome(title: "Deposit")
        .onAppear { model.prepareDeposit() }
        .sheet(isPresented: $isAddingCard) {
            AnotherCardSheet { card in
                model.otherCard = card
                model.card = card
            }
        }
    }

    private func goOn() {
        store.advance(to: .diningReview)
    }
}

/// Regular width: the table, the deposit, the points and card split, the policy and Continue.
private struct DepositSummaryPanel: View {
    let model: DiningFlowModel
    var action: () -> Void

    var body: some View {
        SummaryPanel(spacing: 8) {
            Text("Order summary")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            MiniRestaurantRow(model: model)
                .padding(.bottom, 4)

            PriceRow(label: model.depositLabel, value: model.deposit.usd, isTotal: true)
            SplitBar(pointsShare: model.pointsShare)
                .padding(.top, 6)
                .padding(.bottom, 2)
            HStack(spacing: 6) {
                legend("Points", color: Theme.Colors.yellow)
                Spacer(minLength: 0)
                legend("Card", color: Theme.Colors.purple2)
            }
            DepositBreakdown(model: model, showsTotal: false)

            Text(model.policyText)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .padding(.top, 4)

            Button("Continue", action: action)
                .buttonStyle(FilledButtonStyle(kind: .red))
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

// MARK: - Previews

#Preview("Restaurant · compact") {
    let store = LifestyleStore.preview(seed: .hotelOnly)
    store.open(.restaurant)
    return LifestyleRootView(store: store)
}

#Preview("Table · compact") {
    let store = LifestyleStore.preview()
    store.open(.restaurant)
    store.advance(to: .diningTable)
    return LifestyleRootView(store: store)
}

#Preview("Table · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview()
    store.open(.restaurant)
    store.advance(to: .diningTable)
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}
