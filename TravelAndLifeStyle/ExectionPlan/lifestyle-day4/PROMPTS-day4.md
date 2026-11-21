# Prompts for Claude Code — Day 4

Run these after Day 3 is finished (Day 4 builds trips from Day 2 hotel and Day 3 dining bookings).

## One prompt (hands-off)
Open Claude Code on your project folder and paste this. Adjust the path if you unzipped somewhere other than Downloads.

> Copy everything inside ~/Downloads/lifestyle-day4 into this project, keeping the folder structure (docs/, design/, PROMPTS-day4.md). Then update CLAUDE.md: the current day is Day 4 (My trips + itinerary), and add docs/day4-notes.md and docs/day4-spec.md to "Read first". Read both, and look at every image in design/screens/day4, starting with D4-Tile-States. Plan Day 4, then build it step by step: a pure TripBuilder that groups confirmed hotel and dining bookings by inclusive date overlap, applies the title, indicator, order and removal rules, with unit tests for the five cases and the removal date in docs/sample-data-day4.json; a debug "today" override; the My trips section replacing My plans (hidden when nothing is booked, Stay and Dining indicators only, everywhere indicators appear); a fresh fetch on every landing load; the Concur-style itinerary and the booking details, and point Day 2's and Day 3's "View itinerary" to it. After each step, build and run in the iOS Simulator and compare with the matching screenshot; fix differences before moving on. Finish by walking the Day 4 acceptance criteria and listing anything left.

## Step by step (more control)
0. **Set up and plan** (plan mode: Shift+Tab until "plan mode on")
   > Copy everything inside ~/Downloads/lifestyle-day4 into this project, keeping the folder structure. Update CLAUDE.md so the current day is Day 4 and it reads docs/day4-notes.md and docs/day4-spec.md. Then propose a plan for Day 4. Don't write feature code yet.
1. **TripBuilder + tests**
   > Write TripBuilder as a pure function from bookings and today's date to trips, following the rules in docs/sample-data-day4.json, and unit-test none, dinner only, hotel only, hotel + dinner, two trips, and the removal date. Add a debug override for today and a way to seed each case.
2. **My trips on the landing page**
   > Replace My plans with My trips: hidden when nothing is booked, one tile per trip (image, title, destination, dates, Stay and Dining indicators), upcoming first, rebuilt on every load with Day 1's skeleton and error card. Switch any four-tile indicators (Day 1 plan card, Day 2 trip header) to Stay and Dining. Match D4-Closed-1 to 5, D4-Open-1, D4-iPhone-1 and D4-Tile-States.
3. **Itinerary + details**
   > Build the Concur-style itinerary (hero, indicators, summary tags, day sections with the time rail) and booking details (dinner as designed, hotel from Day 2's booking detail). On regular width show details in the trailing pane. Point Day 2's and Day 3's View itinerary here. Match D4-*-Itinerary, D4-*-Dinner and D4-Book-Itinerary.
4. **Check**
   > Run the refresh example (dinner only, add the hotel, reload) and the removal example (today = Jan 3, 2027), walk every Day 4 requirement in docs/day4-notes.md, compare each screen with design/screens/day4, and list anything that doesn't match.

For iPhone Duo, open the app in Xcode's Device Hub (closed, open, book) and paste screenshots of anything off into the session with the matching screen name.
