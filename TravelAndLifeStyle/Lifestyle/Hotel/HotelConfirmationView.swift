//
//  HotelConfirmationView.swift
//  Lifestyle · Step 5 · booked, and added to the trip
//
//  Confirmation number, booking ID and status, the updated rewards balance, and
//  the hotel in the trip's itinerary with the flights.
//

import SwiftUI
import UIKit

struct HotelConfirmationView: View {
    @Environment(LifestyleStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let booking = store.hotel.confirmedBooking ?? store.bookings.hotelBookings.last

        Group {
            if let booking, let trip = store.bookings.trip(containing: booking.id) {
                let itinerary = store.bookings.itinerary(for: trip)
                if horizontalSizeClass == .regular {
                    // The confirmation beside the unified itinerary.
                    FlowSplit {
                        FlowPane(spacing: 12) {
                            ConfirmationSummary(booking: booking, balance: store.rewardsBalance)
                        }
                    } trailing: {
                        FlowPane(spacing: 12) {
                            TripItinerarySection(itinerary: itinerary)
                        }
                    }
                } else {
                    FlowPage {
                        ConfirmationSummary(booking: booking, balance: store.rewardsBalance)
                        AddedToTripSection(itinerary: itinerary, bookingId: booking.id)
                    }
                }
            } else {
                ContentUnavailableView("No booking yet", systemImage: "bed.double")
            }
        }
        .flowChrome(title: "You're booked")
    }
}

/// The check, "You're booked", the confirmation details and the rewards balance.
private struct ConfirmationSummary: View {
    let booking: HotelBooking
    let balance: Int

    var body: some View {
        StepHeader(step: 5)

        VStack(alignment: .leading, spacing: 8) {
            ConfirmationCheck()
            Text("You're booked")
                .textStyle(.largeTitle)
                .accessibilityAddTraits(.isHeader)
            Text("\(booking.hotelName) · \(TripCalendar.range(booking.checkIn, booking.checkOut))")
                .textStyle(.subhead, color: Theme.Colors.ink2)
        }

        VStack(spacing: 0) {
            row("Confirmation") {
                Text(booking.confirmationNumber)
                    .textStyle(.code)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
                CopyButton(text: booking.confirmationNumber)
            }
            .frame(minHeight: 52)
            Hairline()
            row("Booking ID") {
                Text(booking.aspireBookingId)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Theme.Size.touch)
            Hairline()
            row("Status") {
                Spacer(minLength: 0)
                TagPill(text: booking.status, tone: .mint, symbol: "checkmark")
            }
            .frame(minHeight: Theme.Size.touch)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 14)
        .cardSurface()

        RewardsBalanceCard(balance: balance, used: booking.tender?.points ?? 0)
    }

    private func row(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .frame(width: 110, alignment: .leading)
            value()
        }
        .accessibilityElement(children: .combine)
    }
}

/// Copies a confirmation number or reservation ID.
struct CopyButton: View {
    let text: String
    /// What is copied, as it reads in a sentence: "confirmation number", "reservation ID".
    var name = "confirmation number"
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            copied = true
            AccessibilityNotification.Announcement("\(name.prefix(1).uppercased() + name.dropFirst()) copied").post()
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                copied = false
            }
        } label: {
            SymbolIcon(name: copied ? "checkmark" : "square.on.square", size: 16, weight: .semibold)
                .foregroundStyle(copied ? Theme.Colors.green : Theme.Colors.ink)
                .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Copy \(name)")
    }
}

/// A green circle that pops in while its check draws itself.
struct ConfirmationCheck: View {
    var size: CGFloat = 64
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        Circle()
            .fill(Theme.Colors.green)
            .frame(width: size, height: size)
            .shadow(color: Theme.Colors.confirmShadow, radius: 12, x: 0, y: 10)
            .overlay {
                CheckShape()
                    .trim(from: 0, to: shown || reduceMotion ? 1 : 0)
                    .stroke(Theme.Colors.white, style: StrokeStyle(lineWidth: 4 * size / 64, lineCap: .round, lineJoin: .round))
                    .frame(width: 35 * size / 64, height: 35 * size / 64)
            }
            .scaleEffect(shown || reduceMotion ? 1 : 0.7)
            .onAppear {
                guard !shown else { return }
                withAnimation(.spring(duration: 0.5, bounce: 0.4)) { shown = true }
            }
            .animation(.easeOut(duration: 0.7).delay(0.35), value: shown)
            .accessibilityHidden(true)
    }
}
