# Prompts for Claude Code — Day 5

Run these after Day 2 is finished. Day 5 uses Day 1's landing banner and Concierge, and opens Day 2's Hotel details.

## One prompt (hands-off)
Open Claude Code on your project folder and paste this. Adjust the path if you unzipped somewhere other than Downloads.

> Copy everything inside ~/Downloads/lifestyle-day5 into this project, keeping the folder structure (docs/, design/, PROMPTS-day5.md). Then update CLAUDE.md: the current day is Day 5 (Travel profile + Inspire me), and add docs/day5-notes.md and docs/day5-spec.md to "Read first". Read both, and look at every image in design/screens/day5. Plan Day 5, then build it step by step: the preferences model and a mock PreferencesService keyed by ECN that persists across launches, with a save-failure scenario; the banner rule on the landing page; setup (intro, Brands & airlines, Dining, Traveler, Done) with autosave and the Saving…/Saved pill, Skip, Back, Close and Opt out; the live Your profile pane on the open display; the landing page without the banner and the one-time toast; and Inspire me in Concierge with hotel, flight and trip picks driven by saved brands and airlines, where hotels open Day 2's Hotel details. After each step, build and run in the iOS Simulator and compare with the matching screenshot; fix differences before moving on. Finish by walking the Day 5 acceptance criteria and listing anything left.

## Step by step (more control)
0. **Set up and plan** (plan mode: Shift+Tab until "plan mode on")
   > Copy everything inside ~/Downloads/lifestyle-day5 into this project, keeping the folder structure. Update CLAUDE.md so the current day is Day 5 and it reads docs/day5-notes.md and docs/day5-spec.md. Then propose a plan for Day 5. Don't write feature code yet.
1. **Model + mock service**
   > Add TravelPreferences and a PreferencesService protocol with a mock that reads docs/sample-data-day5.json, stores the record per ECN so it survives relaunch, waits 0.7s per save, and has a scenario switch for save failure. Add a debug reset that clears the profile so the banner comes back for demos.
2. **Banner rule + intro**
   > Show the landing banner only when there's no saved profile and no opt-out. Create profile opens setup full screen. Build the intro with Opt out and Get started. Match D5-iPhone-1-Intro, D5-Closed-1-Intro and D5-Open-1-Intro.
3. **Brands & airlines + Dining**
   > Build both areas with multi-select chips, the price segmented control, the progress bar, the action bar (Skip, Saves as you go, Next) and autosave with the Saving…/Saved pill. On regular width add the live Your profile pane. Match D5-*-2-Brands, D5-*-3-Dining and D5-Book-Dining.
4. **Traveler + Done**
   > Build Traveler with the locked rows from the customer record and the optional document fields (save on end editing and when leaving the area, show only the last 4 after saving, placeholder checks from the sample data). Then Done with the summary, Back to Lifestyle and Try Inspire me. Match D5-*-4-Traveler and D5-*-5-Done.
5. **Back on the landing page**
   > After any save, Close or Back to Lifestyle returns to the landing page without the banner and shows the one-time "Travel profile saved" toast. Closing with nothing saved keeps the banner. Match D5-Closed-6-Home-No-Banner.
6. **Inspire me + check**
   > In Concierge, make Inspire me use the saved brands and airlines: Trip for you, Hotels for you and Flights for you with Based on and because chips, following the rules in the spec. Hotels and View trip open Day 2's Hotel details with dates and travelers carried over; flights are display only. Match D5-*-Inspire and D5-Tabletop-Inspire. Then build and run, walk every Day 5 requirement in docs/day5-notes.md, compare each screen with design/screens/day5, and list anything that doesn't match.

For iPhone Duo, open the app in Xcode's Device Hub (closed, open, book, tabletop) and paste screenshots of anything off into the session with the matching screen name.
