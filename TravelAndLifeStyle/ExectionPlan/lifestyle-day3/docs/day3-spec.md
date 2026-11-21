# Lifestyle · Day 3 spec — Reserve a table

One static restaurant in Houston (Osteria Lume) on one date (Fri, Jan 1, 2027). The customer picks a time that fits their party, adds details, pays a $100-per-person deposit with points, card or both, and the dinner joins the Houston trip itinerary. No restaurant API, and no table is really held.

Target screens: `design/screens/day3/` (PNG, 2x). The same screens as HTML with exact values: `design/artboards/day3/`. Content, seed inventory and mock responses: `docs/sample-data-day3.json`. Decisions and the original requirements: `docs/day3-notes.md`. Day 1's tokens, materials and components (`docs/day1-spec.md`) and Day 2's action bar, pay controls, booking panel and timeline (`docs/day2-spec.md`) still apply; this spec only adds what's new.

## 1. Flow

| Step (progress bar) | Screen | Decision | Screenshots |
|---|---|---|---|
| — | Restaurant | is this the place | D3-iPhone-1-Restaurant, D3-Closed-1-Restaurant, D3-Closed-1b-Restaurant-Scrolled, D3-Open-1-Restaurant |
| 1 Table | Choose a table | party size and start time | D3-iPhone-2-Table, D3-iPhone-2b-Table-Party-6, D3-Closed-2-Table, D3-Closed-2b-Table-Party-6, D3-Open-2-Table, D3-Book-Table, D3-Tabletop-Table |
| 2 Details | Your details | contact, accessibility, requests, dietary notes | D3-iPhone-3-Details, D3-Closed-3-Details, D3-Closed-3b-Details-Errors, D3-Open-3-Details |
| 3 Pay | Deposit | how to pay | D3-iPhone-4-Deposit, D3-Closed-4-Deposit, D3-Closed-4b-Deposit-Scrolled, D3-Open-4-Deposit |
| 4 Review | Review and reserve | agree to terms, confirm | D3-iPhone-5-Review, D3-Closed-5-Review, D3-Closed-5a-Review-Terms, D3-Open-5-Review |
| 4 Review | Reserving / payment failed | — (repeat taps blocked) | D3-iPhone-5b-Reserving, D3-Closed-5b-Reserving, D3-Closed-5c-Payment-Failed |
| Reserved | Confirmed | — | D3-iPhone-6-Confirmed, D3-Closed-6-Confirmed, D3-Open-6-Confirmed |
| Reserved | Itinerary | — (display only) | D3-iPhone-7-Itinerary, D3-Closed-7-Itinerary (trailing pane of D3-Open-6-Confirmed) |

Entry points (all open the Restaurant screen):
- Day 1: the Dining tab card "New Year's Day Chef's Table", the Concierge pick "Osteria Lume · Reserve a table", and Book now → Events.
- Day 2: Hotel details → Nearby → Osteria Lume.

Navigation: Back goes one step back and keeps every entry (party, time, details, split). Close leaves the flow and returns to the Lifestyle landing page. On the Restaurant screen Back returns to wherever it was opened from.

## 2. Layout per device and pose

- **Compact (iPhone, Duo closed)**: one decision per screen; four-segment progress bar ("Step 1 of 4 · Table" … "Reserved"); sticky glass action bar at the bottom with a summary on the left and the primary button on the right. Restaurant screen: full-bleed hero under the Duo side bar, no progress bar.
- **Duo closed**: content inset 20 leading / 84 trailing; Back and Close at the top of the side bar; text buttons stay in the content.
- **Open, landscape (split arrangement)**: the extra pane adds a level:
  - Restaurant (hero, chef, availability, nearby) + menu and Find a table
  - Table choice + live **Your table** summary (date, time, party, deposit) with Continue
  - Contact + "For the restaurant" (accessibility, requests, dietary notes) with the action bar
  - Pay controls + **Order summary** with the points/card split bar, policy and Continue
  - Review details + money, terms and Reserve (booking progress replaces the bar)
  - Confirmation + the trip itinerary with the dinner added
