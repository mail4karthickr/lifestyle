//
//  ConciergeView.swift
//  Lifestyle · simulated Concierge chat
//
//  start → follow-up questions → hotel + dining picks with a reason each.
//  Compact width is one column. Regular width adds a context pane:
//  Inspire me → live trip brief → picks.
//

import SwiftUI

struct ConciergeView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        @Bindable var model = store.concierge

        Group {
            if horizontalSizeClass == .regular {
                ConciergeRegularLayout(model: store.concierge)
            } else {
                ConciergeCompactLayout(model: store.concierge)
            }
        }
        .sheet(isPresented: $model.isChoosingDates) {
            ConciergeDatesSheet(model: store.concierge)
        }
        .background { AmbientBackground() }
        .navigationTitle("Fargo Concierge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Back comes from the navigation stack; New chat follows it.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(Theme.Motion.select) { store.concierge.newChat() }
                } label: {
                    Label("New chat", systemImage: "square.and.pencil")
                }
            }
        }
    }
}

// MARK: - Shared pieces

private extension View {
    /// The bar title in the brand font. With a side bar there is no horizontal
    /// bar for a title to sit in, so the content shows it (`ConciergePageTitle`).
    func conciergeTitle(isShown: Bool) -> some View {
        self
            .toolbar(removing: isShown ? nil : .title)
            .toolbar {
                if isShown {
                    ToolbarItem(placement: .principal) {
                        Text("Fargo Concierge")
                            .textStyle(.headline)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
    }
}

/// The page's title in the content, in the same style as every other page's.
/// It stays above the thread where no bar shows the title: a conversation
/// starts with the customer's own line at the right, which left the top left
/// of the page empty. The start screen has the greeting there instead.
private struct ConciergePageTitle: View {
    var body: some View {
        Text("Fargo Concierge")
            .textStyle(.title1)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// "Hi Avery, I'm your Fargo Concierge. / What do you want to do?"
private struct ConciergeGreeting: View {
    let model: ConciergeModel
    var style: Theme.TextStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.content.greeting, id: \.self) { line in
                Text(line)
                    .textStyle(style)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .riseIn()
    }
}

/// Right-aligned prompt chips. Only the scripted request starts a conversation in the POC.
private struct PromptChipList: View {
    let model: ConciergeModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(model.content.promptChips, id: \.self) { prompt in
                PromptChip(title: prompt, showsSparkle: prompt == model.content.promptChips.last) {
                    withAnimation(Theme.Motion.select) { model.choose(prompt: prompt) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .riseIn(order: 2)
    }
}

/// The conversation so far. `showsPickCards` is false when the picks live in the context pane.
private struct ConciergeThread: View {
    @Environment(LifestyleStore.self) private var store
    let model: ConciergeModel
    var showsPickCards: Bool
    /// Side by side, the picks sit across the fold from the chat, so the line says they are ready.
    var usesReadyLine = false
    var userBubbleWidth: CGFloat = 290
    var conciergeBubbleWidth: CGFloat = 300
    /// How far a sideways scroller may run past the thread's margins.
    var bleed: (leading: CGFloat, trailing: CGFloat) = (0, 0)
    /// Tabletop: the flights sit under the thread; the trip and hotels are on the upright half.
    var showsInspireFlights = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let request = model.request {
                UserBubble(text: request, maxWidth: userBubbleWidth)
            }

            switch model.stage {
            case .start:
                EmptyView()
            case .questions:
                if model.revealedLines >= 1 {
                    ConciergeBubble(model.introLine, maxWidth: conciergeBubbleWidth)
                    FollowUpCard(model: model)
                } else if model.isTyping {
                    typing
                }
            case .picks:
                AnswersSummaryCard(summary: model.answersSummary) {
                    withAnimation(Theme.Motion.select) { model.editAnswers() }
                }
                if model.revealedLines >= 2 {
                    ConciergeBubble(usesReadyLine ? model.picksReadyLine : model.picksLine,
                                    maxWidth: conciergeBubbleWidth)
                    if showsPickCards {
                        ForEach(Array(model.picks.enumerated()), id: \.element.id) { index, pick in
                            PickCardCompact(pick: pick, reason: model.reason(for: pick)) { store.open(pick) }
                                .riseIn(order: index + 1)
                        }
                    }
                    afterPicks
                } else if model.isTyping {
                    typing
                }
            case .inspired:
                if let result = model.inspireResult {
                    ConciergeBubble(model.inspireIntro(for: result), maxWidth: conciergeBubbleWidth)
                    // Only when something in the profile drove the picks.
                    if result.isPersonal { BasedOnRow(names: result.basedOn) }
                    if showsPickCards {
                        InspirePicks(result: result, showsMoreHotels: model.showsMoreHotels,
                                     style: .thread(leadingBleed: bleed.leading, trailingBleed: bleed.trailing))
                    } else if showsInspireFlights {
                        InspirePicks(result: result, showsMoreHotels: model.showsMoreHotels, style: .flights)
                    }
                    InspireFollowUp(model: model, result: result, bubbleWidth: conciergeBubbleWidth)
                } else if model.isTyping {
                    typing
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typing: some View {
        ConciergeBubble(maxWidth: conciergeBubbleWidth, isTyping: true) {
            TypingDots()
        }
    }

    /// "Show other options" has no destination in the POC; "Change dates" reopens the answers.
    private var afterPicks: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                ForEach(model.content.afterPicksChips, id: \.self) { chip in
                    ChoiceChip(title: chip, isSelected: false) {
                        if chip == model.content.afterPicksChips.last {
                            // "Change dates" opens the date picker; the picks stay.
                            model.isChoosingDates = true
                        }
                    }
                }
            }
            Text(model.content.footnote)
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
    }
}

// MARK: - Compact width

private struct ConciergeCompactLayout: View {
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let model: ConciergeModel

    var body: some View {
        @Bindable var model = model

        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let container = CGSize(
                width: proxy.size.width + insets.leading + insets.trailing,
                height: proxy.size.height + insets.top + insets.bottom)
            let margin = LandingMetrics.margin(forWidth: container.width)
            let isShort = container.height < 760
            let hasTopBar = toolbarVerticalEdge == nil
            // An edge the safe area already clears (a side bar) needs no extra margin.
            let leading = max(margin - insets.leading, 0)
            let trailing = max(margin - insets.trailing, 0)

            Group {
                if model.stage == .start {
                    ScrollView {
                        start(leadingBleed: leading, trailingBleed: trailing, isShort: isShort)
                            .padding(.leading, leading)
                            .padding(.trailing, trailing)
                            .padding(.top, hasTopBar ? 12 : max(margin - insets.top, 0))
                            .padding(.bottom, 12)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    VStack(spacing: 0) {
                        if !hasTopBar {
                            ConciergePageTitle()
                                .padding(.leading, leading)
                                .padding(.trailing, trailing)
                                .padding(.top, max(margin - insets.top, 0))
                        }
                        ScrollView {
                            ConciergeThread(model: model, showsPickCards: true, bleed: (leading, trailing))
                                .padding(.leading, leading)
                                .padding(.trailing, trailing)
                                .padding(.vertical, 12)
                        }
                        // Picks read from the top; a conversation follows its latest line.
                        .defaultScrollAnchor(model.stage == .inspired ? .top : .bottom)
                        // A thread shorter than the screen starts under the bar, with
                        // no gap above it.
                        .defaultScrollAnchor(.top, for: .alignment)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 12) {
                    if model.stage == .start {
                        DisclosureCard(text: model.content.disclosure)
                    } else if model.stage == .picks || model.stage == .inspired {
                        // iPhone Duo, closed: the inner display shows the picks
                        // beside the chat. Kept above the composer, where it
                        // shows wherever the thread is scrolled to.
                        OpenForMoreHint(text: "See your picks beside the chat.")
                    }
                    ComposerBar(text: $model.draft) {
                        withAnimation(Theme.Motion.select) { model.submitDraft() }
                    }
                }
                .padding(.leading, leading)
                .padding(.trailing, trailing)
                .padding(.bottom, insets.bottom > 0 ? 0 : 12)
            }
            .conciergeTitle(isShown: hasTopBar)
        }
    }

    private func start(leadingBleed: CGFloat, trailingBleed: CGFloat, isShort: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ConciergeGreeting(model: model, style: isShort ? .title1 : .largeTitle)

            VStack(alignment: .leading, spacing: 8) {
                Text("INSPIRE ME")
                    .textStyle(.caps, color: Theme.Colors.ink2)
                    .accessibilityAddTraits(.isHeader)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(model.content.inspireMe) { card in
                            InspireCardView(card: card, width: isShort ? 190 : 200, imageHeight: isShort ? 96 : 104) {
                                withAnimation(Theme.Motion.select) { model.choose(prompt: card.prompt) }
                            }
                            .riseIn(order: 1)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                }
                .contentMargins(.leading, leadingBleed, for: .scrollContent)
                .contentMargins(.trailing, trailingBleed, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .clipped()
                .padding(.leading, -leadingBleed)
                .padding(.trailing, -trailingBleed)
            }

            PromptChipList(model: model)
        }
    }
}

// MARK: - Regular width

/// Split arrangement: chat + composer in one pane, context in the other.
/// Side by side, the chat leads. Stacked (tabletop), the context sits on the
/// upright half and the chat on the flat half.
private struct ConciergeRegularLayout: View {
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let model: ConciergeModel

    var body: some View {
        GeometryReader { proxy in
            let isSideBySide = proxy.size.width >= proxy.size.height
            let hasTopBar = toolbarVerticalEdge == nil
            let panes = SplitPaneInsets(safeArea: proxy.safeAreaInsets)

            ArrangementView {
                if isSideBySide {
                    ConciergeChatPane(model: model)
                        .splitPanePadding(panes, position: .first)
                        .splitArrangementLayoutRatio(idealHorizontal: 0.53)
                } else {
                    ConciergeContextPane(model: model, insets: panes, position: .first)
                        .splitArrangementLayoutRatio(idealVertical: 0.48)
                }
            } secondary: {
                if isSideBySide {
                    ConciergeContextPane(model: model, insets: panes, position: .second)
                } else {
                    ConciergeChatPane(model: model)
                        .splitPanePadding(panes, position: .second)
                }
            }
            .arrangementViewStyle(.split)
            .conciergeTitle(isShown: hasTopBar)
        }
    }
}

/// Chat and composer.
private struct ConciergeChatPane: View {
    @Environment(\.splitArrangementAxis) private var axis
    /// Non-nil where the system moves the toolbar to a side bar (iPhone Duo).
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let model: ConciergeModel

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 12) {
            if model.stage == .start {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ConciergeGreeting(model: model, style: .largeTitle)
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("TRY ASKING")
                                .textStyle(.caps, color: Theme.Colors.ink2)
                                .accessibilityAddTraits(.isHeader)
                            PromptChipList(model: model)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .frame(maxHeight: .infinity, alignment: .top)

                DisclosureCard(text: model.content.disclosure)
            } else {
                // A top bar shows the title; a side bar has no row for it.
                if toolbarVerticalEdge != nil {
                    ConciergePageTitle()
                }
                ScrollView {
                    ConciergeThread(model: model, showsPickCards: false,
                                    usesReadyLine: axis != .vertical,
                                    userBubbleWidth: axis == .vertical ? 360 : 320,
                                    conciergeBubbleWidth: axis == .vertical ? 380 : 340,
                                    showsInspireFlights: axis == .vertical)
                        .padding(.vertical, 2)
                }
                .defaultScrollAnchor(model.stage == .inspired && axis == .vertical ? .top : .bottom)
                // A thread shorter than the pane starts at its top, with no gap above it.
                .defaultScrollAnchor(.top, for: .alignment)
                .scrollIndicators(.hidden)
            }

            ComposerBar(text: $model.draft) {
                withAnimation(Theme.Motion.select) { model.submitDraft() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Inspire me → trip brief → picks.
private struct ConciergeContextPane: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.splitArrangementAxis) private var axis
    let model: ConciergeModel
    let insets: SplitPaneInsets
    let position: SplitPaneInsets.Position

    private var isStacked: Bool { axis == .vertical }

    var body: some View {
        ScrollView {
            Group {
                switch model.stage {
                case .start:
                    inspire
                case .questions:
                    TripBriefPanel(model: model)
                case .picks:
                    picks
                case .inspired:
                    inspired
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .splitPanePadding(insets, position: position)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    private var inspire: some View {
        VStack(alignment: .leading, spacing: 12) {
            paneTitle("Inspire me", "Ideas to get you started")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: isStacked ? 4 : 2), spacing: 12) {
                ForEach(model.content.inspireMe) { card in
                    InspireCardView(card: card, imageHeight: 120) {
                        withAnimation(Theme.Motion.select) { model.choose(prompt: card.prompt) }
                    }
                    .riseIn(order: 1)
                }
            }
        }
    }

    /// Trip, hotels and flights for you; stacked, the flights move under the thread.
    private var inspired: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let result = model.inspireResult {
                InspirePicks(result: result, showsMoreHotels: model.showsMoreHotels,
                             style: isStacked ? .upright : .pane)
            } else {
                TripSkeletonCard()
                    .accessibilityLabel("Finding ideas for you")
            }
        }
    }

    private var picks: some View {
        VStack(alignment: .leading, spacing: 12) {
            paneTitle("Picks for you", model.picksSubtitle)
            if model.revealedLines >= 2 {
                // An even number of columns, so nothing straddles the fold when stacked.
                let layout = isStacked
                    ? AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                    : AnyLayout(VStackLayout(spacing: 12))
                layout {
                    ForEach(Array(model.picks.enumerated()), id: \.element.id) { index, pick in
                        PickCardLarge(pick: pick, reason: model.reason(for: pick), imageHeight: isStacked ? 100 : 110) {
                            store.open(pick)
                        }
                        .riseIn(order: index + 1)
                    }
                }
            } else {
                TripSkeletonCard()
                    .accessibilityLabel("Finding your picks")
            }
        }
    }

    private func paneTitle(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textStyle(.section)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
    }
}

// MARK: - Previews

private func conciergePreview(_ stage: ConciergeModel.Stage) -> some View {
    let store = LifestyleStore.preview()
    if stage >= .questions { store.concierge.choose(prompt: store.content.concierge.promptChips[0]) }
    if stage >= .picks { store.concierge.showPicks() }
    store.path = [.concierge]
    return LifestyleRootView(store: store)
}

#Preview("Compact · start") { conciergePreview(.start) }
#Preview("Compact · questions") { conciergePreview(.questions) }
#Preview("Compact · picks") { conciergePreview(.picks) }

#Preview("Regular · start", traits: .landscapeLeft) {
    conciergePreview(.start).environment(\.horizontalSizeClass, .regular)
}

#Preview("Regular · questions", traits: .landscapeLeft) {
    conciergePreview(.questions).environment(\.horizontalSizeClass, .regular)
}

#Preview("Regular · picks", traits: .landscapeLeft) {
    conciergePreview(.picks).environment(\.horizontalSizeClass, .regular)
}
