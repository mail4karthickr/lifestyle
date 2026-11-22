//
//  HeroView.swift
//  Lifestyle · points pill and hero (points + card value prop)
//

import SwiftUI

// MARK: - Header

/// Points pill: yellow coin + balance. Shows a skeleton while rewards load.
struct PointsPill: View {
    let state: LoadState<Rewards>

    var body: some View {
        HStack(spacing: 8) {
            PointsCoin(size: Theme.Size.coinLarge, starSize: 15)
            switch state {
            case .loaded(let rewards):
                Text(rewards.pointsText)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            case .loading:
                ShimmerBlock().frame(width: 64, height: 14)
            case .failed:
                Text("— pts")
                    .textStyle(.subheadEmphasis, color: Theme.Colors.muted)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .frame(minHeight: Theme.Size.pill)
        .floatingGlass(tint: Theme.Colors.glassFillLight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch state {
        case .loaded(let rewards): "Points balance, \(rewards.pointsText)"
        case .loading: "Points balance, loading"
        case .failed: "Points balance unavailable"
        }
    }
}

struct PointsCoin: View {
    var size: CGFloat = Theme.Size.coin
    var starSize: CGFloat = 14

    var body: some View {
        SymbolIcon(name: "star", size: starSize, weight: .semibold)
            .foregroundStyle(Theme.Colors.ink)
            .frame(width: size, height: size)
            .background(Theme.Colors.yellow, in: Circle())
    }
}

// MARK: - Hero

struct HeroView: View {

    enum Layout: Equatable {
        /// Runs edge to edge and under the bars; the value panel keeps to the content insets.
        case fullBleed(leading: CGFloat, trailing: CGFloat)
        /// A rounded card inside a pane.
        case card
    }

    let customer: Customer
    let rewards: LoadState<Rewards>
    var layout: Layout
    var height: CGFloat
    var onRetry: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            HeroValuePanel(customer: customer, rewards: rewards, onRetry: onRetry)
                .padding(panelInsets)
                .riseIn()
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .bottom)
        .background {
            Image("beach")
                .resizable()
                .scaledToFill()
                .accessibilityLabel("Beach at sunrise")
        }
        .overlay(alignment: .top) {
            if case .fullBleed = layout {
                LinearGradient(colors: [Theme.Colors.heroScrim, Theme.Colors.heroScrim.opacity(0)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(clipShape)
        .shadow(color: layout == .card ? Theme.Colors.ink2.opacity(0.16) : .clear, radius: 15, x: 0, y: 12)
    }

    private var panelInsets: EdgeInsets {
        switch layout {
        case .fullBleed(let leading, let trailing):
            EdgeInsets(top: 0, leading: leading, bottom: 12, trailing: trailing)
        case .card:
            EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        }
    }

    private var clipShape: UnevenRoundedRectangle {
        switch layout {
        case .fullBleed:
            UnevenRoundedRectangle(bottomLeadingRadius: Theme.Radius.heroBleed,
                                   bottomTrailingRadius: Theme.Radius.heroBleed, style: .continuous)
        case .card:
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: Theme.Radius.heroPane, bottomLeading: Theme.Radius.heroPane,
                bottomTrailing: Theme.Radius.heroPane, topTrailing: Theme.Radius.heroPane), style: .continuous)
        }
    }
}

/// Glass panel over the image: card art, value prop, then the points balance and its travel value.
struct HeroValuePanel: View {
    let customer: Customer
    let rewards: LoadState<Rewards>
    var onRetry: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                CardArt()
                VStack(alignment: .leading, spacing: 0) {
                    Text(customer.card.valueProp)
                        .textStyle(.cardTitle)
                    Text("with your \(customer.card.name) card")
                        .textStyle(.footnote, color: Theme.Colors.ink2)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .accessibilityElement(children: .combine)

            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(height: Theme.Size.border)

            HStack(spacing: 8) {
                PointsCoin()
                balance
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SheenSweep() }
        // The beach is bright, so more of it shows through than on other panels.
        .frostSurface(tint: Theme.Colors.frostFillLight)
    }

    @ViewBuilder
    private var balance: some View {
        switch rewards {
        case .loaded(let rewards):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(rewards.pointsText)
                    .textStyle(.headline)
                    .lineLimit(1)
                Text(rewards.travelValueText)
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        case .loading:
            HStack(spacing: 10) {
                ShimmerBlock(cornerRadius: 8).frame(width: 92, height: 16)
                ShimmerBlock(cornerRadius: 6).frame(width: 120, height: 12)
            }
            .frame(minHeight: 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading your points")
        case .failed:
            HStack(spacing: 8) {
                Text("Couldn't load your points")
                    .textStyle(.footnote, color: Theme.Colors.ink2)
                Button("Try again", action: onRetry)
                    .buttonStyle(.plain)
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                    .frame(minHeight: 22)
            }
        }
    }
}

/// Placeholder card art for the Autograph Journey card.
struct CardArt: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.cardArt, style: .continuous)
            .fill(LinearGradient(colors: Theme.Colors.cardArt, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 54, height: 35)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: Theme.Colors.cardChip, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 10, height: 8)
                    .padding(.leading, 7)
                    .padding(.top, 12)
            }
            .overlay(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.cardStripe)
                    .frame(width: 14, height: 3)
                    .padding(6)
            }
            .shadow(color: Theme.Colors.ink.opacity(0.25), radius: 5, x: 0, y: 4)
            .accessibilityHidden(true)
    }
}

#Preview("Hero · full bleed") {
    let content = LifestyleContent.sample
    return VStack {
        HeroView(customer: content.customer, rewards: .loaded(content.rewards),
                 layout: .fullBleed(leading: 16, trailing: 16), height: 300)
        Spacer()
    }
    .ignoresSafeArea()
    .background(AmbientBackground())
}

#Preview("Hero · card, loading") {
    let content = LifestyleContent.sample
    return VStack(spacing: 10) {
        PointsPill(state: .loading)
            .frame(maxWidth: .infinity, alignment: .trailing)
        HeroView(customer: content.customer, rewards: .loading, layout: .card, height: 190)
    }
    .padding(20)
    .background(AmbientBackground())
}
