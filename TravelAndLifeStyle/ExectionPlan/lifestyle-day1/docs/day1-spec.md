# Lifestyle · Day 1 spec — Landing page + Concierge

Source of truth for the Day 1 build. Target screens are in `design/screens/` (PNG, 2x); the same screens as HTML, with every exact value (colors, sizes, spacing, radii), are in `design/artboards/`. Decisions and the original Day 1 requirements are in `docs/decisions.md`. Sample content is in `docs/sample-data.json`. Images are in `design/assets/`.

The `.dc.html` files are design references, not code to port: ignore their `{{ }}` template holes, `<sc-if>`/`<sc-for>` tags and the `DCLogic` script. Read them for values and structure.

## 1. Scope

In Day 1:
- Landing page, top to bottom: header, hero (points + card value prop), profile banner, Concierge search box, tabs + carousel, Book now tiles, My plans.
- Concierge: guided chat that is **simulated** (scripted, no live AI): start → follow-up questions → hotel + dining picks with a reason each.
- Every section loads independently, with its own loading and error state.

Not in Day 1: cart and checkout (cart icon only), Entertainment and Exclusives content, the booking flows themselves (Days 2–3), My Trip (Day 4), profile setup (Day 5). Their entry points exist and are stubbed.

## 2. Platforms and adaptive layout

One adaptive SwiftUI layout, driven by size classes. No per-device code paths.

| Environment | Size class | Layout |
|---|---|---|
| iPhone | compact width | single scrolling column |
| iPhone Duo, closed (outer display) | compact width | single column; toolbar on the trailing side bar |
| iPhone Duo, open, landscape (inner display) | regular width | split arrangement: leading + trailing panes; toolbar on the trailing side bar |
| iPhone Duo, open, portrait / tabletop | regular width | split stacks vertically; standard horizontal bars |

iPhone Duo rules (Apple HIG, "Designing for iPhone Duo"):
- Use standard `NavigationStack` + `.toolbar` so the system moves toolbar items to the side bar automatically. Don't override bar placement.
- Toolbar order on the side bar: primary navigation first (Close on Landing, Back in Concierge), then actions (Cart; New chat).
- Give every toolbar item a title and a symbol (`Label`). Text-only buttons stay in a horizontal bar, so the logo and points pill live in the content, not the toolbar.
- Account for asymmetry: content is inset on the side-bar edge; read safe-area insets, never hard-code.
- Open display: lay the page out as a split arrangement (`ArrangementView`, split). Leading = logo row, hero, profile banner, search, tabs, carousel. Trailing = Book now, My plans. Concierge: leading = chat, trailing = context pane (Inspire me → trip brief → picks).
- Partially folded (book pose): panes become equal width and mirror the side-bar margin; nothing sits in the folding region. Use `ReservedRegion` for anything custom the system doesn't move. Grids that span the fold use an even number of columns.
- Tabletop: picks on the upright half, chat + composer on the flat half.
- Keep state identical across displays: selected tab, scroll position, chat thread and chip selections survive opening/closing.
- The hero image may run full width behind the side bar; scrolling content stays inset.

Geometry used in the designs (points; illustrative — real values come from safe areas and reserved regions at runtime):
- Outer display 466×678. Side bar: 48 wide, 24 from the trailing edge, centered under the camera; toolbar items start ~169 from the top (camera + status above). Content inset: leading 20, trailing 84.
- Inner display 951×669 landscape. Fully open panes: leading 439, trailing 392, gap 16. Book pose: both panes 363, folding region ≈ 40 centered on the hinge.
- iPhone 402×874; margins 16; floating header at y 58.

## 3. Design tokens (match the retail app)

Colors

| Token | Hex | Use |
|---|---|---|
| ink | #141414 | primary text |
| ink2 | #3B3331 | secondary text, icons |
| muted | #665E5C | tertiary text, placeholders |
| background | #F4F0ED | page (with the app's faint diagonal facets) |
| red | #D71E28 | primary CTA, active state, brand tile |
| purple | #5A469B | links, Concierge, secondary CTA (pressed #46348D) |
| purple2 | #6048AD | selected chips, focus |
| yellow | #FFCD41 | points coin |
| green / mint | #026F43 / #E5FAF3 | booked status |
| magenta | #C440A4 | Events tile |
| amber | #5C3A00 | text on yellow |
| hairline | rgba(20,20,20,0.10) | dividers |

Type — "Wells Fargo Sans" (fallback in the designs: Source Sans 3). Titles are regular weight, like the app.

| Style | Size/line | Weight |
|---|---|---|
| large title | 30/36 | 400 |
| title 1 | 26/32 | 400 |
| section | 20/25 | 600 |
| card title | 19/24 | 600 |
| headline | 17/22 | 600 |
| body | 16/22 | 400 (600 for emphasis) |
| subhead | 15/20 | 400/600 |
| footnote | 13/18 | 400/600 |
| caps label | 12/16 | 600, tracking 0.06–0.08em |

Support Dynamic Type: map to the closest text styles and let layouts grow.

Materials (glass)
- Card: white 80%, 1pt white-95% border, shadow 0/4/14 rgba(59,51,49,0.08). Radius 20.
- Floating controls (header buttons, side bar, search, composer, tab chrome): Liquid Glass (`.glassEffect`) or white 72% + blur 24 + saturation 170%, white-92% border, shadow 0/12/34 rgba(59,51,49,0.18).
- Frost panel over imagery (hero value panel, image tags): white 82% + blur.
- Ambient background: #F4F0ED with very soft yellow, red and purple radial glows that drift slowly.