- **Book pose**: table choice and Your table as two equal panes mirrored around the fold (D3-Book-Table).
- **Tabletop (portrait, horizontal bars)**: restaurant and Your table on the upright half; party size, times and Continue on the flat half (D3-Tabletop-Table).
- Keep state across size changes and poses.

## 3. New components

- **Progress bar**: Day 2's bar with 4 segments: Table, Details, Pay, Review; "Reserved" when done.
- **Restaurant hero**: full-bleed image, frost tags "Fri, Jan 1 · Chef's table" and "5-course menu", soft bottom gradient.
- **Restaurant title**: name (t1), cuisine · chef, address row (pin), hours row (clock).
- **Availability card**: red calendar circle; "Available on Fri, Jan 1, 2027" / "Seatings 5:00 – 10:00 PM · parties up to 6" / "$100 per person deposit, paid when you book".
- **Menu card**: dish image, offering name + "5 courses" tag, numbered courses (dish + detail), swaps note.
- **Mini restaurant row**: thumbnail, name, "Fri, Jan 1 · 8:00 PM · 4 guests", address. Sits at the top of every step.
- **Date row**: the only date, with an "Only date" tag and "Seatings in Houston time (CT)".
- **Party stepper**: users icon, "Party size / Up to 6 guests", −/+ (44pt; disabled at 1 and 6), count.
- **Time slot** (2-column grid): time (17pt semibold) + "3 tables left" (amber text at 2 or fewer). Selected: purple fill, white text, check. Sold out: grey, time struck through, "Sold out", disabled. Above the grid: "Start time" and "3 of 4 times open". Under it: a note naming hidden times ("7:00 PM and 10:00 PM seat parties of 2 only." / "Parties of 5 or 6 sit at 6:00 PM or 9:00 PM only.") and "Tables aren't held while you check out. The count drops when a booking is confirmed."
- **Guest field**: label + Required/Optional, 44pt field (64pt text area for requests and notes); error state: red border + alert icon + message.
- **Accessibility chips**: Wheelchair access, Step-free route, Service animal, Hearing support (multi-select).
- **Overlap banner**: red tint; "You already have a table that night" + the existing reservation + "Change time".
- **Deposit card**: "Deposit due now $400.00" / "4 guests × $100.00" / points available.
- **Policy card**: green shield; the policy text; "Shown for your information; cancellations aren't available in the app yet."
- **Terms box** (Review): policy, checkbox "I agree to the deposit terms and cancellation policy" (Required to confirm), "Read the full terms" link. Reserve is disabled until it's checked ("Agree to the terms to reserve" in red under the amount).
- **Reserving panel**: Card ···· 4821 charged $300.00 → Table for 4 at 8:00 PM confirmed → 10,000 points deducted; disabled "Reserving…".
- **Payment failed panel**: "Payment didn't go through" / "No points were deducted and no table was reserved." / Change card · Try again.
- **Confirmation**: check draws in; "Your table is reserved"; Reservation ID (copy), When, Party, Status Confirmed, "Show this ID when you arrive."; rewards balance; "Added to your trip" + View itinerary.
- **Itinerary dinner item**: amber dining icon; "Dinner · Osteria Lume" / "8:00 PM · Party of 4 · Chef's table" / "Reservation RES-270101-7Q3K"; "Just added" outline after booking.
- **Trip header indicators**: Stay and Dining only, green with a check or greyed out (Day 4's rule; replace Day 2's four status tiles now).

## 4. Behavior and rules

Restaurant (step 1 in the requirements)
- One static record: name, city, chef, cuisine, menu, images, address (sample data). No restaurant API.

Choose a table
- One date only (2027-01-01). Start times hourly 5:00–10:00 PM, restaurant local time (America/Chicago).
- Party size 1–6; default to the trip's travelers (2) when opened from a trip, else 2. Designs show 4.
- Each start time has 5 tables of one size (5 & 8 PM: 4-tops; 6 & 9 PM: 6-tops; 7 & 10 PM: 2-tops).
- Show only times whose table size ≥ party. Each shows "N tables left" (5 minus confirmed bookings); 0 shows Sold out and can't be picked.
- If a party change hides the selected time, clear the selection and disable Continue.
- Tables aren't held during checkout.

