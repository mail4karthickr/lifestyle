//
//  CarouselViews.swift
//  Lifestyle · Travel and Dining carousels, their skeleton, and the coming-soon card
//

import SwiftUI

/// Card sizes for the carousel. They differ per layout (Day 1 spec, section 4).
struct CarouselMetrics: Equatable {
    var travelCardWidth: CGFloat
    var imageHeight: CGFloat
    /// How far the scroller runs past the content column on each side.
    var leadingBleed: CGFloat = 0
    var trailingBleed: CGFloat = 0

    /// Dining cards are 10pt wider than travel cards.
    var diningCardWidth: CGFloat { travelCardWidth + 10 }
}

/// The carousel area under the tabs. Shows whatever the selected tab and load state call for.
struct LandingCarousel: View {
    let tab: CategoryTab
    let state: LoadState<CarouselContent>
    let metrics: CarouselMetrics
    @Binding var position: String?
    var onSelectTravel: (TravelCard) -> Void
    var onSelectDining: (DiningEvent) -> Void
    var onRetry: () -> Void

    /// Text block under a travel card's image: the coming-soon card matches it.
    @ScaledMetric(relativeTo: .headline) private var captionHeight: CGFloat = 62

    var body: some View {
        if !tab.inPOC {
            ComingSoonCard(title: "\(tab.label) is coming soon")
                .frame(height: metrics.imageHeight + captionHeight)
                .padding(.top, 2)
                .padding(.bottom, 8)
        } else {
            switch state {
            case .loading:
                scroller(position: .constant(nil)) {
                    ForEach(0..<3, id: \.self) { _ in
                        CarouselSkeletonCard(width: metrics.travelCardWidth, imageHeight: metrics.imageHeight)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading \(tab.label)")
            case .failed:
                SectionErrorCard(title: "Couldn't load \(tab.label)",
                                 message: "Everything else on this page is up to date.",
                                 onRetry: onRetry)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
            case .loaded(let content):
                if tab.id == CategoryTab.diningID {
                    scroller(position: $position) {
                        ForEach(Array(content.diningEvents.enumerated()), id: \.element.id) { index, event in
                            DiningEventCard(event: event, width: metrics.diningCardWidth, imageHeight: metrics.imageHeight) {
                                onSelectDining(event)
                            }
                            .riseIn(order: index)
                        }
                    }
                } else {
                    scroller(position: $position) {
                        ForEach(Array(content.travelCards.enumerated()), id: \.element.id) { index, card in
                            TravelCardView(card: card, width: metrics.travelCardWidth, imageHeight: metrics.imageHeight) {
                                onSelectTravel(card)
                            }
                            .riseIn(order: index)
                        }
                    }
                }
            }
        }
    }

    /// Horizontal, snapping scroller that peeks the next card.
    private func scroller(position: Binding<String?>, @ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                content()
            }
            .scrollTargetLayout()
            .padding(.top, 2)
            .padding(.bottom, 14)
        }
        .contentMargins(.leading, metrics.leadingBleed, for: .scrollContent)
        .contentMargins(.trailing, max(metrics.trailingBleed, 0), for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: position, anchor: .leading)
        .scrollIndicators(.hidden)
        .clipped()
        .padding(.leading, -metrics.leadingBleed)
        .padding(.trailing, -metrics.trailingBleed)
        // The room the cards' shadows take below them.
        .padding(.bottom, -6)
    }
}

// MARK: - Cards

/// Travel card: image + title + subtitle.
struct TravelCardView: View {
    let card: TravelCard
    var width: CGFloat
    var imageHeight: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CardImage(name: card.imageName, height: imageHeight)
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.title)
                        .textStyle(.headline)
                    Text(card.subtitle)
                        .textStyle(.footnote, color: Theme.Colors.muted)
                }
                .lineLimit(1)
                .padding(.top, 10)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width)
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }
}

