# Prompts for Claude Code — Day 3

Run these after Day 2 is finished. Day 3 reuses Day 2's action bar, pay controls, booking panel and itinerary timeline.

## One prompt (hands-off)
Open Claude Code on your project folder and paste this. Adjust the path if you unzipped somewhere other than Downloads.

> Copy everything inside ~/Downloads/lifestyle-day3 into this project, keeping the folder structure (docs/, design/, PROMPTS-day3.md). Then update CLAUDE.md: the current day is Day 3 (Reserve a table), and add docs/day3-notes.md and docs/day3-spec.md to "Read first". Read both, and look at every image in design/screens/day3. Plan Day 3, then build it step by step: the restaurant, hard-coded setup and seeded bookings, and a mock DiningService with its scenario switch (success, payment declined, sold out at confirm, overlap); the Restaurant screen; Choose a table with the party stepper, fit rule, tables left and Sold out; Your details with prefill, validation and the overlap block; Deposit with the points/card split and policy; Review with the terms box, Reserving, Payment failed and duplicate protection; the confirmation; and the dinner in the Houston itinerary. Wire the entry points (Day 1 Dining card, Concierge pick, Book now → Events, and Day 2's Nearby row), and switch trip indicators to Stay and Dining only. After each step, build and run in the iOS Simulator and compare with the matching screenshot; fix differences before moving on. Finish by walking the Day 3 acceptance criteria and listing anything left.

## Step by step (more control)
0. **Set up and plan** (plan mode: Shift+Tab until "plan mode on")
   > Copy everything inside ~/Downloads/lifestyle-day3 into this project, keeping the folder structure. Update CLAUDE.md so the current day is Day 3 and it reads docs/day3-notes.md and docs/day3-spec.md. Then propose a plan for Day 3. Don't write feature code yet.
1. **Models + mock service**
   > Add Restaurant, Slot and Reservation and a DiningService protocol with a mock that reads docs/sample-data-day3.json, keeps table counts and the points balance in memory across the session, adds the delays, and has a scenario switch for payment declined, sold out at confirm and overlap. Add a debug reset for the counts.
2. **Restaurant + Choose a table**
   > Build the Restaurant screen and Choose a table: party stepper 1–6, only times whose table fits, tables left, Sold out, the hidden-times note, and the live Your table pane on regular width. Match D3-*-1-Restaurant, D3-*-2-Table, D3-*-2b-Table-Party-6, D3-Book-Table and D3-Tabletop-Table.
3. **Your details**
   > Build Your details with prefilled contact, accessibility chips, requests and dietary notes, inline validation and the overlap banner; entries survive Back. Match D3-*-3-Details and D3-Closed-3b-Details-Errors.
4. **Deposit**
   > Build the deposit screen with Day 2's pay controls set to $100 × party, the policy card and the order summary on regular width. Match D3-*-4-Deposit.
5. **Review, reserving, confirmation, itinerary**
   > Build Review with the terms box gating Reserve, an idempotency key, the Reserving panel in the order from the spec (points last), Payment failed, the confirmation, and the dinner added to the Houston itinerary with Stay and Dining indicators. Match D3-*-5, 5a, 5b, 5c, 6 and 7.
6. **Entry points + check**
   > Wire the entry points into the Restaurant screen. Build and run, book 8:00 PM for 4 and check the count drops to 1 left, walk every Day 3 requirement in docs/day3-notes.md, compare each screen with design/screens/day3, and list anything that doesn't match.

For iPhone Duo, open the app in Xcode's Device Hub (closed, open, book, tabletop) and paste screenshots of anything off into the session with the matching screen name.
