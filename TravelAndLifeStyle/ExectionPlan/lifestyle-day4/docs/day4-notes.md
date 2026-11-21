# Day 4 notes — decisions and requirements

## Decisions from the design session
- Same scope as the other days: iPhone and iPhone Duo only; same tokens, materials and placeholder branding.
- The section is called **My trips** and replaces Day 1's My plans. The requirement calls it the "My Trip section"; it's plural because several tiles can show.
- Nothing booked hides the section. This replaces Day 1's "No plans yet" empty state (Day 4 leaves out empty-state prompts) and settles the open question from Day 2.
- Indicators are Stay and Dining only. Day 1's plan card and Day 2's trip header had four tiles (Stay, Travel, Dining, Experience); Day 4 leaves Travel and Experience out, so change those to the two-indicator style everywhere.
- Trip matching follows the requirement literally: overlapping dates, counting check-in and checkout day. City isn't part of the rule. In the POC every dinner is in Houston, so this never mis-groups; if bookings in different cities on overlapping dates should stay apart, add "same city" to the rule (confirm with the product owner).
- Day 2 linked the hotel by trip ID; Day 4 groups by dates on every load. Both agree for the demo data. Trip IDs stay on bookings for the itinerary and seeded flights.
- Seeded flights (from the Day 2 setup) appear in the itinerary, because Days 2 and 3 ask for flights in the unified itinerary, but they never drive tiles or indicators (the data source is Day 2 and Day 3 bookings).
- Trip title city drops the state ("Your trip in Houston"); the destination line keeps it ("Houston, TX").
- Dinner-only tiles show the date and time ("Fri, Jan 1, 2027 · 8:00 PM").
- Tile images come from our destination library by city (Houston skyline, Silver Basin alpine). The requirement says the image is supplied by us.
- A second, hotel-only trip (Kesselhorn Lodge, Silver Basin, CO, Feb 12–16, 2027) is seed data so the demo can show two tiles. It matches Day 1's returning-customer sample.
- "Remove the tile one day after the checkout date": the tile shows through the checkout date and is gone the next day. Add a debug "today" override for the demo.
- Concur-style itinerary: day sections, a time column, an icon rail and cards with confirmation numbers; tapping an item opens its details. Dinner details are designed; hotel details reuse Day 2's booking detail.
- Not designed (potential scope noted on the slide): customers naming their own trip.

## Day 4 requirements (transcribed from the requirements slide)
Show a My reservation tile for each trip on the landing page once a customer has booked; each tile shows what is booked and opens a Concur-style itinerary.

1. **Find bookings**
   - Find the tile: show the My Trip section on the landing page, where customers find their bookings. Look up the customer's confirmed hotel and dining bookings.
   - Trip matching: group booked items into one trip when their dates overlap. Example: a Houston hotel is booked for the week of the 8th and a Houston dinner within the stay dates become one trip.
2. **Tile logic**
   - None booked: hide the My Trip section; no empty tile or prompt.
   - One booked: hotel only: "Your stay at [hotel name]". Dining only: "Your dinner at [restaurant name]", e.g. "Italian Restaurant".
   - Two or more booked: dates overlap, including check-in and checkout day: one tile for the whole trip, "Your trip in [City of hotel]".
   - Multiple trips: one tile per trip, upcoming trip first; dinners with no hotel each get their own tile.
   - Remove tile: remove the tile one day after the checkout date.
3. **Tile content**
   - Tile shows: destination, from booking data; image, supplied by us; title; trip dates, from booking data; Stay and Dining indicators: green with a check mark if booked, greyed out if not.
4. **Refresh**
   - Show the right data: pull the latest bookings each time the landing page loads. A new booking appears the next time the page loads. Re-run trip matching and tile logic on every page load, so titles and indicators always match what is booked. Example: a customer with a Houston dinner adds a hotel; on the next load the tile changes from "Your dinner at…" to "Your trip in Houston".
5. **Open trip**
   - Open trip: tapping a tile opens that trip's itinerary. Itinerary is a Concur-style view listing each booked item from Day 2 and Day 3 in the same date range.
   - POC: display only. No edit or cancel in POC. Post-POC: customer can edit or cancel booked items from the itinerary.

**Day 4 is complete when** hotel and dining with overlapping dates show one tile, "Your trip in Houston", with destination, image, dates, and both indicators green. Multiple trips show as multiple tiles, upcoming trip first. The itinerary is display only.

**Not included:** editing or cancelling from the itinerary (post-POC), Travel and Experience indicators, or empty-state prompts.

**Data source:** trip destination, dates, and bookings come from the customer's confirmed hotel and dining booking data (Day 2 and Day 3).
