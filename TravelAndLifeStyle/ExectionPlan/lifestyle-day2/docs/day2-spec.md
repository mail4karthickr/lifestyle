# Lifestyle · Day 2 spec — Book a hotel

Let the customer choose a hotel room and rate, reprice it, pay with card, points or both, and add the confirmed hotel to the existing trip itinerary.

Target screens: `design/screens/day2/` (PNG, 2x). The same screens as HTML with exact values: `design/artboards/day2/`. Content and mock API responses: `docs/sample-data-day2.json`. Decisions and the original requirements: `docs/day2-notes.md`. Day 1's tokens, materials and components (`docs/day1-spec.md`) still apply; this spec only adds what's new.

## 1. Flow

One decision per screen on compact width: "One decision at a time, with only the details that help you make it."

| Step (progress bar) | Screen | Decision | Screenshots |
|---|---|---|---|
| 1 Hotel | Search | where, when, who | D2-iPhone-1-Search, D2-Closed-1-Search, D2-Open-1-Search |
| 1 Hotel | Results (+ Filters sheet) | which hotel | D2-iPhone-2-Results, D2-iPhone-2b-Filters, D2-Closed-2-Results, D2-Open-2-Results, D2-Book-Results |
| 1 Hotel | Hotel details | is this the one | D2-iPhone-3-Details, D2-Closed-3-Details (on the open display it's the trailing pane of Results) |
| 2 Room | Room + rate | exactly one room and rate | D2-iPhone-4-Rooms, D2-Closed-4-Rooms, D2-Open-4-Rooms |
| 3 Pay | Reprice + pay | accept any change; how to pay | D2-iPhone-5-Checkout, D2-Closed-5-Checkout, D2-Closed-5b-Checkout-Scrolled, D2-Open-5-Checkout, D2-Tabletop-Checkout |
| 4 Review | Review and book | confirm | D2-iPhone-6-Review, D2-Closed-6-Review, D2-Open-6-Review |
| 4 Review | Booking in progress | — (repeat taps blocked) | D2-iPhone-6b-Booking, D2-Closed-6b-Booking, D2-Open-6b-Booking |
| 5 Done | Confirmed | — | D2-iPhone-7-Confirmed, D2-Closed-7-Confirmed, D2-Open-7-Confirmed |
| 5 Done | Itinerary | — (display only) | D2-iPhone-8-Itinerary, D2-Closed-8-Itinerary, D2-Open-9-Itinerary (also the trailing pane of D2-Open-7-Confirmed) |
| After booking | Home page, My plans shows the trip | open the trip | D2-iPhone-9-Home-After-Booking, D2-Closed-9-Home-After-Booking, D2-Open-8-Home-After-Booking |

Entry points from Day 1:
- Book now → Hotels, and the Travel carousel's Caribbean Beach Hotel / Alpine Adventure → Search (prefilled from the trip; the carousel cards preset the destination).
- Concierge pick "Hotel Solenne" → Hotel details directly, with trip dates and travelers carried over and the hotel ID kept.
- Close (×) leaves the flow and returns to the Lifestyle landing page; Back goes one step back and keeps every choice.

Where the customer sees the itinerary:
- Right after booking: **View itinerary** on the confirmation (compact), or the itinerary pane beside the confirmation (open display).
- Any time later: Lifestyle home → **My plans** → the trip card ("Your trip in Houston", status tiles Stay ✓ Travel ✓, "Hotel added" tag) → itinerary. Day 1 sends this tap to My Trip (Day 4); until Day 4 exists, open the Day 2 itinerary view, which Day 4 will expand.
- Back from the itinerary returns to wherever it was opened from (confirmation or home).

## 2. Layout per device and pose

- **Compact (iPhone, Duo closed)**: one screen per decision, five-step progress bar at the top, sticky glass action bar at the bottom (summary on the left, primary button on the right).
- **Toolbar**: Back first, then Close, as standard toolbar items (Labels with SF Symbols) so iPhone Duo puts them at the top of the side bar. Filters and sort stay above the results they affect (HIG: keep controls near their content).
- **Open, landscape (split arrangement)**: each step pairs the decision with the next level of detail:
  - Search + "Your trip in Houston" (flights, with an empty slot where the hotel will go)
  - Results + hotel details (selected card outlined in purple)
  - Room list + live "Your stay" summary with Continue
  - Payment controls + live order summary (points/card split bar) with Continue
  - Review details + money/tender + Confirm (booking progress replaces the confirm bar)
  - Confirmation + the unified itinerary
  - Itinerary (opened from My plans) + the selected booking's details: confirmation, check-in/out, room, guests, cancellation, payment
- **Book pose**: Results + details as two equal panes mirrored around the fold; nothing in the folding region.
- **Tabletop (portrait, horizontal bars)**: checkout with the price check and totals on the upright half; tender selector, points control and Continue on the flat half.
- Keep state across size changes and poses: selected hotel, room/rate, points split, acceptance.

## 3. New components

- **Progress bar**: 5 segments (Hotel, Room, Pay, Review, Done), purple for done/current, caption "Step n of 5 · Name".
- **Trip chip**: calendar icon · "Wed, Dec 30 – Sat, Jan 2" / "3 nights · 2 guests · 1 room" · "From your trip" tag (or Edit link on Results).
- **Search form**: grouped glass card with Destination, Dates (tag "From your trip"), Guests and Rooms steppers (44pt buttons; disabled at limits; rooms ≤ guests). Note: dates and travelers come from the trip; limits come from Aspire.
- **Hotel card**: 92pt image · name · neighborhood · distance · rating (star) · "Free cancellation" mint tag or "Non-refundable rates" · price per night + points per night.
- **Filter chips**: Filters (opens sheet) · Brand · Price · Rating · Amenities · Distance · Accessibility. **Sort**: segmented Recommended / Price / Rating with a caption ("Sorted by relevance", "Lowest price first", "Highest rated first").
- **Filters sheet**: sort, price range slider, guest rating, brand, amenities, distance from (City center, Your dinner, Airport), accessibility; footer "Show N hotels".
- **Gallery**: full-bleed photo (under the Duo side bar), "1 / 8 photos" tag, page dots.
- **Amenity grid** (2 columns), **Nearby** list (Osteria Lume 6-min walk links Day 3).
- **Room card**: image · name · beds/occupancy/size · features; **rate rows** (radio): rate name, cancellation policy (green when free, grey when non-refundable), "+ $X taxes and fees", price per night, "per night", points per night.
- **Stay bar / Your stay pane**: selected room · rate · total incl. taxes and fees · Continue.
- **Reprice card** states: Checking (spinner), Price changed (amber; diff rows for nightly rate, room, cancellation; "I accept the new total" checkbox), No change (mint), Room unavailable (red tint; "Choose another room").
- **Pay controls**: segmented Card / Points / Points + card (Points disabled with a reason when the balance is short); points card with −/+ (1,000 steps), slider (100-point steps), "= $100.00", "100 points = $1", "2,450 pts left after booking"; split tiles (Points $ / Card $); card picker (saved card, "Use another card"); price breakdown.
- **Order summary** (open display): breakdown, points/card split bar, Continue.
- **Review**: hotel row, Dates, Room, Guests, Cancellation; money block with tender lines; "Confirm and book" with "$795.05 + 10,000 pts · Charged when you confirm".
- **Booking panel**: three steps (Price and room confirmed → Points applied → Confirming with the hotel), each check / spinner / waiting; disabled "Booking…" button.
- **Confirmation**: animated check, "You're booked", confirmation number (copy), Booking ID, status tag, rewards balance card, "Added to your trip".
- **Itinerary timeline**: day headers; flight, check-in (outlined, "Just added"), check-out, flight; status tiles (Stay ✓ Travel ✓); "Display only" note.

## 4. Behavior and rules

Search
- Capture destination, dates, guests, rooms. Prefill from the existing trip. Enforce Aspire's limits (designs use 8 guests / 4 rooms as placeholders). No group bookings.

Results
- Live Aspire data (mocked): first 10 hotels, sorted by relevance by default. Filters: brand, price, rating, amenities, distance from, accessibility. Sort: Recommended, Price, Rating (POC only). Show a count and the active sort.

Hotel details
- Name, address, photos, amenities, ratings. Carry over trip dates and travelers. Keep the hotel ID.

Room + rate
- Show room types, beds, occupancy, and every rate with cash price, points price, taxes and fees, and the cancellation policy returned by the API — before selection.
- Exactly one room + rate selected; keep the room and rate IDs; show the selected-stay summary.

Reprice + pay
- On entering checkout, reprice and recheck availability (show Checking).
- If price, room or cancellation terms changed, show what changed (old → new) and require "I accept the new total" before Continue is enabled. If unavailable, send the customer back to rooms.
- Show the rewards balance. Tender: card, points, or points + card. 100 points = $1. The customer picks the points; the card covers the remainder. Points can't exceed the balance or the total. Recalculate the split whenever points change. Card entry is simulated; no live charge.

Review and submit
- Show hotel, dates, room, guests, price breakdown and tender. Require an explicit tap on "Confirm and book".
- Submit to Aspire (mock) with an idempotency key generated when the review screen opens; Aspire triggers the loyalty order.
- Show the in-progress panel immediately and disable the confirm control; ignore repeat taps; a retry after a failure reuses the same key so no duplicate booking is created.

Store and link
- Store: Aspire booking ID, confirmation number, status, rate ID, cancellation terms, amounts, payment (points, card amount, last 4), timestamp, customer ID.
- Link the booking to the existing trip ID; do not create a new trip. The trip and its flights are seeded for the demo (flight booking isn't in the POC).

Itinerary
- The itinerary is not stored. It's a view built on each load from the booking records linked to the trip ID (the seeded flights + this hotel booking; Day 3 adds dining), sorted by date and time. Day 4 reuses the same query for My reservations.
- Show the hotel in the unified itinerary with the flights: hotel, dates, room, guests, confirmation number. Show the updated rewards balance. Display only (no edit/cancel).

## 5. Money (mock numbers)

| | |
|---|---|
| Rate before reprice | Deluxe King · Flexible · $250/night × 3 = $750.00 + $127.50 taxes and fees = **$877.50** (87,750 pts) |
| After reprice | $255/night × 3 = $765.00 + $130.05 = **$895.05** (89,505 pts) |
| Balance | 12,450 pts → Points only disabled ("Points only needs 89,505 pts. You have 12,450 pts.") |
| Default split | 10,000 pts = $100.00 + card $795.05 |
| After booking | 2,450 pts |

Taxes in mocks: 17% of the room subtotal, rounded to the cent. Points = dollars × 100.

## 6. Suggested models and mock service

```swift
struct HotelSearch { var destination: String; var checkIn: Date; var checkOut: Date; var adults: Int; var rooms: Int }
struct HotelSummary: Identifiable { let id: String; let name, neighborhood: String; let distanceMi, rating: Double; let cashPerNight, pointsPerNight: Int; let freeCancellation: Bool }
struct Rate: Identifiable { let id: String; let name: String; let cashPerNight: Decimal; let pointsPerNight: Int; let taxesAndFeesTotal: Decimal; let refundable: Bool; let cancellationPolicy: String }
struct RoomType: Identifiable { let id: String; let name, beds: String; let sleeps, sizeSqFt: Int; let rates: [Rate] }
enum RepriceResult { case unchanged(total: Decimal); case changed(old: Decimal, new: Decimal, changes: Set<Change>); case unavailable }
struct Tender { var points: Int; var cardAmount: Decimal }
struct HotelBooking { let aspireBookingId, confirmationNumber: String; let status: String; let rateId: String; let cancellationTerms: String; let total: Decimal; let tender: Tender; let timestamp: Date; let tripId: String }
protocol AspireService {
  func search(_ s: HotelSearch) async throws -> [HotelSummary]
  func details(hotelId: String) async throws -> HotelDetails
  func rooms(hotelId: String, search: HotelSearch) async throws -> [RoomType]
  func reprice(rateId: String) async throws -> RepriceResult
  func book(rateId: String, tender: Tender, tripId: String, idempotencyKey: UUID) async throws -> HotelBooking
}
```
The mock reads `sample-data-day2.json`, adds delays, and has a scenario switch for reprice (Price changed / No change / Room unavailable) and booking failure, so every state can be demoed.

## 7. Motion and accessibility

- Rate selection, chips and tabs cross-fade (0.25s); the stay bar total updates as the selection changes.
- Booking steps check off with a pop; the confirmation check draws itself. Honor Reduce Motion.
- Radio rows and checkboxes expose selected state; the disabled Points option and Continue explain why (the note is read by VoiceOver); amounts read as currency.

## 8. Day 2 is complete when

The hotel is repriced, booked with card / points / both, linked to the existing trip ID, and shown in the itinerary; a repeat submission creates no duplicates.

Not included: real card processing, post-booking changes or cancellation, refunds, group rooms, servicing emails.
