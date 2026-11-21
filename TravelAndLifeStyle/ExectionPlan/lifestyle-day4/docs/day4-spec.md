# Lifestyle · Day 4 spec — My trips + itinerary

Once a customer has booked, the landing page shows a **My trips** section with one tile per trip. Each tile shows what's booked and opens a Concur-style itinerary. Trips are worked out from confirmed hotel (Day 2) and dining (Day 3) bookings every time the page loads.

Target screens: `design/screens/day4/` (PNG, 2x). The same screens as HTML with exact values: `design/artboards/day4/`. Bookings, rules, expected tiles and the expected itinerary: `docs/sample-data-day4.json`. Decisions and the original requirements: `docs/day4-notes.md`. Day 1's tokens, materials and components (`docs/day1-spec.md`) still apply.

## 1. Screens

| Screen | Shows | Screenshots |
|---|---|---|
| Landing · nothing booked | No My trips section at all | D4-Closed-1-Home-Nothing-Booked, D4-Tile-States (1) |
| Landing · dinner only | "Your dinner at Osteria Lume", Dining green, Stay grey | D4-Closed-2-Home-Dinner-Only, D4-Tile-States (3) |
| Landing · hotel only | "Your stay at Hotel Solenne", Stay green, Dining grey | D4-Closed-3-Home-Stay-Only, D4-Tile-States (2) |
| Landing · hotel + dinner | "Your trip in Houston", both green | D4-Closed-4-Home-Trip, D4-Tile-States (4) |
| Landing · two trips | Houston first, then "Your stay at Kesselhorn Lodge" | D4-Closed-5-Home-Two-Trips, D4-Open-1-Home-Two-Trips, D4-iPhone-1-Home-Two-Trips, D4-Tile-States (5) |
| Itinerary | Concur-style day list | D4-Closed-6-Itinerary, D4-Closed-6b-Itinerary-Scrolled, D4-iPhone-2-Itinerary, D4-Open-2-Itinerary, D4-Book-Itinerary |
| Booking details | The tapped booking (dinner shown) | D4-Closed-7-Dinner, D4-iPhone-3-Dinner (trailing pane of D4-Open-2-Itinerary) |

Navigation: tile → that trip's itinerary. Itinerary item → its booking details (compact) or the trailing pane (open display). Back returns one level. The itinerary opened from Day 2's or Day 3's confirmation ("View itinerary") is this same view.

## 2. Layout per device and pose

