# Lifestyle · Day 5 spec — Travel profile + Inspire me

Customers set travel, dining and brand preferences once, from a banner on the landing page. Each answer saves on its own. Concierge's "Inspire me" then uses the saved brands and airlines to suggest hotels, flights and a trip.

Target screens: `design/screens/day5/` (PNG, 2x). The same screens as HTML with exact values: `design/artboards/day5/`. Content, catalog, preference record and mock responses: `docs/sample-data-day5.json`. Decisions and the original requirements: `docs/day5-notes.md`. Day 1's tokens, materials and components (`docs/day1-spec.md`) and Day 2's progress bar and action bar (`docs/day2-spec.md`) still apply; this spec only adds what's new.

## 1. Flow

| Step | Screen | What the customer does | Screenshots |
|---|---|---|---|
| Entry | Landing page with the profile banner (Day 1) | Create profile | Day 1 landing (`hasTravelProfile: false`) |
| Intro | Personalize your experience | Get started, or Opt out | D5-iPhone-1-Intro, D5-Closed-1-Intro, D5-Open-1-Intro |
| 1 of 3 | Brands & airlines | Pick favorite hotel brands, airlines, venues, restaurants | D5-iPhone-2-Brands, D5-Closed-2-Brands, D5-Closed-2b-Brands-Scrolled, D5-Open-2-Brands |
| 2 of 3 | Dining | Pick cuisines, dietary needs, one price range | D5-iPhone-3-Dining, D5-Closed-3-Dining, D5-Open-3-Dining, D5-Book-Dining |
| 3 of 3 | Traveler | Review details from the record; add KTN, passport, redress | D5-iPhone-4-Traveler, D5-Closed-4-Traveler, D5-Closed-4b-Traveler-Scrolled, D5-Open-4-Traveler |
| All set | Your travel profile is set | Back to Lifestyle, or Try Inspire me | D5-iPhone-5-Done, D5-Closed-5-Done, D5-Open-5-Done |
| After | Landing page, no banner, "Travel profile saved" toast | — | D5-Closed-6-Home-No-Banner (iPhone and open display: the Day 1 returning landing without the banner) |
| AI search test | Concierge · Inspire me | Read picks; open a hotel | D5-iPhone-6-Inspire, D5-Closed-7-Inspire, D5-Closed-7b-Inspire-Scrolled, D5-Open-6-Inspire, D5-Tabletop-Inspire |

Navigation
- Setup opens full screen from the banner's Create profile (same pattern as Day 1's Concierge and Day 2's booking flow: no tab bar, Close at the top).
- Toolbar: Close on the intro, the first area and Done; Back + Close on Dining and Traveler. Standard toolbar items, so iPhone Duo puts them at the top of the side bar.
- Next goes to the next area. Skip goes to the next area without touching it. Back goes one area back and keeps every answer.
- Finish (on Traveler) goes to Done. Done → Back to Lifestyle returns to the landing page; Try Inspire me opens Concierge and sends "Inspire me".
- Close at any point returns to the landing page:
  - nothing saved → the banner is still there (Day 1 landing as it was);
  - anything saved → the banner is gone, and a one-time toast "Travel profile saved · Concierge now uses your preferences" floats at the bottom for 4 seconds.
