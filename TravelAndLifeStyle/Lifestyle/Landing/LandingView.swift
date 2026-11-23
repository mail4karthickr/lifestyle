//
//  LandingView.swift
//  Lifestyle · landing page
//
//  One adaptive layout, driven by size classes (Day 1 spec, section 2):
//  compact width is a single scrolling column; regular width is a split
//  arrangement with the leading and trailing panes side by side.
//

import SwiftUI

struct LandingView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

    /// Close: back to the retail app's Menu, where Lifestyle is opened from.
    var onClose: () -> Void

    private var isRegular: Bool { horizontalSizeClass == .regular }

    /// On compact width with a horizontal bar, the points pill shares the bar's
    /// row with Close. Otherwise it lives in the content.
    private var showsPointsInBar: Bool { !isRegular && toolbarVerticalEdge == nil }

    var body: some View {
        Group {
            if isRegular {
                LandingRegularLayout()
            } else {
                LandingCompactLayout()
            }
        }
        .background { AmbientBackground() }
        // The title names the page for VoiceOver and for the Back button of the
        // pages it opens; it isn't shown.
        .navigationTitle("Lifestyle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .toolbar {
            // The only Close in Lifestyle: this is the page the retail app
            // opens, so there is no Back. On iPhone Duo it moves to the side bar.
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onClose) {
                    Label("Close", systemImage: "xmark")
                }
            }
            if showsPointsInBar {
                ToolbarItem(placement: .topBarTrailing) {
                    PointsPill(state: store.rewards.state)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        // One-time toast after the travel profile is saved (Day 5).
        .overlay(alignment: .bottom) {
            LandingToastHost()
        }
        // Every time the page shows, fetch the bookings and rebuild My plans (Day 4).
        .onAppear { store.landingAppeared() }
        .onChange(of: store.profileToastIsDue, initial: true) { _, isDue in
            if isDue { store.showProfileToast() }
        }
    }
}

// MARK: - Metrics

/// Sizes that change with the layout. Derived from the container, never from the device.
struct LandingMetrics {
    var margin: CGFloat
    var heroHeight: CGFloat
    var carousel: CarouselMetrics
    var tileHeight: CGFloat
    var contentTop: CGFloat
    var contentBottom: CGFloat
    var tabsTopGap: CGFloat
    var sectionTopGap: CGFloat

    /// Margin grows on wider displays, like the system's layout margins.
    static func margin(forWidth width: CGFloat) -> CGFloat { width >= 430 ? 20 : 16 }

    /// Single column. Shorter displays get a shorter hero and smaller cards.
    static func compact(container: CGSize, insets: EdgeInsets) -> LandingMetrics {
        let margin = margin(forWidth: container.width)
        let isShort = container.height < 760
        return LandingMetrics(
            margin: margin,
            heroHeight: isShort ? 232 : 300,
            carousel: CarouselMetrics(
                travelCardWidth: isShort ? 230 : 260,
                imageHeight: isShort ? 112 : 150,
                // Bleed to the display edge, but never under a side bar.
                leadingBleed: insets.leading > 0 ? 0 : margin,
                trailingBleed: insets.trailing > 0 ? 0 : margin),
            tileHeight: isShort ? 84 : 92,
            contentTop: isShort ? 12 : 16,
            contentBottom: isShort ? 40 : 48,
            tabsTopGap: isShort ? 4 : 8,
            sectionTopGap: isShort ? 8 : 12)
    }

    /// Split panes. The sizes are the same half folded and flat: the device is
    /// half folded for a moment every time it opens, and sizes of its own there
    /// made the hero and the cards jump as it went flat.
    static func regular(showsBanner: Bool) -> LandingMetrics {
        LandingMetrics(
            margin: 20,
            heroHeight: showsBanner ? 190 : 230,
            carousel: CarouselMetrics(travelCardWidth: 210, imageHeight: 100),
            tileHeight: 88,
            contentTop: 20,
            contentBottom: 20,
            tabsTopGap: 2,
            sectionTopGap: 18)
    }
}

// MARK: - Shared section builders

/// Banner, search, tabs and carousel: the leading pane on regular width.
private struct LandingBrowseSections: View {
    @Environment(LifestyleStore.self) private var store
    let metrics: LandingMetrics

    var body: some View {
        @Bindable var store = store
        let tab = store.content.tabs.first { $0.id == store.selectedTabID } ?? store.content.tabs[0]

        if store.showsProfileBanner {
            ProfileBanner { store.open(.profileIntro) }
                .riseIn(order: 1)
        }

        // The way into Fargo Concierge, with the chat's own ideas as examples.
        ConciergeSearchBox(examples: store.content.concierge.inspireMe.map(\.prompt)) {
            store.open(.concierge)
        }
        .riseIn(order: 2)

        CategoryTabBar(tabs: store.content.tabs, selection: $store.selectedTabID)
            .padding(.top, metrics.tabsTopGap)

        LandingCarousel(
            tab: tab,
            state: store.carousel.state,
            metrics: metrics.carousel,
            position: Binding(
                get: { store.carouselPosition[tab.id] },
                set: { store.carouselPosition[tab.id] = $0 }),
            onSelectTravel: { store.open($0.route) },
            onSelectDining: { store.open($0.route) },
            onRetry: { Task { await store.carousel.load() } })
            .id(tab.id)
    }
}

/// Book now and My plans: the trailing pane on regular width.
private struct LandingBookingSections: View {
    @Environment(LifestyleStore.self) private var store
    let metrics: LandingMetrics
    /// Gap above Book now; zero when it starts a pane.
    var bookNowTopGap: CGFloat