- **Landing, compact (iPhone, Duo closed)**: My trips is the last section, after Book now (replaces Day 1's My plans). Header "My trips" + "2 upcoming" when there's more than one.
- **Landing, open display**: My trips sits in the trailing pane under Book now (D4-Open-1-Home-Two-Trips).
- **Itinerary, compact**: full-bleed destination hero with a frost title panel (title, dates · city), then the Stay/Dining indicators, summary tags (3 nights · 1 stay · 1 dinner · 2 flights), then the days. Duo closed: hero runs under the side bar; Back sits at the top of the side bar.
- **Itinerary, open display**: compact header (thumbnail, title, dates, indicators) + day list leading; the selected booking's details trailing (selected card outlined in purple).
- **Book pose**: the same two panes, equal, mirrored around the fold (D4-Book-Itinerary).

## 3. Components

- **Trip tile**: glass card; 64pt destination image; title (17 semibold, one line); pin + destination; dates; chevron. Under it, two indicators side by side. The whole tile is one button. VoiceOver: "Your trip in Houston, Houston, TX, Dec 30, 2026 – Jan 2, 2027. Stay booked, Dining booked. Opens the itinerary".
- **Indicator**: 40pt; icon + label. Booked: mint fill, green text, green check badge. Not booked: grey fill, muted text, "Not booked". Labels: Stay, Dining.
- **Itinerary hero**: destination image; frost panel with "Your trip in Houston" (t3) and "Dec 30, 2026 – Jan 2, 2027 · Houston, TX".
- **Summary tags**: neutral tags with icons for nights, stays, dinners, flights.
- **Day header**: "Wed, Dec 30" (bold) + "Day 1 of 4" (muted). Days with nothing booked are left out.
- **Segment row**: time column ("10:15" / "AM", right-aligned), an icon on a vertical rail (purple plane, red bed, grey door, amber dining; opaque tints with a halo so the rail line doesn't show through), and a card with title, one detail line, and the confirmation or reservation number; chevron.
- **Booking details (dinner)**: image with a Confirmed tag; name + address; Reservation ID; rows for date and time, party and accessibility, requests, deposit paid, cancellation policy; "Display only" note. Hotel details reuse Day 2's booking detail (D2-Open-9-Itinerary).
- **Display-only note**: "Display only in this version: changes and cancellations aren't available yet."

## 4. Behavior and rules

Find bookings
- On every landing page load, fetch the customer's confirmed hotel and dining bookings. Nothing about a trip is stored on its own.
- Show a skeleton for the section while loading (Day 1's plan skeleton) and Day 1's "Couldn't load your plans" card on failure; the rest of the page never waits.

Trip matching
- Bookings whose date ranges overlap form one trip. A hotel covers check-in through checkout; a dinner covers its date. Check-in and checkout day count. Overlap chains (A~B, B~C → one trip).
- Seeded flights attach to the trip whose dates include them; they show in the itinerary but never affect tiles, titles or indicators.

Tile logic
- None booked: hide the section entirely. No empty tile, no prompt.
- One trip with only a hotel: "Your stay at [hotel name]". Only a dinner: "Your dinner at [restaurant name]".
- Two or more bookings with overlapping dates: one tile, "Your trip in [city of the hotel]".
- Several trips: one tile each, upcoming first (start date ascending). A dinner with no overlapping hotel gets its own tile.
- Remove a tile from the day after its end date (checkout, or the dinner date).

Tile content
- Destination and dates from booking data; image from our destination library; title per the rules; Stay and Dining indicators.

Refresh
- Rerun matching and tile logic on every load, so a new booking shows on the next load and titles change with it (dinner only → add a hotel → "Your trip in Houston").

Open trip
- Tapping a tile opens that trip's itinerary: every booked item from Day 2 and Day 3 in the trip's date range (plus the seeded flights), grouped by day, sorted by time.
- Display only: no edit, no cancel.

## 5. Accessibility and motion

- Each tile is one button with a full spoken summary (above); indicators also carry their own labels.
- Itinerary rows read "10:15 AM, Flight SFO to IAH, Coast Air 1015, arrives 4:05 PM, confirmation QX7P2M".
- Day headers are headings.
- Motion: tiles and day blocks rise in; off with Reduce Motion.

## 6. Models (suggested)

```swift
enum Booking { case hotel(HotelBooking), dining(Reservation) }
struct Trip: Identifiable {
    let id: String               // stable: earliest booking id
    let bookings: [Booking]
    var start: Date; var end: Date
    var hasStay: Bool; var hasDining: Bool
    var title: String            // rules in the spec
    var destination: String
    var imageKey: String
}
enum TripBuilder {
    static func trips(from bookings: [Booking], today: Date) -> [Trip]   // group by inclusive overlap, drop ended (end + 1 day <= today), sort by start
}
```
Keep `TripBuilder` pure and unit-test it with the five cases in the sample data (none, dinner only, hotel only, hotel + dinner, two trips) plus the removal date.

## 7. Acceptance

- [ ] Nothing booked: no My trips section.
- [ ] Hotel only → "Your stay at Hotel Solenne"; dinner only → "Your dinner at Osteria Lume"; indicators match.
- [ ] Hotel and dinner with overlapping dates show one tile, "Your trip in Houston", with destination, image, dates, and both indicators green.
- [ ] Multiple trips show as multiple tiles, upcoming first.
- [ ] A new booking appears on the next landing load, and the title updates (dinner → trip).
- [ ] A tile disappears the day after its checkout date.
- [ ] Tapping a tile opens a Concur-style itinerary listing each booked item in the date range; display only.
- [ ] Matches the screenshots on iPhone, Duo closed, Duo open and book pose.
