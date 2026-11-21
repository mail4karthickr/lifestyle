//
//  ProfileViews.swift
//  Lifestyle · Day 5 · travel profile setup: Intro, three areas, Done
//
//  Opens full screen from the landing banner. Nothing is required and there is
//  no Save button: each answer saves on its own.
//

import SwiftUI

// MARK: - Intro

/// Personalize your experience: what setup asks, Get started, or Opt out.
struct ProfileIntroView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // The intro beside a sample of what Inspire me will suggest.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        intro
                    } footer: {
                        bar
                    }
                } trailing: {
                    FlowPane(spacing: 8) {
                        WhatYouGetPanel()
                    }
                }
            } else {
                FlowPage {
                    intro
                } bar: {
                    bar
                }
            }
        }
        .flowChrome(title: "Travel profile")
    }

    @ViewBuilder
    private var intro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Personalize your experience")
                .textStyle(.title1)
                .accessibilityAddTraits(.isHeader)
            Text("Tell us what you like once. Fargo Concierge uses it to make every suggestion personal.")
                .textStyle(.subhead, color: Theme.Colors.ink2)
        }

        CardImage(name: "beach", height: 150)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.heroPane, style: .continuous))
            .shadow(color: Theme.Colors.glassShadow, radius: 15, x: 0, y: 12)
            .overlay(alignment: .bottomLeading) {
                ImageTag(symbol: "clock", text: "About 2 minutes · everything optional")
                    .padding(12)
            }
            .riseIn()

        VStack(spacing: 0) {
            Text("Three short areas")
                .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            ForEach(ProfileArea.allCases) { area in
                HStack(spacing: 12) {
                    IconCircle(size: 40) {
                        SymbolIcon(name: area.symbol, size: 17)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(area.title)
                            .textStyle(.bodyEmphasis)
                        Text(Self.introLine(area))
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 64)
                .overlay(alignment: .top) { Hairline() }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 14)
        .cardSurface()
        .riseIn(order: 1)

        InfoNote(text: "Each answer saves as you go. Skip anything you like.", symbol: "checkmark")
    }

    private var bar: some View {
        ProfileActionBar(secondaryTitle: "Opt out", primaryTitle: "Get started",
                         onSecondary: { store.optOutOfProfile() },
                         onPrimary: { store.advance(to: .profileArea(.brands)) })
    }

    private static func introLine(_ area: ProfileArea) -> String {
        switch area {
        case .brands: "Hotels, airlines, venues and restaurants you like"
        case .dining: "Cuisines, dietary needs and price range"
        case .traveler: "Your details, plus KTN, passport and redress number"
        }
    }
}

