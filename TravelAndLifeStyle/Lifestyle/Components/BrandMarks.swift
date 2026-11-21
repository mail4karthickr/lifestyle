//
//  BrandMarks.swift
//  Lifestyle · the Fargo assistant icon
//
//  Drawn here from the retail app's icon (Requirements/IMG_0008), so it scales
//  to any size. Swap in the official artwork before this ships.
//

import SwiftUI

// MARK: - Fargo

/// The Fargo bubble: three round corners and a point at the bottom leading
/// corner. Proportions are measured from the retail app's icon.
struct FargoBubbleShape: InsettableShape {
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: inset, dy: inset)
        let side = min(rect.width, rect.height)
        return UnevenRoundedRectangle(
            topLeadingRadius: side * 0.46, bottomLeadingRadius: side * 0.08,
            bottomTrailingRadius: side * 0.42, topTrailingRadius: side * 0.42, style: .continuous)
            .path(in: rect)
    }

    func inset(by amount: CGFloat) -> FargoBubbleShape {
        FargoBubbleShape(inset: inset + amount)
    }
}

/// The "F": two speech bubbles, one above the other. The upper one runs
/// longer; the lower one has a tail at its bottom leading corner.
private struct FargoMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * side, y: rect.minY + y * side, width: width * side, height: height * side)
        }
        let radius = side * 0.055
        let upper = Path(roundedRect: box(0.22, 0.255, 0.54, 0.185), cornerRadius: radius, style: .continuous)
        let lowerBox = box(0.22, 0.60, 0.44, 0.185)
        let lower = Path(roundedRect: lowerBox, cornerRadius: radius, style: .continuous)
        var tail = Path()
        tail.move(to: CGPoint(x: lowerBox.minX, y: lowerBox.maxY - side * 0.07))
        tail.addLine(to: CGPoint(x: lowerBox.minX, y: lowerBox.maxY + side * 0.075))
        tail.addLine(to: CGPoint(x: lowerBox.minX + side * 0.105, y: lowerBox.maxY - side * 0.02))
        tail.closeSubpath()
        // One outline per bar, so the tail's overlap can't punch a hole in it.
        var path = upper
        path.addPath(lower.union(tail))
        return path
    }
}

/// The Fargo assistant icon: a purple bubble with an "F" made of two speech
/// bubbles. Animated, its colors drift slowly inside the bubble; nothing moves
/// or changes size. With Reduce Motion it is still.
struct FargoIcon: View {
    var size: CGFloat = Theme.Size.touch
    var isAnimated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animates: Bool { isAnimated && !reduceMotion }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animates)) { timeline in
            FargoBubbleShape()
                .fill(Self.gradient(at: animates ? timeline.date.timeIntervalSinceReferenceDate : 0))
        }
        .overlay {
            FargoMarkShape()
                .fill(Theme.Colors.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Purple at the top trailing corner, magenta at the bottom leading one,
    /// as in the retail app. Over time the middle of the mesh wanders and the
    /// edges sway, so the two colors flow into each other.
    private static func gradient(at time: TimeInterval) -> MeshGradient {
        func sway(_ speed: Double, _ phase: Double, _ amount: Double) -> Float {
            Float(0.5 + amount * sin(time * speed + phase))
        }
        let centerX = sway(0.62, 0, 0.24)
        let centerY = sway(0.47, 1.3, 0.24)
        let colors = Theme.Colors.self
        return MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [sway(0.41, 2.1, 0.14), 0], [1, 0],
                [0, sway(0.36, 0.7, 0.14)], [centerX, centerY], [1, sway(0.44, 3.4, 0.14)],
                [0, 1], [sway(0.39, 4.2, 0.14), 1], [1, 1],
            ],
            colors: [
                colors.fargoViolet, colors.fargoPurple, colors.fargoPurple,
                colors.fargoMagenta, colors.fargoViolet, colors.fargoPurple,
                colors.fargoMagenta, colors.fargoMagenta, colors.fargoViolet,
            ])
    }
}

#Preview("Brand marks") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            FargoIcon(size: 28)
            FargoIcon(size: 44, isAnimated: true)
            FargoIcon(size: 96, isAnimated: true)
        }
    }
    .padding(40)
    .background(AmbientBackground())
}
