//
//  PaymentChoosing.swift
//  Lifestyle · the points and card split shared by hotel and dining checkout
//
//  100 points = $1. The customer picks the points; the card covers the rest.
//  Points can't exceed the balance or the amount due.
//

import Foundation
import Observation

enum TenderMode: Int, CaseIterable, Identifiable {
    case card, points, pointsAndCard

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .card: "Card"
        case .points: "Points"
        case .pointsAndCard: "Points + card"
        }
    }
}

/// A checkout whose total can be paid with points, a card, or both.
protocol PaymentChoosing: AnyObject, Observable {
    /// Rewards balance available to spend.
    var balance: Int { get }
    /// What has to be paid, once it is known.
    var amountDue: Decimal? { get }
    var points: Int { get set }
    var card: PaymentCard { get set }
    /// A card entered in the simulated form.
    var otherCard: PaymentCard? { get set }
    var savedCard: PaymentCard { get }
    /// The points preselected for "Points + card".
    var defaultPoints: Int { get }
    /// Points move in steps of this size.
    var pointsStep: Int { get }
    /// Whether the most points that can be used is rounded down to a whole step.
    var roundsMaxPointsToStep: Bool { get }
}

extension PaymentChoosing {

    /// The amount due, in points.
    var amountDueInPoints: Int { amountDue?.cents ?? 0 }

    /// Points can't exceed the balance or the amount due.
    var maxPoints: Int {
        let limit = min(balance, amountDueInPoints)
        return roundsMaxPointsToStep ? limit - limit % pointsStep : limit
    }

    var canPayAllWithPoints: Bool { amountDue != nil && balance >= amountDueInPoints }

    /// "Points only needs 89,505 pts. You have 12,450 pts."
    var pointsOnlyNote: String? {
        guard amountDue != nil, !canPayAllWithPoints else { return nil }
        return "Points only needs \(amountDueInPoints.pointsText). You have \(balance.pointsText)."
    }

    func setPoints(_ value: Int) {
        let stepped = (Double(value) / Double(pointsStep)).rounded() * Double(pointsStep)
        // The top of the range may not be a whole step; allow it so points can cover the total.
        points = value >= maxPoints ? maxPoints : min(max(Int(stepped), 0), maxPoints)
    }

    func changePoints(by delta: Int) { setPoints(min(max(points + delta, 0), maxPoints)) }

    var tender: Tender? {
        guard let amountDue else { return nil }
        return Tender(points: points, cardAmount: max(amountDue - Decimal(cents: points), 0))
    }

    /// The mode follows the split: no points, all points, or both.
    var tenderMode: TenderMode {
        guard let tender else { return .pointsAndCard }
        if tender.points == 0 { return .card }
        return tender.cardAmount == 0 ? .points : .pointsAndCard
    }

    func isAvailable(_ mode: TenderMode) -> Bool { mode != .points || canPayAllWithPoints }

    func choose(_ mode: TenderMode) {
        guard isAvailable(mode) else { return }
        switch mode {
        case .card: points = 0
        case .points: points = min(balance, amountDueInPoints)
        case .pointsAndCard: points = min(defaultPoints, maxPoints)
        }
    }

    /// The default split when checkout opens.
    func applyDefaultSplit() { points = min(defaultPoints, maxPoints) }

    var pointsLeft: Int { balance - points }

    /// The share of the amount due paid with points, 0…1.
    var pointsShare: Double {
        guard amountDueInPoints > 0 else { return 0 }
        return Double(points) / Double(amountDueInPoints)
    }

    /// "$795.05" / "on card + 10,000 pts"
    var tenderSummary: (title: String, subtitle: String) {
        guard let tender else { return ("", "") }
        if tender.cardAmount > 0 {
            return (tender.cardAmount.usd,
                    tender.points > 0 ? "on card + \(tender.points.pointsText)" : "on card ···· \(card.last4)")
        }
        return (tender.points.pointsText, "Paid with points")
    }

    /// "$795.05 + 10,000 pts"
    var chargeText: String {
        guard let tender else { return "" }
        if tender.points == 0 { return tender.cardAmount.usd }
        if tender.cardAmount == 0 { return tender.points.pointsText }
        return "\(tender.cardAmount.usd) + \(tender.points.pointsText)"
    }
}
