//
//  Glyphs.swift
//  Lifestyle · custom marks that have no SF Symbol equivalent
//
//  Paths are transcribed from the design artboards (24 × 24 view box).
//

import SwiftUI

/// Scales a 24 × 24 design path into the shape's rect.
private func designPath(in rect: CGRect, _ build: (inout Path) -> Void) -> Path {
    var path = Path()
    build(&path)
    let scale = min(rect.width, rect.height) / 24
    let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)
    return path.applying(transform)
}

/// Concierge sparkle: one large and one small four-point star.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        designPath(in: rect) { p in
            p.addLines([
                CGPoint(x: 11, y: 3), CGPoint(x: 12.9, y: 8.1), CGPoint(x: 18, y: 10),
                CGPoint(x: 12.9, y: 11.9), CGPoint(x: 11, y: 17), CGPoint(x: 9.1, y: 11.9),
                CGPoint(x: 4, y: 10), CGPoint(x: 9.1, y: 8.1),
            ])
            p.closeSubpath()
            p.addLines([
                CGPoint(x: 18.5, y: 15), CGPoint(x: 19.3, y: 17.2), CGPoint(x: 21.5, y: 18),
                CGPoint(x: 19.3, y: 18.8), CGPoint(x: 18.5, y: 21), CGPoint(x: 17.7, y: 18.8),
                CGPoint(x: 15.5, y: 18), CGPoint(x: 17.7, y: 17.2),
            ])
            p.closeSubpath()
        }
    }
}

/// Location pin with a centre dot.
struct PinShape: Shape {
    func path(in rect: CGRect) -> Path {
        designPath(in: rect) { p in
            p.move(to: CGPoint(x: 12, y: 21))
            p.addCurve(to: CGPoint(x: 5.5, y: 10), control1: CGPoint(x: 12, y: 21), control2: CGPoint(x: 5.5, y: 15))
            p.addArc(center: CGPoint(x: 12, y: 10), radius: 6.5,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addCurve(to: CGPoint(x: 12, y: 21), control1: CGPoint(x: 18.5, y: 15), control2: CGPoint(x: 12, y: 21))
            p.closeSubpath()
            p.addEllipse(in: CGRect(x: 9.6, y: 7.6, width: 4.8, height: 4.8))
        }
    }
}

/// A door with a knob: check-out.
struct DoorShape: Shape {
    func path(in rect: CGRect) -> Path {
        designPath(in: rect) { p in
            p.move(to: CGPoint(x: 5, y: 21))
            p.addLine(to: CGPoint(x: 19, y: 21))
            p.move(to: CGPoint(x: 7, y: 21))
            p.addLine(to: CGPoint(x: 7, y: 4))
            p.addQuadCurve(to: CGPoint(x: 8, y: 3), control: CGPoint(x: 7, y: 3))
            p.addLine(to: CGPoint(x: 16, y: 3))
            p.addQuadCurve(to: CGPoint(x: 17, y: 4), control: CGPoint(x: 17, y: 3))
            p.addLine(to: CGPoint(x: 17, y: 21))
            p.addEllipse(in: CGRect(x: 13.4, y: 11.4, width: 1.2, height: 1.2))
        }
    }
}

/// Checkmark, drawn as one stroke so it can animate.
struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        designPath(in: rect) { p in
            p.move(to: CGPoint(x: 5, y: 12.5))
            p.addLine(to: CGPoint(x: 9.5, y: 17))
            p.addLine(to: CGPoint(x: 19, y: 7.5))
        }
    }
}

/// A stroked glyph at a design size, with the artboards' round caps and joins.
struct Glyph<S: Shape>: View {
    let shape: S
    var size: CGFloat
    var lineWidth: CGFloat = 1.8

    var body: some View {
        shape
            .stroke(style: StrokeStyle(lineWidth: lineWidth * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

extension Glyph where S == SparkleShape {
    static func sparkle(_ size: CGFloat, lineWidth: CGFloat = 1.8) -> Glyph {
        Glyph(shape: SparkleShape(), size: size, lineWidth: lineWidth)
    }
}

/// An SF Symbol sized in points, used for the outline icons in the designs.
struct SymbolIcon: View {
    let name: String
    var size: CGFloat
    var weight: Font.Weight = .medium

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: weight))
            .accessibilityHidden(true)
    }
}