Your details
- Prefill name, email and phone from the customer's profile; all three required and editable.
- Capture accessibility needs, special requests and dietary notes (optional). Don't prefill dietary notes from Day 5 preferences.
- On Continue: validate required fields (inline errors) and block a reservation that overlaps one the customer already holds (2-hour seating) with the overlap banner.
- Keep entries when the customer goes back.

Deposit
- $100 per person; show the total and the rewards balance.
- Card / Points / Points + card, 100 points = $1; points in 100-point steps, slider max = the lower of balance and deposit (rounded down to 100). Default split 10,000 pts + card. Points only is disabled with a reason when the balance is short (needs 40,000).
- Show the cancellation policy (display only).
- Card entry is simulated: saved card preselected; "Use another card" opens a simulated form.

Review and reserve
- Show restaurant, date and time, party size, accessibility needs, requests and dietary notes, guest, and price with tender.
- The terms box must be checked before Reserve works.
- On Reserve: generate an idempotency key, then in order: recheck availability, charge card (simulated), create the reservation and lower that time's count, deduct points. Show the Reserving panel and block repeat taps.
- Payment fails → nothing reserved, no points deducted, count unchanged; show Payment failed with Change card / Try again.
- Sold out by the time they confirm → nothing charged; "8:00 PM just filled up. Choose another time." and back to times.

Confirm + itinerary
- Generate a reservation ID (`RES-yymmdd-XXXX`); no restaurant is notified.
- Store customer, trip, restaurant, slot, party, points, cash, status (plus accessibility, requests, notes, createdAt).
- Link the dinner to the trip whose dates include it (trip ID when present), and show it in the itinerary with the flights and hotel: restaurant, date, time, party size, reservation ID.
- Show the confirmation with the reservation ID and the updated rewards balance.

## 5. Accessibility and motion

- Time slots are buttons with selected state; sold-out ones are disabled and read "9:00 PM, sold out". Hidden times are explained in text, not just removed.
- Errors: VoiceOver reads the message with the field; the overlap banner is announced (`role=alert`).
- The terms checkbox is a real toggle; Reserve's disabled state explains why.
- Reserving announces each step; the failed panel is announced.
- Motion: slot check pop, confirmation check draw, cards rise in; all off with Reduce Motion.

## 6. Models (suggested)

```swift
struct Restaurant: Codable { let id, name, city, address, chef, cuisine, about: String; let menu: [Course]; let timeZone: String }
struct Slot: Codable, Identifiable { let id: String /* "20:00" */; let tableSize: Int; var tablesLeft: Int }
struct Reservation: Codable {
    let reservationId: String; let customerId: String; let tripId: String?; let restaurantId: String
    let date: String; let time: String; let partySize: Int
    let accessibilityNeeds: [String]; let specialRequests: String?; let dietaryNotes: String?
    let pointsUsed: Int; let cardChargedUsd: Decimal; let status: String; let createdAt: Date
}
protocol DiningService {
    func availability(date: String, party: Int) async throws -> [Slot]
    func reserve(_ request: ReservationRequest, idempotencyKey: UUID) async throws -> Reservation   // scenario switch: success, paymentDeclined, soldOutAtConfirm, overlap
}
```

## 7. Acceptance

- [ ] The Houston restaurant shows tables left for each start time that fits the party; times that don't fit are hidden and explained; 0 left shows Sold out.
- [ ] Party of 3–4 never sees 7 PM or 10 PM; party of 5–6 sees only 6 PM and 9 PM.
- [ ] Details are prefilled; required fields are validated; an overlapping reservation is blocked; entries survive Back.
- [ ] Deposit is $100 × party; points/card split at 100 points = $1 with balance validation; the policy is shown.
- [ ] Reserve needs the terms box; repeat taps create one reservation.
- [ ] Points are deducted only after confirmation; a failed payment deducts nothing and reserves nothing.
- [ ] Booking lowers that time's open tables by one (8:00 PM goes from 2 left to 1).
- [ ] Confirmation shows the reservation ID and updated balance; the dinner appears in the Houston itinerary with the flights and hotel.
- [ ] Matches the screenshots on iPhone, Duo closed, Duo open, book and tabletop; state survives opening and closing the Duo.
