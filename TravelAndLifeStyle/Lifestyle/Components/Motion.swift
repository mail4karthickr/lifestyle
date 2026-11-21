//
//  Motion.swift
//  Lifestyle · subtle motion (Day 1 spec, section 7). All of it honours Reduce Motion.
//

import SwiftUI

// MARK: - Rise in

/// Sections rise 12pt and fade up from 55% as they load, staggered by ~150ms.
private struct RiseIn: ViewModifier {
    let order: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : Theme.Motion.riseOpacity)
            .offset(y: shown || reduceMotion ? 0 : Theme.Motion.riseOffset)
            .onAppear {
                guard !shown else { return }
                withAnimation(Theme.Motion.rise.delay(Double(order) * Theme.Motion.stagger)) {
                    shown = true
                }
            }
    }
}

extension View {
    func riseIn(order: Int = 0) -> some View { modifier(RiseIn(order: order)) }
}

// MARK: - Shimmer

/// A skeleton block: a soft highlight that sweeps across.
struct ShimmerBlock: View {
    var cornerRadius: CGFloat = 7
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.Colors.shimmerBase)
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [Theme.Colors.shimmerPeak.opacity(0), Theme.Colors.shimmerPeak, Theme.Colors.shimmerPeak.opacity(0)],
                        startPoint: .leading, endPoint: .trailing)
                        .frame(width: max(width, 80))
                        .offset(x: (1 - 2 * phase) * max(width, 80))
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .opacity(reduceMotion ? 0 : 1)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: Theme.Motion.shimmerPeriod).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Sheen

/// A slow highlight that sweeps the hero value panel every ~6s.
struct SheenSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweeping = false

    var body: some View {
        GeometryReader { geo in
            let band = geo.size.width * 0.34
            LinearGradient(
                colors: [Theme.Colors.sheen.opacity(0), Theme.Colors.sheen, Theme.Colors.sheen.opacity(0)],
                startPoint: .leading, endPoint: .trailing)
                .frame(width: band)
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.32, d: 1, tx: 0, ty: 0))
                .offset(x: sweeping ? band * 3.6 : -band * 1.6)
        }
        .opacity(reduceMotion ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            let sweep = Theme.Motion.sheenPeriod * 0.55
            withAnimation(.easeInOut(duration: sweep)
                .delay(Theme.Motion.sheenPeriod - sweep)
                .repeatForever(autoreverses: false)) {
                sweeping = true
            }
        }
    }
}

// MARK: - Typing indicator

/// Three dots that blink in sequence while Concierge "types".
struct TypingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blinking = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.Colors.muted)
                    .frame(width: 7, height: 7)
                    .opacity(blinking || reduceMotion ? 1 : 0.3)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever().delay(Double(index) * 0.2),
                        value: blinking)
            }
        }
        .frame(height: 22)
        .onAppear { blinking = true }
        .accessibilityLabel("Fargo Concierge is typing")
    }
}
