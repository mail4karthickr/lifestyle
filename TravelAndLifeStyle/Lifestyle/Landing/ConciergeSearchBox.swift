//
//  ConciergeSearchBox.swift
//  Lifestyle · the way into Fargo Concierge from the landing page
//
//  Day 1: a search box below the hero, "What do you want to do?", that opens
//  the guided chat. It is the page's most prominent control, and it gets there
//  with light rather than weight: a slim glass pill whose edge glows in Fargo's
//  colors, turning slowly, with example requests fading through the question.
//

import SwiftUI

struct ConciergeSearchBox: View {
    /// Example requests that take turns with the question.
    var examples: [String] = []
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // The Fargo icon, with its colors drifting slowly.
                FargoIcon(size: 34, isAnimated: true)

                ConciergePromptLine(examples: examples)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SymbolIcon(name: "mic", size: 18)
                    .foregroundStyle(Theme.Colors.ink2)
                    .frame(width: 36, height: Theme.Size.touch)
            }
            .padding(.leading, 10)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .frame(minHeight: Theme.Size.conciergeBox)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .floatingGlass(tint: Theme.Colors.glassFillLight, interactive: true)
        .overlay { ConciergeAura(layer: .edge) }
        .background { ConciergeAura(layer: .glow) }
        .accessibilityLabel("Ask Fargo Concierge: what do you want to do?")
        .accessibilityHint("Opens the guided chat")
    }
}

// MARK: - Prompt

/// "What do you want to do?", with example requests fading through it one at
/// a time. The question stays longest and comes back after each example. With
/// Reduce Motion only the question shows.
private struct ConciergePromptLine: View {
    let examples: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Even steps show the question; odd steps show the next example.
    @State private var step = 0

    private var example: String? {
        guard !examples.isEmpty, !step.isMultiple(of: 2) else { return nil }
        return examples[(step / 2) % examples.count]
    }

    var body: some View {
        let example = example

        // Wraps at the largest text sizes instead of cutting the question short.
        Text(example.map { "“\($0)”" } ?? "What do you want to do?")
            .textStyle(.body, color: example == nil ? Theme.Colors.ink : Theme.Colors.ink2)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.leading)
            .id(step)
            .transition(.blurReplace)
            .accessibilityHidden(true)
            .task(id: reduceMotion) {
                guard !reduceMotion, !examples.isEmpty else {
                    step = 0
                    return
                }
                while !Task.isCancelled {
                    let stay = step.isMultiple(of: 2) ? Theme.Motion.questionPeriod : Theme.Motion.examplePeriod
                    try? await Task.sleep(for: .seconds(stay))
                    guard !Task.isCancelled else { return }
                    withAnimation(Theme.Motion.example) { step += 1 }
                }
            }
    }
}

// MARK: - Aura

/// Fargo's colors turning slowly around the box, as light rather than as a
/// border: a hairline on the edge, a soft glow just inside it, and a wider
/// glow underneath that breathes. With Reduce Motion it is all still.
private struct ConciergeAura: View {
    enum Layer { case edge, glow }

    let layer: Layer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            // Kept small: the time since 2001, in degrees, is too large to turn smoothly.
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let turn = (Theme.Motion.auraStart + time * Theme.Motion.auraSpeed).truncatingRemainder(dividingBy: 360)
            let gradient = AngularGradient(colors: Theme.Colors.aura, center: .center, angle: .degrees(turn))

            switch layer {
            case .edge:
                ZStack {
                    Capsule()
                        .strokeBorder(gradient, lineWidth: 5)
                        .blur(radius: 5)
                        .opacity(0.42)
                    Capsule()
                        .strokeBorder(gradient, lineWidth: 1.2)
                        .opacity(0.9)
                }
                .clipShape(Capsule())
            case .glow:
                Capsule()
                    .stroke(gradient, lineWidth: 10)
                    .blur(radius: 14)
                    .opacity(0.5 + 0.12 * sin(time * 1.1))
                    .offset(y: 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Concierge search box") {
    VStack(spacing: 24) {
        ConciergeSearchBox(examples: LifestyleContent.sample.concierge.inspireMe.map(\.prompt)) {}
        ConciergeSearchBox {}
    }
    .padding(16)
    .frame(maxHeight: .infinity)
    .background(AmbientBackground())
}