/// "What you'll get": a trip and hotels like those Inspire me suggests.
private struct WhatYouGetPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What you’ll get")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Text("Fargo Concierge uses your profile for “Inspire me”")
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        .padding(.bottom, 6)

        // An example, not something to tap.
        let sample = MockInspireService.match(ProfileSampleData.sample.afterSetup)
        Group {
            if let trip = sample.trip {
                TripIdeaCard(idea: trip, imageHeight: 100) {}
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(sample.hotels.prefix(2)) { hotel in
                    HotelPickCard(hotel: hotel, imageHeight: 76) {}
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example: \(sample.trip?.title ?? "a trip idea"), and hotels from the brands you pick")
        .riseIn(order: 1)
    }
}

// MARK: - Areas

/// One area of setup: Brands & airlines, Dining or Traveler.
struct ProfileAreaView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let area: ProfileArea

    var body: some View {
        let model = store.profile

        Group {
            if horizontalSizeClass == .regular {
                FlowSplit {
                    FlowPane(spacing: 12) {
                        header(model)
                        if area == .traveler {
                            // Documents lead; the locked details trail.
                            TravelDocumentsCard(model: model)
                            documentsNote
                        } else {
                            ProfileAreaChoices(area: area, model: model)
                        }
                    }
                } trailing: {
                    FlowPane(spacing: 8) {
                        if area == .traveler {
                            LockedDetailsCard(record: model.record)
                        } else {
                            ProfileSummaryPanel(current: area, model: model)
                        }
                    } footer: {
                        bar(model)
                    }
                }
            } else {
                FlowPage {
                    header(model)
                    if area == .traveler {
                        LockedDetailsCard(record: model.record)
                        TravelDocumentsCard(model: model)
                        documentsNote
                    } else {
                        ProfileAreaChoices(area: area, model: model)
                    }
                } bar: {
                    bar(model)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .flowChrome(title: area.title)
        .onAppear { model.enter(area) }
        // Next, Skip and Back all save what is waiting.
        .onDisappear { model.leave(area) }
    }

    private func header(_ model: ProfileModel) -> some View {
        StepHeader(segments: ProfileArea.allCases.count + 1, filled: area.rawValue + 1, caption: area.caption,
                   spokenCaption: area.spokenCaption, title: area.title, subtitle: subtitle) {
            SavePill(state: model.saveState(area)) { model.retry(area) }
        }
    }

    private var subtitle: String {
        switch area {
        case .brands: "Pick favorites; each one saves right away."
        case .dining: "Cuisines, dietary needs and the price range you like."
        case .traveler: "Your details come from your profile. Add documents if you like."
        }
    }

    private var documentsNote: some View {
        InfoNote(text: "Documents are encrypted and stored with your profile. Only the last digits are shown.",
                 symbol: "lock")
    }

    private func bar(_ model: ProfileModel) -> some View {
        ProfileActionBar(secondaryTitle: "Skip", caption: ("Saves as you go", "Nothing is required"),
                         primaryTitle: nextTitle,
                         onSecondary: {
                             model.skip(area)
                             goOn(model)
                         },
                         onPrimary: { goOn(model) })
    }

    private var nextTitle: String {
        switch area {
        case .brands: "Next: Dining"
        case .dining: "Next: Traveler"
        case .traveler: "Finish"
        }
    }

    /// Next is always enabled: nothing is required.
    private func goOn(_ model: ProfileModel) {
        model.leave(area)
        switch area {
        case .brands: store.advance(to: .profileArea(.dining))
        case .dining: store.advance(to: .profileArea(.traveler))
        // The flow is finished: Done has nothing behind it.
        case .traveler: store.path = [.profileDone]
        }
    }
}

/// The chips for Brands & airlines, or for Dining.
private struct ProfileAreaChoices: View {
    let area: ProfileArea
    let model: ProfileModel

    var body: some View {
        let catalog = model.catalog
        let brands = model.preferences.brands
        let dining = model.preferences.dining

        if area == .brands {
            PreferenceGroup(symbol: "bed.double", title: "Hotel brands", subtitle: "Pick any you like") {
                PreferenceChips(catalog.hotelBrands, selected: brands.hotelBrandIds) { model.toggleHotelBrand($0) }
            }
            PreferenceGroup(symbol: "airplane", title: "Airlines", subtitle: "Pick any you like") {
                PreferenceChips(catalog.airlines, selected: brands.airlineIds) { model.toggleAirline($0) }
            }
            PreferenceGroup(symbol: "building.columns", title: "Venues", subtitle: "Pick any you like") {
                PreferenceChips(catalog.venues, selected: brands.venueIds) { model.toggleVenue($0) }
            }
            PreferenceGroup(symbol: "fork.knife", title: "Restaurant brands", subtitle: "Pick any you like") {
                PreferenceChips(catalog.restaurants, selected: brands.restaurantIds) { model.toggleRestaurant($0) }
            }
        } else {
            PreferenceGroup(symbol: "fork.knife", title: "Cuisines", subtitle: "Pick any you like") {
                PreferenceChips(catalog.cuisines, selected: dining.cuisines) { model.toggleCuisine($0) }
            }
            PreferenceGroup(symbol: "leaf", title: "Dietary needs", subtitle: "Saved with your profile") {
                PreferenceChips(catalog.dietaryNeeds, selected: dining.dietaryNeeds) { model.toggleDietaryNeed($0) }
            }
            PreferenceGroup(symbol: "dollarsign.circle", title: "Price range", subtitle: catalog.priceRangeNote) {
                // Single select; tapping the selected range again clears it.
                SegmentedControl(
                    options: catalog.priceRanges.map { .init(value: Optional($0), label: $0) },
                    selection: dining.priceRange) { range in
                    if let range { model.choosePriceRange(range) }
                }
                .accessibilityHint("Tap the selected range again to clear it")
            }
        }
    }
}

/// Regular width: "Your profile", filling in as chips are picked.
private struct ProfileSummaryPanel: View {
    let current: ProfileArea
    let model: ProfileModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your profile")
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Text("Updates as you choose")
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        ForEach(ProfileArea.allCases) { area in
            // Areas not reached yet say what they will ask.
            let isAhead = area.rawValue > current.rawValue && model.isEmpty(area)
            ProfileSummaryCard(area: area, model: model, status: isAhead ? .upNext : .live)
        }
    }
}

// MARK: - Done

/// Your travel profile is set: what was saved, Back to Lifestyle, or Try Inspire me.
struct ProfileDoneView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private static let editNote = "Editing preferences isn’t available in the app yet."

    var body: some View {
        let model = store.profile

        Group {
            if horizontalSizeClass == .regular {
                // The summary splits across both panes; the action bar trails.
                FlowSplit {
                    FlowPane(spacing: 12) {
                        header
                        ProfileSummaryCard(area: .brands, model: model, status: .final)
                        ProfileSummaryCard(area: .dining, model: model, status: .final)
                    }
                } trailing: {
                    FlowPane(spacing: 12) {
                        ProfileSummaryCard(area: .traveler, model: model, status: .final)
                        InfoNote(text: Self.editNote)
                    } footer: {
                        bar
                    }
                }
            } else {
                FlowPage {
                    header
                    ForEach(ProfileArea.allCases) { area in
                        ProfileSummaryCard(area: area, model: model, status: .final)
                            .riseIn(order: area.rawValue + 1)
                    }
                    InfoNote(text: Self.editNote)
                } bar: {
                    bar
                }
            }
        }
        .flowChrome(title: "Travel profile")
    }

    @ViewBuilder
    private var header: some View {
        StepHeader(segments: ProfileArea.allCases.count + 1, filled: ProfileArea.allCases.count + 1, caption: "All set")

        VStack(alignment: .leading, spacing: 8) {
            ConfirmationCheck(size: 56)
            Text("Your travel profile is set")
                .textStyle(.title1)
                .accessibilityAddTraits(.isHeader)
            Text("Fargo Concierge will use it to make suggestions personal.")
                .textStyle(.subhead, color: Theme.Colors.ink2)
        }
        .riseIn()
    }

    private var bar: some View {
        ProfileActionBar(secondaryTitle: "Back to Lifestyle", primaryTitle: "Try Inspire me", primaryKind: .purple,
                         primaryShowsSparkle: true,
                         onSecondary: { store.closeFlow() },
                         onPrimary: { store.tryInspireMe() })
    }
}

// MARK: - Previews

#Preview("Intro · compact") {
    let store = LifestyleStore.preview()
    store.path = [.profileIntro]
    return LifestyleRootView(store: store)
}

#Preview("Brands · compact") {
    let store = LifestyleStore.preview(profile: ProfileSampleData.sample.afterSetup)
    store.path = [.profileIntro, .profileArea(.brands)]
    return LifestyleRootView(store: store)
}

#Preview("Dining · regular", traits: .landscapeLeft) {
    let store = LifestyleStore.preview(profile: ProfileSampleData.sample.afterSetup)
    store.path = [.profileIntro, .profileArea(.brands), .profileArea(.dining)]
    return LifestyleRootView(store: store).environment(\.horizontalSizeClass, .regular)
}

#Preview("Done · compact") {
    let store = LifestyleStore.preview(profile: ProfileSampleData.sample.afterSetup)
    store.path = [.profileDone]
    return LifestyleRootView(store: store)
}
