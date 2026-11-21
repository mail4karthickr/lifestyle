# Day 5 notes — decisions and requirements

## Decisions from the design session
- Same scope as Days 1 and 2: iPhone and iPhone Duo only; same tokens, materials and placeholder branding. Hotel brands, airlines, venues and restaurants are fictional placeholders.
- Day 5 was designed before Days 3 and 4. It depends only on Day 1 (the banner and Concierge) and Day 2 (Hotel details, which Inspire me opens).
- Setup is three short areas, one per screen on compact width (Brands & airlines → Dining → Traveler), framed by an intro and a Done screen. The requirement lists the areas in that order.
- Autosave is visible: a Saving… → Saved pill on each area (and on each summary card on the open display) is the only save feedback. There is no Save button anywhere.
- The open display adds a live "Your profile" summary next to setup, so the customer sees each choice land. It's the same summary the Done screen shows.
- Opt out: the requirement asks for an opt-out button but doesn't say what it does. Choice made here: Opt out stores an opt-out flag against the ECN and hides the banner, so a customer who said no isn't asked again. Close (without saving) is the "maybe later" path and keeps the banner. Confirm with the product owner; if opt-out should keep the banner, drop the flag.
- The "Travel profile saved" toast on the landing page confirms why the banner disappeared. It shows once.
- Traveler documents: masked to the last 4 digits once saved; stored encrypted (mock: only last 4 kept in the app). Country of issue and passport expiry are included as the "other items as documented"; confirm the full list.
- Validation rules for KTN, passport and redress are placeholders (see the sample data) so the demo catches typos.
- Inspire me uses only brands and airlines, as the requirement states; dining preferences are collected but not applied in the POC (listed under Not included). The "Based on" chips therefore show only hotel brands and airlines.
- Dining copy promises nothing about table bookings ("Saved with your profile"): the requirements leave applying preferences to dining out of the POC, so Day 3 doesn't pre-fill dietary notes.
- Trip estimate: hotel nights with taxes and fees (Day 2's 17%) plus round-trip fares for both travelers: 3 × $289 × 1.17 = $1,014.39, plus 2 × $318 = $636.00, so "Est. $1,650 for 2".
- Inspire me picks are simulated from the sample data (the requirements' card 8 is "Mix": functional + simulated). Matching sits behind one service so a real AI search can replace it.
- Hotels and View trip open Day 2's booking flow; flight booking isn't in the POC, so flights are display only.
- Not designed (nice to have, from a reviewer comment): an onboarding quiz or "wine barometer". Left out of the POC.

## Day 5 requirements (transcribed from the requirements slide)
Customers set travel, dining and brand preferences once from a banner; the POC tests whether AI search can use them.

1. **Entry**
   - Landing banner: "Personalize your experience. Create your travel profile." Show it only to customers with no saved preferences. Tapping Create profile opens preference setup full screen.
   - After data is entered: the banner no longer shows. No Edit button on the landing page; editing saved preferences is post-POC.
   - Abandoned without data: Close returns to the landing page. Nothing was saved, so the banner still shows.
2. **Collect**
   - Brands and airlines: favorite hotel, airline, venue and restaurant brands.
   - Dining: cuisines, dietary needs, price range.
   - Traveler: prefilled from the customer record (name, address, date of birth). Contact info shown but not editable. Customer enters KTN, passport number, redress number and other items as documented.
   - Required: nothing. Skipped areas stay blank. An opt-out button is available.
3. **Save**
   - Save automatically as the customer enters information; no Save button. Each preference saves as soon as it is entered, including when the customer moves to the next area. Store preferences against the customer ECN.
   - The first saved choice counts as a profile, so the banner stops showing.
   - Editing is out of scope for the POC; post-POC, customers edit from a separate entry point.
4. **AI search test**
   - "Inspire me" recommends hotels, flights and trips based on saved preferences.
   - Hotels match favorite hotel brands. Flights match favorite airlines. Trips combine hotel and flight picks into a suggested trip.

**Day 5 is complete when** preferences save automatically and the banner stops showing, and "Inspire me" returns hotel, flight and trip recommendations based on saved preferences.

**Not included:** editing preferences or contact info; applying preferences to dining, experiences or checkout; adding new cards; AI-inferred preferences.
