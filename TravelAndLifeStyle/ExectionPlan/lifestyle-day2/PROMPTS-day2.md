# Prompts for Claude Code — Day 2

## One prompt (hands-off)
Open Claude Code on your Day 1 project folder and paste this. Adjust the path if you unzipped somewhere other than Downloads.

> Copy everything inside ~/Downloads/lifestyle-day2 into this project, keeping the folder structure (docs/, design/, PROMPTS-day2.md). Then update CLAUDE.md: the current day is Day 2 (Book a hotel), and add docs/day2-notes.md and docs/day2-spec.md to "Read first". Read both, and look at every image in design/screens/day2. Plan Day 2, then build it step by step: models and the mock Aspire service with its scenario switch, search, results with filters and sort, hotel details, room + rate, reprice + pay, review with booking in progress and duplicate protection, confirmation, and the itinerary linked to the existing trip. Wire the Day 1 entry points (Book now → Hotels, the travel carousel, and the Concierge hotel pick), and make the My plans trip card on the home page open the itinerary (it shows the trip once the hotel is booked, per D2-*-Home-After-Booking). After each step, build and run in the iOS Simulator and compare with the matching screenshot; fix differences before moving on. Finish by walking the Day 2 acceptance criteria and listing anything left.

## Step by step (more control)
0. **Set up and plan** (plan mode: Shift+Tab until "plan mode on")
   > Copy everything inside ~/Downloads/lifestyle-day2 into this project, keeping the folder structure. Update CLAUDE.md so the current day is Day 2 and it reads docs/day2-notes.md and docs/day2-spec.md. Then propose a plan for Day 2. Don't write feature code yet.
1. **Models + mock service**
   > Add the Day 2 models and an AspireService protocol with a mock that reads docs/sample-data-day2.json, adds delays, and has a scenario switch for reprice (Price changed, No change, Room unavailable) and booking failure.
2. **Search, results, filters, details**
   > Build Search, Results (filters, sort, 10 results), the Filters sheet and Hotel details. Match D2-iPhone-1 to 3 and D2-Closed-1 to 3; on regular width, Results + details side by side like D2-Open-2-Results and D2-Book-Results.
3. **Room + rate**
   > Build room + rate selection with exactly one selection, the policy on every rate, and the stay summary (bar on compact, pane on regular). Match D2-*-4-Rooms.
4. **Reprice + pay**
   > Build checkout: reprice on entry with all four states, change diff and acceptance gating, and the tender controls with split math and validation. Match D2-*-5-Checkout and D2-Tabletop-Checkout.
5. **Review, booking, confirmation, itinerary**
   > Build review and submit with an idempotency key, the in-progress panel that blocks repeat taps, the confirmation, and the itinerary that adds the hotel to the existing trip with the flights. Match D2-*-6, 6b, 7 and 8.
6. **Entry points + check**
   > Wire the Day 1 entry points into this flow, and make the My plans trip card open the itinerary (D2-*-Home-After-Booking, D2-Open-9-Itinerary). Build and run, walk every Day 2 requirement in docs/day2-notes.md, compare each screen with design/screens/day2, and list anything that doesn't match.

For iPhone Duo, open the app in Xcode's Device Hub (closed, open, book, tabletop) and paste screenshots of anything off into the session with the matching screen name.
