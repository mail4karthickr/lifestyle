# Lifestyle (Travel & Lifestyle) — hackathon POC

A Lifestyle section inside the retail banking iOS app, for **iPhone and iPhone Duo**. Built one day at a time over five days; **all five days are built**:

1. Landing page + Concierge
2. Book a hotel
3. Reserve a table
4. My Trip: a trip's itinerary and booking details
5. Travel profile + Inspire me

## Read first
Each day's handoff is in `TravelAndLifeStyle/ExectionPlan/lifestyle-dayN/`:

- `docs/dayN-spec.md` — flow, layouts, components, rules, acceptance (`day1-spec.md` also has the tokens, materials and components every day reuses)
- `docs/dayN-notes.md` (`decisions.md` for Day 1) — decisions, and the original requirements transcribed from the slides
- `docs/sample-data*.json` — content and mock responses
- `design/screens/dayN/*.png` — target screens; `design/artboards/dayN/*.dc.html` — the same screens with exact values (ignore their template tags and scripts)

`TravelAndLifeStyle/Requirements/` has photos of the requirement slides (IMG_0001–0007) and screenshots of the real retail app for look and feel (IMG_0008–0013). It is kept out of the Git repository (see `.gitignore`) and exists only in the local working copy.

## Project
- Xcode project `TravelAndLifeStyle.xcodeproj`: the app target and a unit-test target (`TravelAndLifeStyleTests`, hosted in the app and depending on it through `test-host-target` and `dependencies` in `project.xcproj`). Deployment target iOS 27.1. The `TravelAndLifeStyle/` and `TravelAndLifeStyleTests/` folders are synchronized: files added there join their target.
- `ExectionPlan/` and `Requirements/` are kept out of the app bundle by the target's `EXCLUDED_SOURCE_FILE_NAMES`. Resources the app needs are copied to `Lifestyle/Resources/` and `Assets.xcassets/Lifestyle/`.
- Code is under `TravelAndLifeStyle/Lifestyle/`:
  - `Theme`, `Components`, `Models`, `Services`, `Navigation` — shared
  - `Landing`, `Concierge` — Day 1
  - `Hotel` — Day 2 (also the flow containers every flow uses: `FlowPage`, `FlowSplit`, `FlowPane`, `ActionBar`, `StepHeader`). `HotelCatalog` is every hotel the mock service knows: the sample's ten Houston hotels plus placeholder hotels for seven other destinations, all of which open and book. It also says which photo each hotel and room shows.
  - `Payment` — the points and card split shared by hotel and dining checkout (`PaymentChoosing`)
  - `Dining` — Day 3
  - `Trips` — Day 4: `BookingStore` (confirmed bookings), `TripBuilder` (pure trip matching), itinerary and booking details; also the My plans cards on the landing page
  - `Profile` — Day 5: preferences, autosave, setup screens, Inspire me
- The shared scheme `TravelAndLifeStyle` builds the app and runs the tests.

