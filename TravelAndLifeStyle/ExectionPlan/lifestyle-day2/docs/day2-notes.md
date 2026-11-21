# Day 2 notes — decisions and requirements

## Decisions from the design session
- Same scope as Day 1: iPhone and iPhone Duo only; same tokens, materials and placeholder branding.
- The flow is one decision per screen on compact width, with a five-step progress bar (Hotel, Room, Pay, Review, Done). The open display pairs each decision with the next level of detail (see the spec, section 2).
- The existing trip already has flights (Coast Air 1015 SFO → IAH on Dec 30, Coast Air 1022 IAH → SFO on Jan 2). The hotel joins that trip; no new trip is created. All flight and hotel data is fictional.
- Points balance stays 12,450 (as in Day 1), so Points only is unavailable for this stay and the design shows why. Default split: 10,000 pts + card. If the demo needs Points only (Day 3's dining checkout uses 40,000 pts), seed a higher balance in the mock customer.
- Day 1's returning-customer sample shows the Houston trip with Stay and Dining booked; after Day 2 the trip shows Stay and Travel booked. Treat Day 1's returning state as an example, and drive the real tiles from booking data.
- Where the itinerary lives: nowhere on its own. The requirements store booking records (Day 2 step 5: hotel booking fields + link to the existing trip ID; Day 3 step 5: dining booking fields + trip) and Day 4 builds the trip view from that booking data on every load. So the itinerary = all bookings for the trip, sorted by date.
- Day 2 links bookings by trip ID while Day 4 groups bookings whose dates overlap. Rule used here: link to the trip ID when one exists; fall back to date-overlap grouping for bookings without a trip (Day 4's "dinners with no hotel each get their own tile").
- Finding the itinerary later: home → My plans → trip card → itinerary. Until Day 4's My Trip exists, the card opens the Day 2 itinerary view.
- Empty My plans: Day 1 says show an empty state; Day 4 says hide the section when nothing is booked. Day 1's empty state is kept for now; revisit on Day 4.
- Card entry is simulated: a saved card is preselected; "Use another card" opens a simulated form. No live charge.
- Aspire limits (guests, rooms) are placeholders in the designs (8 / 4); use what the API returns.

## Day 2 requirements (transcribed from the requirements slide)
Let the customer choose a hotel room and rate, reprice it, pay with card, points, or both, and add the confirmed hotel to the existing trip itinerary.

1. **Hotel search**
   - Search: capture destination, dates, guests and rooms; limits per the Aspire API.
   - Results: live data from Aspire; show the first 10 hotels, sorted by relevance. Filter results (Brand, Price, Rating, Amenities, Distance from, Accessibility). Sort: Recommended, Price, Rating (POC only).
   - Hotel details: show name, address, photos, amenities and ratings. Carry over trip dates and travelers; retain the hotel identifier.
2. **Room + rate**
   - Rooms + rates: show room types, beds, occupancy and rates. Show cash price, points price, taxes and fees.
   - Cancellation terms: show the cancellation policy returned by the API on every rate before selection.
   - Selection: preserve the room and rate identifier. Customer selects exactly one room and rate. Show a selected-stay summary.
3. **Reprice + pay**
   - Reprice: reprice and recheck availability before payment. Flag changes to price, room or cancellation terms (e.g., $250 to $255: show the new total). Require acceptance of any change to continue.
   - Payment: show the available rewards balance. Allow card, points, or points + card; 100 points = $1 (e.g., $100 = 10,000 points). Customer picks the split; cash covers the remainder; validate the balance. Recalculate the split when points change. Card entry is simulated; no live charge.
4. **Complete booking**
   - Confirm: review the final summary: hotel, dates, room, guests, price and tender. Require explicit confirmation before booking.
   - Submit: submit the booking to Aspire (Aspire triggers the loyalty order). Show a booking-in-progress state; block repeat clicks for duplicative bookings.
5. **Add to itinerary**
   - Store: Aspire booking ID, confirmation number and status. Store rate, cancellation terms, amounts, payment and timestamp.
   - Link to trip: link the hotel to the existing trip ID and customer. Do not create a new trip record.
   - Itinerary: show the hotel in the unified itinerary with the flight: hotel, dates, room, guests, confirmation number. Show the updated rewards balance.

**Day 2 is complete when** the hotel is repriced, booked with card / points / both, linked to the existing trip ID, and shown in the itinerary; a repeat submission creates no duplicates.

**Not included:** real card processing, post-booking changes or cancellation, refunds, group rooms, or servicing emails.