- Opt out (intro only): records the opt-out against the ECN and returns to the landing page with the banner gone. See the notes for why.
- Inspire me can also be reached from Concierge (Day 1's Inspire me prompt). With a profile it returns the personalized picks; without one it keeps Day 1's general ideas.

## 2. Layout per device and pose

- **Compact (iPhone, Duo closed)**: one area per screen. Four-segment progress bar at the top with a caption ("1 of 3 · Brands & airlines", … "All set"). The title row carries the save pill on the trailing side. A sticky glass action bar sits at the bottom: Skip · "Saves as you go / Nothing is required" · primary Next button.
- **Duo closed**: content inset 20 leading / 84 trailing; the side bar holds Back and Close under the camera. Text buttons (Skip, Next, Opt out, Get started) stay in the content.
- **Open, landscape (split arrangement)**: the extra pane adds a level:
  - Intro + "What you'll get": a sample trip and hotels like those Inspire me will suggest.
  - Brands & airlines / Dining + a live **Your profile** summary that fills as chips are picked, with the action bar at the bottom of the trailing pane.
  - Traveler: documents lead; the locked "From your profile" details trail, above the action bar.
  - Done: the summary splits across both panes; the action bar trails.
  - Inspire me: the chat and follow-up chips lead; Trip, Hotels and Flights for you trail.
- **Book pose**: Dining + Your profile as two equal panes mirrored around the fold; nothing in the folding region (D5-Book-Dining).
- **Tabletop (portrait, horizontal bars)**: Inspire me with the trip and hotels on the upright half; the thread, flights and composer on the flat half (D5-Tabletop-Inspire).
- Keep state across size changes and poses: the current area, every pick, typed but unsaved text, and the scroll position.

## 3. New components

- **Area progress bar**: 4 segments, purple for done/current, caption under it. Reuse Day 2's progress bar with a different count.
- **Save pill** (title row, and per section on the open display): Saving… (grey, small spinner) → Saved (mint, check, pops in). Add a third state the designs don't show: "Not saved · Retry" (red text, tappable) when the mock returns `saved: false`.
- **Preference chip**: 44pt tall capsule, multi-select. Off: white 80%, ink text, grey outline. On: purple 12% fill, purple outline and text, leading check. `accessibilityAddTraits(.isSelected)` when on. Chips wrap.
- **Preference group**: glass tile with a 32pt icon circle, title, optional subtitle ("Pick any you like", "Saved with your profile", "Per person, before drinks"), then the chips.
- **Price segmented control**: $ · $$ · $$$ · $$$$, single select (tap the selected one again to clear it).
- **Locked row**: icon circle (grey), label, value, trailing lock icon. Group header "From your profile" with "Can't be changed here".
- **Document field**: label, optional Saved pill, 44pt text field. Once saved, the field shows only the last digits ("•••• •••• 4417"). Country + Expires share a row. Note under the group: "Documents are encrypted and stored with your profile. Only the last digits are shown."
- **Profile summary card**: icon, area name, status (Saved pill, live pill, "Up next" or "Skipped" tag), then label/value rows ("Not set" when empty).
- **Done header**: green check circle that draws in, "Your travel profile is set", "Concierge will use it to make suggestions personal.", note "Editing preferences isn't available in the app yet."
- **Toast**: frost glass capsule above the bottom edge: green check + "Travel profile saved" / "Concierge now uses your preferences".
- **Because chip**: small purple-tint capsule with a sparkle icon ("Solenne Collection", "Your airline", "Your hotel brand"). The **Based on** row under Concierge's first reply lists the saved brands and airlines that drove the picks.
- **Trip idea card**: image with "Trip idea" frost tag; title + dates; estimate ("Est. $1,650 for 2"); flight line; hotel line; because chips; View trip.
- **Hotel pick card**: image, name, price per night, because chip with the brand. Horizontal scroll on compact; two columns on the open display.
- **Flight pick row**: plane circle, route + flight number, date · nonstop, because chip, round-trip fare.

## 4. Behavior and rules

Entry
- Show the banner only when the customer has no saved preferences and hasn't opted out (`hasTravelProfile == false && optedOutOfProfile == false`). Read it with the landing page; until it loads, don't show the banner (no flash).
- Once anything is saved, the landing page never shows the banner again, and there is no Edit button anywhere on it.

Collect
- Brands & airlines: favorite hotel brands, airlines, venues and restaurants (multi-select chips from the catalog).
- Dining: cuisines (multi), dietary needs (multi), price range (single).
- Traveler: name, address and date of birth come from the customer record and are read-only; email and phone are shown but not editable. The customer can add Known Traveler Number, passport number, country of issue, passport expiry and redress number.
- Nothing is required. Skipped areas stay blank. Next is always enabled.

Save
- No Save button. Each change saves on its own:
  - chips and price: on tap, debounced 0.7s per area so quick taps send one request;
  - text fields: when the field loses focus or the customer presses Return/Next, and when they leave the area (Next, Skip, Back, Close).
- Store preferences against the customer's ECN (mock: `PATCH /customers/{ecn}/travel-preferences`, see the sample data).
- The first successful save creates the profile: set `hasTravelProfile = true` locally right away so the landing page is correct when the customer closes.
- Field checks before saving (placeholders; see the sample data): show an inline message under the field and don't save until it passes. Never send or log full document numbers in plain text; keep only the last 4 for display.
- A failed save shows "Not saved · Retry" on the pill; it never blocks moving on.

Inspire me (AI search test)
- Hotels: hotels whose brand is one of the favorite hotel brands.
- Flights: flights on favorite airlines.
- Trip: the top hotel plus a flight to the same city on matching dates, as one suggested trip with an estimate (hotel nights with taxes and fees + fares for the travelers).
- Leave out a section that has no matches. With no saved brands or airlines, fall back to Day 1's general ideas and hide the Based on row.
- Dining preferences are not applied anywhere in the POC (not to Inspire me, dining, experiences or checkout).
- Tapping a hotel opens Day 2's Hotel details for it. View trip / "Build the Miami trip" opens the same hotel with the trip's dates and travelers carried over. Flights are display only ("Flight booking isn't available yet; hotels open the booking flow.").
- "More hotels" adds the next hotels from the same favorite brands to the thread.
- The picks are simulated from the sample data for the POC (requirements slide: "Mix"); keep the matching logic in one place so a real AI search can replace it.

## 5. Accessibility and motion

- Chips and segments are buttons with selected state; the progress caption is read as "Step 1 of 3, Brands and airlines".
- Announce save results politely (VoiceOver: "Saved") without moving focus.
- Locked rows read as "Name, Avery Morgan, can't be changed here".
- Document fields use secure-looking masking only after save; while typing, show the characters so the customer can check them.
- Dynamic Type: chips wrap and grow; the action bar stacks its caption under the buttons at accessibility sizes.
- Motion: chip check pop, Saved pill pop, Done check draw, cards rise in. All off with Reduce Motion.

## 6. Models (suggested)

```swift
struct TravelPreferences: Codable, Equatable {
    var brands = Brands(); var dining = Dining(); var traveler = Traveler()
    var isEmpty: Bool { /* every list empty and every value nil */ }
    struct Brands: Codable, Equatable { var hotelBrandIds: [String] = []; var airlineIds: [String] = []; var venueIds: [String] = []; var restaurantIds: [String] = [] }
    struct Dining: Codable, Equatable { var cuisines: [String] = []; var dietaryNeeds: [String] = []; var priceRange: String? }
    struct Traveler: Codable, Equatable { var ktnLast4: String?; var passportLast4: String?; var passportCountry: String?; var passportExpiry: String?; var redressLast4: String? }
}
enum SaveState { case idle, saving, saved, failed }
protocol PreferencesService {
    func load(ecn: String) async throws -> TravelPreferences?
    func save(ecn: String, field: String, value: Any) async throws   // mock: 0.7s delay, scenario switch for failure
    func optOut(ecn: String) async throws
}
protocol InspireService { func recommendations(for prefs: TravelPreferences) async throws -> InspireResult }
```

## 7. Acceptance

- [ ] The banner shows only for a customer with no saved preferences who hasn't opted out; Create profile opens setup full screen.
- [ ] Closing with nothing saved returns to the landing page with the banner still showing.
- [ ] Each chip, price and document field saves on its own, with Saving… → Saved feedback and no Save button; moving to the next area also saves.
- [ ] Preferences are stored against the ECN (mock) and survive an app relaunch.
- [ ] After the first saved choice the banner never shows again, and there is no Edit button on the landing page.
- [ ] Traveler shows name, address and date of birth from the record (read-only) and contact info (not editable); KTN, passport, country, expiry and redress can be added, and only the last digits are shown after saving.
- [ ] Nothing is required: Skip works on every area, and Opt out is available.
- [ ] Inspire me returns hotels matching favorite hotel brands, flights matching favorite airlines, and a trip combining a hotel and flight, each with its reason.
- [ ] Matches the screenshots on iPhone, Duo closed, Duo open, book and tabletop; state survives opening and closing the Duo.