## Conventions
- SwiftUI, one adaptive layout driven by size classes; no device checks, no fixed widths. Margins come from safe areas.
- Standard `NavigationStack` and `.toolbar`, so iPhone Duo moves controls to the side bar. Every toolbar item is a `Label`. Regular width uses `ArrangementView` (split).
- Close (×) is only on the landing page, where it returns to the retail app's Menu (the stand-in screen in `ContentView.swift`): Lifestyle is opened from the Menu. Every other page leaves with Back. The landing header is Close at the top left and the points pill at the top right; Day 1's logo pill and Cart were removed at the user's request (2026-11-21). Sheets keep their own dismiss button.
- A Fargo Concierge thread shorter than the screen starts at the top (user request; the Day 1 screens anchor it above the chat field).
- Every inspire-me card and prompt chip on the Fargo Concierge start screen starts the guided chat (Day 1: "a guided chat with inspire-me prompts"). A prompt that names a kind of trip (`ConciergeModel.Idea`: beach week, ski weekend, New York, relaxed weekend) is answered with two stays from `HotelCatalog` for its destination and dates, ranked by the budget answer; any other request gets the sample's Houston hotel and dinner. Vibe and Dining answers only change the sample's reasons, not which stays are picked.
- "Inspire me" always recommends hotels, flights and a trip (Day 5: "recommend hotels, flights, and trips based on saved preferences"). Hotels match favorite brands, flights match favorite airlines, and the trip combines a hotel pick and a flight pick to the same city. Where no favorite is saved for one of them, `MockInspireService.match` fills that list from the catalog, and only real matches carry a "because" chip. Flights are display only: flight booking is not in the POC.
- All design tokens in `Theme/Theme.swift`. No hex values in views.
- State that must survive Back, size changes and Duo poses lives in models (`LifestyleStore`, `HotelFlowModel`, `DiningFlowModel`, `ProfileModel`, `ConciergeModel`), not in views.
- Services are protocols with mocks that read the sample JSON, add delays and have scenario switches. No network calls. The travel profile mock persists in `UserDefaults`, keyed by ECN.
- Trips are never stored: `TripBuilder` works them out from the bookings on every landing load.
- **The requirement slides are the source of truth** (photos in `TravelAndLifeStyle/Requirements/`; read the photo, not only the transcription in the notes). Where the design handoff (specs, notes, screens) differs from a slide or adds to it, follow the slide (user, 2026-11-21). The user's own explicit requests still stand where they differ from a slide.
- The landing page has **My plans** below Book now (Day 1 slide): always shown, one card per trip, and an empty state when nothing is booked. A card is also Day 4's tile for the trip, so it shows the trip name, destination, image and dates, then four status tiles (Stay, Travel, Dining, Experience; only Stay and Dining can be booked). Selecting a plan opens **My Trip**, that trip's itinerary page (Day 4), directly. Day 4's rules decide which trips there are, their titles, order and removal. Do not add a page of trip tiles between the two: it was built on 2026-11-21 and the user had it removed the same day because it repeated the My plans list. Two lines of the Day 4 slide lose to Day 1 here: "hide the My Trip section" when nothing is booked, and no Travel or Experience indicators.
- Compare dates with `Date.isOnOrBefore(_:)`, not `<=`: built with the iOS 27.2 SDK, `<=` between two dates crashes on the iOS 27.1 simulator.
- The assistant is named "Fargo Concierge" in everything the customer reads or hears, as on the requirement slides (types and files keep the short name, `ConciergeView`, `ConciergeModel`). Its greeting and AI disclosure come from the bundled `Lifestyle/Resources/sample-data.json`, which differs from the Day 1 handoff copy in those two strings.
- The Fargo icon is drawn in `Components/BrandMarks.swift` from `Requirements/IMG_0008`. It is an approximation: use the official artwork before shipping.
- Hotels and rooms show real photographs (`Assets.xcassets/Lifestyle/Photos/`, named `photo_*`), not the design artwork. They are freely licensed photos of other, real hotels from Wikimedia Commons, credited in `PHOTO-CREDITS.md`; keep that file in step when a photo changes, and avoid photos with a legible brand sign. The landing hero, carousel, trip tiles and restaurant still use the design artwork.

## Running states for demos and screenshots
Launch arguments (most are also on the app's Menu stand-in screen, reached with Close on the landing page):
- `-lifestyleSeed none|dinnerOnly|hotelOnly|hotelAndDinner|twoTrips` — bookings that exist at start
- `-lifestyleToday 2027-01-03` — "today", to show a tile going away after checkout
- `-lifestylePoints 52450` — rewards balance (enough to pay a dining deposit with points only)
- `-lifestyleLoading normal|slow|stuck|plansFail`
- `-lifestyleReprice priceChanged|noChange|roomUnavailable`, `-lifestyleBooking succeeds|failsOnce`
- `-lifestyleDining success|paymentDeclined|soldOutAtConfirm|overlap`
- `-lifestyleProfile keep|reset|sample`, `-lifestyleSave succeeds|failsOnce`
- `-lifestyleStart <step>` opens the app part-way through a flow (`Navigation/DemoStart.swift`):
  `hotelSearch|hotelResults|hotelDetails|hotelRooms|hotelCheckout|hotelCheckoutAccepted|hotelReview|hotelBooking|hotelConfirmed|itinerary|homeAfterBooking`,
  `restaurant|diningTable|diningTableParty6|diningDetails|diningDetailsErrors|diningDeposit|diningReview|diningReviewTerms|diningReserving|diningConfirmed|diningItinerary|homeAfterDinner`,
  `tripItinerary|dinnerDetails|stayDetails`, `profileIntro|profileBrands|profileDining|profileTraveler|profileDone`, `inspire|inspireMoreHotels`,
  `conciergeQuestions|conciergePicks|conciergeIdeaPicks`

## How to work
- Build after each step and fix all errors and warnings before moving on.
- Run the unit tests after changing trip matching, dining availability, Inspire me matching, the Fargo Concierge prompts and picks, or the hotel catalog and its photos:
  `xcodebuild test -project TravelAndLifeStyle.xcodeproj -scheme TravelAndLifeStyle -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO`
- After changing a screen, run in the iOS Simulator and compare with the matching PNG in that day's `design/screens/`.
- Don't add features beyond the specs. If something is unclear, ask.