Radii: pills 999 · cards 20 · tiles 18 · hero 24 (in a pane) / bottom corners 32 (full bleed) · thumbnails 12–14 · status tiles 12.
Touch targets ≥ 44. Glass icon buttons 44 (iPhone header) / 48 (Duo side bar).

## 4. Components

- **Header** — iPhone: floating row over the hero: Close (glass circle) · brand pill (red 30pt logo tile + "Lifestyle") · spacer · points pill (yellow coin + "12,450 pts") · Cart (glass circle). Duo: brand + points pill in the content; Close and Cart in the side bar.
- **Hero** — image (beach) with a frost panel at the bottom: card art · "Earn 5X points on hotels" / "with your Autograph Journey card" · divider · coin + "12,450 pts" + "$124.50 in travel value". A slow sheen sweeps the panel. Heights: iPhone 300 (full bleed), Duo closed 232 (full bleed), Duo open 190 (230 without the banner), book pose 170.
- **Profile banner** — only when the customer has no travel profile. "Personalize your experience" / "Create your travel profile." + outline purple "Create profile" (→ Day 5 stub). 64 tall.
- **Search box** — glass pill 56: purple circle with sparkle (gentle pulse) · "What do you want to do?" · mic glyph. Tap → Concierge start.
- **Tabs** — Travel (default), Entertainment, Dining, Exclusives. Underline style: 44 tall, 3pt ink underline on the active tab, 22 gap. Switchable at any time. Entertainment/Exclusives show a "{Tab} is coming soon" card at the carousel's height (no layout jump).
- **Travel carousel** — horizontal, snapping, peeks the next card. Card: image + title + subtitle. Sizes (width × image height): iPhone 260×150, Duo closed 230×112, Duo open 210×100, book pose 230×100.
- **Dining carousel** — Houston, New York, Miami, in that order. Card: image with date tag (top) and menu tag (bottom) · event name · cuisine · chef · venue + address (pin). Width +10 vs travel.
- **Book now** — section title + 3-column grid of 6 tiles (Hotels, Flights, Cars, Cruises, Experiences, Events): tinted icon circle + label. Tile height: iPhone 92, Duo 84–88. Always on the page, outside the tabs.
- **My plans** — section title (+ "See all" when there are plans). Plan card: 56 thumbnail · trip name · dates · chevron, then 4 status tiles (Stay, Travel, Dining, Experience); booked = mint with green check badge, not booked = grey. Empty state: "No plans yet" / "Stays and tables you book show up here." + "Plan with Concierge" link.
- **Skeletons / errors** — shimmer blocks shaped like the content. My plans error: "Couldn't load your plans" / "Everything else on this page is up to date." + "Try again".
- **Concierge** — large regular greeting; "INSPIRE ME" image cards; right-aligned outlined prompt chips (app style); AI disclosure card; composer (glass, "Start chatting", purple outlined mic). User bubbles purple with white text; Concierge bubbles glass with a purple sparkle avatar.
- **Follow-up card** — "What matters most? Pick any." Dates chip; Budget a night (single select); Vibe (multi); Dining (multi); purple "Show my picks". On the open display, the trailing "Your trip so far" brief updates live as chips change.
- **Pick card** — image · STAY/DINING caps label · name · meta · CTA ("View rooms", "Reserve a table") · reason row (sparkle + one-sentence why). The whole compact card is tappable; on the open display the CTA is a red button. "Nothing is booked or charged in chat."

## 5. Navigation map

| From | Action | To |
|---|---|---|
| Landing | Close | back to the retail app (Explore) |
| Landing | Cart | no-op in POC |
| Landing | Search box | Concierge start |
| Landing | Create profile | Day 5 stub |
| Carousel | Caribbean Beach Hotel / Alpine Adventure | Day 2 hotel booking stub |
| Carousel | Big City Nights | not in POC (no-op) |
| Dining | Houston event | Day 3 reserve-a-table stub |
| Book now | Hotels / Events | Day 2 / Day 3 stubs; other tiles no-op |
| My plans | plan card | Day 4 My Trip stub |
| Concierge start | "Find a great hotel near great food" / food inspire card | follow-ups |
| Follow-ups | Show my picks | picks |
| Picks | View rooms / Reserve a table | Day 2 / Day 3 stubs (no checkout in chat) |

## 6. Loading model

Header, profile banner, search, tabs and Book now render immediately (local/static). Three sections load on their own, each with its own skeleton and error: hero points (rewards), carousel content, My plans (bookings). One failing never blocks the others. Build each as its own view model with an async load and a `state: loading | loaded | failed`; mock services with different delays for the demo.

## 7. Motion (subtle; honor Reduce Motion)

- Sections rise in (12pt, fade from 55%) with ~150ms stagger as each loads.
- Hero sheen sweep every ~6s; ambient glows drift over 14–23s.
- Concierge sparkle pulses gently; typing indicator = three dots.
- Chips and tabs cross-fade color in 0.25s; press scales to 0.97.
- Carousels snap.

## 8. Accessibility

Real buttons/links; labels on icon buttons ("Close", "Cart", "Back", "New chat", "Speak"); plan cards read "{trip}, {dates}. Opens My Trip"; contrast ≥ 4.5:1 (all token pairs above pass); Dynamic Type; VoiceOver order follows the visual order; selected chips/tabs expose selected state.

## 9. Day 1 is complete when

The page loads each section independently; the chat returns hotel and dining picks that hand off to Days 2–3; the Travel carousel opens Day 2; Book now tiles and My plans work; all of it adapts across iPhone, Duo closed, Duo open, book pose and tabletop without losing state.