    var body: some View {
        BookNowSection(tiles: store.content.bookNowTiles, tileHeight: metrics.tileHeight) { tile in
            store.open(tile.route)
        }
        .padding(.top, bookNowTopGap)
        .riseIn(order: 3)

        // The last section, always there (Day 1). A plan opens its trip (Day 4).
        MyPlansSection(
            state: store.trips.state,
            onSelect: { store.open($0) },
            onPlanWithConcierge: { store.open(.concierge) },
            onRetry: { Task { await store.trips.load() } })
            .padding(.top, metrics.sectionTopGap)
    }
}

// MARK: - Compact width

/// Single scrolling column. The hero runs full width behind the bars; everything
/// else keeps to the safe area, which is asymmetric when there's a side bar.
private struct LandingCompactLayout: View {
    @Environment(LifestyleStore.self) private var store
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    @State private var position = ScrollPosition(edge: .top)

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let container = CGSize(
                width: proxy.size.width + insets.leading + insets.trailing,
                height: proxy.size.height + insets.top + insets.bottom)
            let metrics = LandingMetrics.compact(container: container, insets: insets)
            // An edge the safe area already clears (a side bar) needs no extra margin.
            let leading = max(insets.leading, metrics.margin)
            let trailing = max(insets.trailing, metrics.margin)

            ScrollView {
                VStack(spacing: 0) {
                    HeroView(
                        customer: store.content.customer,
                        rewards: store.rewards.state,
                        layout: .fullBleed(leading: leading, trailing: trailing),
                        height: metrics.heroHeight,
                        onRetry: { Task { await store.rewards.load() } })

                    VStack(alignment: .leading, spacing: 12) {
                        LandingBrowseSections(metrics: metrics)
                        LandingBookingSections(metrics: metrics, bookNowTopGap: metrics.sectionTopGap)
                    }
                    .padding(.top, metrics.contentTop)
                    .padding(.leading, leading)
                    .padding(.trailing, trailing)
                    .padding(.bottom, metrics.contentBottom)
                }
            }
            .scrollPosition($position)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, offset in
                store.pageOffset = offset
            }
            .ignoresSafeArea(.container, edges: [.top, .horizontal])
            // With a side bar there is no bar row for the points balance, so
            // it sits at the top right of the content, over the hero.
            .overlay(alignment: .topTrailing) {
                if toolbarVerticalEdge != nil {
                    PointsPill(state: store.rewards.state)
                        .padding(.trailing, max(metrics.margin - insets.trailing, 0))
                        .padding(.top, insets.top > 0 ? 0 : metrics.margin)
                }
            }
        }
        .onAppear {
            // Come back to where the page was before the display changed.
            if store.pageOffset > 0 { position.scrollTo(y: store.pageOffset) }
        }
    }
}

// MARK: - Regular width

/// Split arrangement. Leading: logo row, hero, banner, search, tabs, carousel.
/// Trailing: Book now, My plans. The system keeps both panes out of the fold.
private struct LandingRegularLayout: View {
    @Environment(LifestyleStore.self) private var store

    var body: some View {
        let metrics = LandingMetrics.regular(showsBanner: store.showsProfileBanner)

        GeometryReader { proxy in
            let panes = SplitPaneInsets(safeArea: proxy.safeAreaInsets)

            ArrangementView {
                LandingPane(insets: panes, position: .first) {
                    // The header: the points balance, at the right of the pane.
                    PointsPill(state: store.rewards.state)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    HeroView(
                        customer: store.content.customer,
                        rewards: store.rewards.state,
                        layout: .card,
                        height: metrics.heroHeight,
                        onRetry: { Task { await store.rewards.load() } })
                    LandingBrowseSections(metrics: metrics)
                }
                .splitArrangementLayoutRatio(idealHorizontal: 0.53, idealVertical: 0.6)
            } secondary: {
                LandingPane(insets: panes, position: .second) {
                    LandingBookingSections(metrics: metrics, bookNowTopGap: 0)
                }
            }
            .arrangementViewStyle(.split)
        }
    }
}

/// One pane of the split arrangement. Scrolls only when its content doesn't fit.
private struct LandingPane<Content: View>: View {
    let insets: SplitPaneInsets
    let position: SplitPaneInsets.Position
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .splitPanePadding(insets, position: position)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }
}

/// Keeps the toast clear of the side bar and the bottom edge.
private struct LandingToastHost: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let margin = LandingMetrics.margin(forWidth: proxy.size.width + insets.leading + insets.trailing)

            VStack {
                Spacer(minLength: 0)
                if store.showsProfileToast {
                    ProfileSavedToast()
                        .frame(maxWidth: 420)
                        .padding(.leading, max(margin - insets.leading, 0))
                        .padding(.trailing, max(margin - insets.trailing, 0))
                        .padding(.bottom, insets.bottom > 0 ? 4 : 26)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .animation(Theme.Motion.select, value: store.showsProfileToast)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Compact · nothing booked") {
    LifestyleRootView(store: .preview())
}

#Preview("Compact · two trips, Dining") {
    LifestyleRootView(store: .preview(seed: .twoTrips, tab: CategoryTab.diningID))
}

#Preview("Compact · loading") {
    LifestyleRootView(store: .preview(.loading))
}

#Preview("Compact · My plans failed") {
    LifestyleRootView(store: .preview(seed: .twoTrips, .tripsFailed))
}

#Preview("Regular · nothing booked", traits: .landscapeLeft) {
    LifestyleRootView(store: .preview())
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Regular · two trips, Dining", traits: .landscapeLeft) {
    LifestyleRootView(store: .preview(seed: .twoTrips, tab: CategoryTab.diningID))
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Regular · loading", traits: .landscapeLeft) {
    LifestyleRootView(store: .preview(.loading))
        .environment(\.horizontalSizeClass, .regular)
}
