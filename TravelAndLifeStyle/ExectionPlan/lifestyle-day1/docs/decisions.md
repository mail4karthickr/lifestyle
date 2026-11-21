# Decisions and context (from the design session)

Claude Code on your Mac didn't see the design conversation. This file records what was decided there.

## Project
- Hackathon, built one day at a time. Each day has its own spec; build only the current day.
- Day 1 = Landing page + Concierge. Platforms for now: **iPhone and iPhone Duo only** (iPad and Mac are out of scope).
- The feature lives inside the existing retail banking iOS app. Colours and typography follow that app (see the spec's tokens); the UI adds a glassmorphism layer (frosted cards, Liquid Glass controls) on top.

## Navigation
- Lifestyle opens full screen from the app (as the app's product pages open from Explore), with a **Close** button that returns to the app. No extra tab bar: Day 1 is one page, and the Concierge opens from its search box.

## Branding
- The designs use placeholders: a red logo tile with the word "Lifestyle", and the assistant named "Concierge". Replace them with the real Lifestyle logo and assistant name from the app's brand assets. Keep the layout.

## Concierge
- Simulated for the POC: scripted conversation from `docs/sample-data.json`, no live AI.
- It asks follow-ups (dates, budget, vibe, dining), returns one hotel and one dining pick with a reason for each, and hands off to the booking flows. Nothing is booked or charged in chat.
- Keep the AI disclosure ("Concierge is an AI assistant, not a real person…").

## Sample data story
All sample data is fictional and consistent with the Day 2–4 requirements:
- Customer Avery, 12,450 points ($124.50 at 100 points = $1), no travel profile yet.
- Trip: Houston, Dec 30, 2026 – Jan 2, 2027 (3 nights).
- Hotel Solenne, Downtown, $250 a night (Day 2 reprices $250 → $255).
- Osteria Lume, live-fire Italian, chef's table on Fri, Jan 1, 2027 (Day 3's one fixed date).
- Returning customer's plans: "Your trip in Houston" (Stay + Dining booked) and "Your stay at Kesselhorn Lodge" (Stay booked).

## iPhone Duo
- Follow Apple's HIG "Designing for iPhone Duo" (summarized in the spec, section 2). Compact layout on the outer display, regular (split) on the inner display; standard toolbars so controls move to the side bar; nothing in the folding region; same state across displays.
- Duo previews run in Xcode's Device Hub. Claude Code's simulator pane works with Xcode 26.x but not yet with Xcode 27, so Duo screens need a manual look in Device Hub.

## Day 1 requirements (transcribed from the requirements slide)
Build the landing page top to bottom with personalized entry, chat search, Travel carousel, Book Now tiles, and My plans. Booking details are covered on Days 2–5.

1. **Top of page**
   - Header: Lifestyle logo, points balance (e.g., 12,450 pts), and cart icon.
   - Showcase points balance and card value prop for the signed-in customer (POC: "Earn 5X on Hotels, with Autograph Journey").
   - Profile banner: "Personalize your experience" with a Create profile button, only for customers without a travel profile. Create profile starts profile setup (Day 5).
2. **Concierge**
   - Search box below the hero: "What do you want to do?" Tapping it opens a guided chat with inspire-me prompts.
   - Chat accepts plain-language requests, e.g., "Find a great hotel near great food"; asks follow-ups (budget, vibe, dining, dates); answers with hotel and dining picks and the reason for each.
   - Handoff: each pick opens its booking flow (hotel: Day 2); no checkout in chat.
3. **Tabs + carousel**
   - Four tabs: Travel, Entertainment, Dining, Exclusives; default Travel. Entertainment and Exclusives are display only (not in the POC). Customer can switch tabs at any time.
   - Travel cards (hotels): scroll sideways; 3 cards, each with image, title, subtitle. Caribbean Beach Hotel opens an embedded hotel booking screen; Alpine Adventure opens a hotel at a ski resort; Big City Nights opens flight booking to NYC (not in POC).
   - Dining cards (events): order Houston, NYC, Miami. Each record: name, city, chef, cuisine, menu, imagery, address.
4. **Book now**
   - Tiles that remain on the page throughout: Hotels, Flights, Cars, Cruises, Experiences, Events.
   - Each tile opens a real booking flow (Days 2 and 3: Hotel and Dining POC only). Keep Book now separate from chat search.
5. **My plans**
   - Below Book now. Each plan shows trip name and dates with status tiles: Stay, Travel, Dining, Experience.
   - Selecting a plan opens My Trip (Day 4). Show hotel and dining bookings in the plan once booked (Days 2–3).
   - Empty state when the customer has no plans.

**Day 1 is complete when** the page loads each section independently; the chat returns hotel and dining picks that open Days 2–3; the Travel carousel opens Day 2; Book now tiles and My plans work.

**Not included:** cart and checkout; Entertainment and Exclusives content.
