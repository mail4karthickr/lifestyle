//
//  AmbientBackground.swift
//  Lifestyle · page background
//
//  #F4F0ED with the app's faint diagonal facets and soft yellow, red, purple
//  and magenta glows that drift slowly. The glows are what the glass cards
//  blur and tint.
//

import SwiftUI

struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(
                    colors: [Theme.Colors.backgroundTop, Theme.Colors.backgroundBottom],
                    startPoint: .top, endPoint: .bottom)

                // Diagonal facets: two page-wide squares turned 45°.
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Theme.Colors.facetLight, Theme.Colors.facetLight.opacity(0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w, height: w)
                    .rotationEffect(.degrees(45))
                    .position(x: -0.05 * w, y: 0.20 * w)

                Rectangle()
                    .fill(LinearGradient(
                        colors: [Theme.Colors.facetShade, Theme.Colors.facetShade.opacity(0)],
                        startPoint: .bottomTrailing, endPoint: .topLeading))
                    .frame(width: w, height: w)
                    .rotationEffect(.degrees(45))
                    .position(x: 1.10 * w, y: 0.30 * h + 0.5 * w)

                glow(Theme.Colors.glowYellow, diameter: 440, period: Theme.Motion.driftPeriods[0])
                    .position(x: w - 90, y: 70)
                glow(Theme.Colors.glowRed, diameter: 420, period: Theme.Motion.driftPeriods[1])
                    .position(x: 40, y: 0.34 * h + 210)
                glow(Theme.Colors.glowPurple, diameter: 520, period: Theme.Motion.driftPeriods[2])
                    .position(x: w - 110, y: h - 80)
                glow(Theme.Colors.glowMagenta, diameter: 400, period: Theme.Motion.driftPeriods[3])
                    .position(x: 0.28 * w, y: 0.70 * h)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .background(Theme.Colors.background)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            drifting = true
        }
    }

    private func glow(_ color: Color, diameter: CGFloat, period: Double) -> some View {
        Circle()
            .fill(RadialGradient(
                stops: [.init(color: color, location: 0), .init(color: color.opacity(0), location: 0.68)],
                center: .center, startRadius: 0, endRadius: diameter / 2))
            .frame(width: diameter, height: diameter)
            .scaleEffect(drifting ? 1.08 : 1)
            .offset(x: drifting ? 22 : 0, y: drifting ? -16 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: period).repeatForever(autoreverses: true),
                value: drifting)
    }
}

#Preview {
    AmbientBackground()
}
