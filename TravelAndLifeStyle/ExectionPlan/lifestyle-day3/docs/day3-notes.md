# Day 3 notes — decisions and requirements

## Decisions from the design session
- Same scope as Days 1, 2 and 5: iPhone and iPhone Duo only; same tokens, materials and placeholder branding.
- The restaurant is Osteria Lume (already on Day 1's Dining tab and Concierge pick): live-fire Italian, Chef Livia Montarro, 1420 Calder Row, Houston. The one fixed date is Fri, Jan 1, 2027 (New Year's Day chef's table), inside the Houston trip (Dec 30 – Jan 2), so the dinner joins that trip.
- With one restaurant, "Select restaurant" is the restaurant page itself. The progress bar covers the four booking steps that follow: Table, Details, Pay, Review.
- Table fit: a table fits when its size is at least the party size. Times that don't fit are hidden (with a note naming them); times that fit but have no tables left show Sold out.
- Seeded bookings by other guests give the demo a spread of counts and one Sold out (9 PM). Every hour still starts at 5 tables; tables left = 5 minus confirmed bookings.
- Designs show a party of 4 (the requirements' $400 = 40,000 points example) so the 2-top filtering is visible. The real default is the trip's 2 travelers.
- Points: designs start from Day 1's 12,450 points, like Day 2, so Points only is unavailable for $400 (needs 40,000) and the screen says why. Default split 10,000 pts + $300 card, leaving 2,450. The mock keeps the real balance, so whichever of Day 2 or Day 3 runs second sees what's left; seed 52,450 to demo Points only.
- Overlap rule: a reservation occupies 2 hours from its start. A new one for the same customer on the same date that overlaps is blocked. The 2 hours is an assumption; confirm with the product owner.
- Accessibility needs are captured on Details because Review must show them.
- One terms checkbox, on Review next to Reserve. The requirements ask for it under Payment and under Confirm; one box at the moment of commitment covers both. The policy shows on Deposit and on Review.
- Dietary notes are typed, not prefilled from Day 5 preferences (applying preferences to dining isn't in the POC).
- Order on Reserve: recheck availability (tables aren't held), charge card (simulated), create the reservation and lower the count, then deduct points. That keeps "deduct points only after confirmation" and "no points if payment fails".
- Reservation ID format `RES-yymmdd-XXXX`. No restaurant is notified.
- Trip indicators are Stay and Dining only (Day 4 leaves Travel and Experience indicators out), starting with the Day 3 itinerary header.
- The itinerary view is Day 2's timeline with the dinner added. Day 4 replaces it with the Concur-style itinerary.
- Not designed (potential scope noted on the slide): cancellation with the table returning to inventory, and a hold timer.

## Day 3 requirements (transcribed from the requirements slide)
Set up a static dining offering of one restaurant in Houston for end-to-end POC testing; no restaurant API, and no real table is held.

1. **Select restaurant**
   - Restaurants: one static restaurant in Houston, TX. Each record: name, city, chef, cuisine, menu, imagery, address. No restaurant API in POC.
   - Setup (hard-coded for POC): open 5 PM to 11 PM; hours and tables are hard-coded in seed data (no inventory tool or admin screen). 5 tables per hour; table size repeats: 5 PM, 8 PM: 4-tops; 6 PM, 9 PM: 6-tops; 7 PM, 10 PM: 2-tops.
2. **Select date + time**
   - Availability: one fixed date, e.g. "Available on 01/01/2027". Capture party size (max 6); only 6 PM and 9 PM 6-tops fit parties of 5–6. Hourly start times, 5 PM to 10 PM, restaurant local time (hard-coded). Show "X tables left" per time; if no table fits, show SOLD OUT.
   - Table inventory: show only times with a table that fits the party (3 guests cannot take a 2-top); each booking lowers that time's open tables (starts at 5). Tables are not held during checkout; the count drops only when the booking is confirmed.
3. **Guest details**
   - Guest info: prefill name, email and phone from the customer's profile. Capture special requests and dietary notes. Validate required fields; block overlapping bookings by the same customer. Keep entries if the customer goes back. Show the selected slot summary.
4. **Payment**
   - Deposit: $100 per person up front; show total and rewards balance. Customer picks points/cash split; 100 points = $1 ($400 = 40,000 points); cash covers the rest.
   - Policy: show cancellation policy at checkout (display only, no cancellations processed): refunded 48+ hours out, lost within 48 hours. Require terms and conditions checkbox.
   - Processing: card entry is simulated; no live charge. Deduct points only after confirmation. If payment fails, no points are deducted.
5. **Confirm + itinerary**
   - Confirm: review restaurant, date, time, party size, accessibility needs, and price. Terms and conditions box must be checked. Generate a Wells Fargo reservation ID; no restaurant is notified in POC. Store customer, trip, restaurant, slot, party, points, cash, status.
   - Add to itinerary: add dining to the itinerary with flight and hotel: restaurant, date, time, party size, reservation ID. Show confirmation with reservation ID and updated rewards balance.

**Day 3 is complete when** a customer sees tables left for each start time at the Houston restaurant, books with points and cash at $100 per person, open tables drop with each booking, and the item appears in the itinerary. Setup runs on hard-coded inventory.

**Not included:** live restaurant API or held tables, real card processing, an inventory admin tool (setup is hard-coded), restaurant notifications, waitlist, hold timer, or cancellation.