/// Dining event card: image with date and menu tags, then name, cuisine, chef and venue.
struct DiningEventCard: View {
    let event: DiningEvent
    var width: CGFloat
    var imageHeight: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CardImage(name: event.imageName, height: imageHeight)
                    .overlay(alignment: .topLeading) {
                        ImageTag(symbol: "calendar", text: event.date).padding(8)
                    }
                    .overlay(alignment: .bottomLeading) {
                        ImageTag(symbol: "doc.plaintext", text: event.menu).padding(8)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(event.name)
                        .textStyle(.headline)
                    Text(event.cuisineLine)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                    HStack(spacing: 4) {
                        Glyph(shape: PinShape(), size: 14)
                            .foregroundStyle(Theme.Colors.muted)
                        Text(event.locationLine)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                }
                .lineLimit(1)
                .padding(.top, 10)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width)
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.name), \(event.date), \(event.menu). \(event.cuisineLine). \(event.locationLine)")
    }
}

/// Small glass pill over an image: a date or a menu.
struct ImageTag: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            SymbolIcon(name: symbol, size: 11, weight: .bold)
            Text(text)
                .textStyle(.footnoteEmphasis)
                .lineLimit(1)
        }
        .foregroundStyle(Theme.Colors.ink)
        .padding(.horizontal, 10)
        .frame(minHeight: Theme.Size.imageTag)
        .glassTag()
    }
}

/// An image that fills a fixed height and whatever width it is given.
struct CardImage: View {
    let name: String
    var height: CGFloat

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(name)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Skeleton, coming soon, error

struct CarouselSkeletonCard: View {
    var width: CGFloat
    var imageHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmerBlock(cornerRadius: 0).frame(height: imageHeight)
            VStack(alignment: .leading, spacing: 9) {
                ShimmerBlock().frame(width: width * 0.62, height: 14)
                ShimmerBlock(cornerRadius: 6).frame(width: width * 0.42, height: 11)
            }
            .padding(.top, 12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(width: width, alignment: .leading)
        .cardSurface()
    }
}

/// Entertainment and Exclusives are display only in the POC.
struct ComingSoonCard: View {
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            NoteIcon(fill: Theme.Colors.tintPurple, foreground: Theme.Colors.purple) {
                Glyph.sparkle(22, lineWidth: 1.9)
            }
            Text(title)
                .textStyle(.bodyEmphasis)
            Text("Explore Travel and Dining for now.")
                .textStyle(.footnote, color: Theme.Colors.ink2)
        }
        .multilineTextAlignment(.center)
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardSurface()
        .riseIn()
        .accessibilityElement(children: .combine)
    }
}

/// A section's own error, with a way to try again. Never blocks the rest of the page.
struct SectionErrorCard: View {
    let title: String
    let message: String
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                NoteIcon(fill: Theme.Colors.tintRed, foreground: Theme.Colors.red) {
                    SymbolIcon(name: "info.circle", size: 20)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .textStyle(.bodyEmphasis)
                    Text(message)
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)

            Button("Try again", action: onRetry)
                .buttonStyle(OutlineButtonStyle(horizontalPadding: 18))
                .padding(.leading, 56)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

#Preview("Carousel states") {
    let content = LifestyleContent.sample
    let metrics = CarouselMetrics(travelCardWidth: 260, imageHeight: 150, leadingBleed: 16, trailingBleed: 16)
    return ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(content.tabs) { tab in
                LandingCarousel(tab: tab, state: .loaded(content.carousel), metrics: metrics,
                                position: .constant(nil), onSelectTravel: { _ in }, onSelectDining: { _ in }, onRetry: {})
            }
            LandingCarousel(tab: content.tabs[0], state: .loading, metrics: metrics,
                            position: .constant(nil), onSelectTravel: { _ in }, onSelectDining: { _ in }, onRetry: {})
            LandingCarousel(tab: content.tabs[0], state: .failed, metrics: metrics,
                            position: .constant(nil), onSelectTravel: { _ in }, onSelectDining: { _ in }, onRetry: {})
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
