# Lifestyle (Travel & Lifestyle) — hackathon POC

A Lifestyle section inside the retail banking iOS app: a landing page and a simulated Concierge chat. Built one day at a time; the current day is **Day 1 (Landing page + Concierge)**, for **iPhone and iPhone Duo**.

## Read first
- @docs/decisions.md — context and decisions from the design session, plus the Day 1 requirements
- @docs/day1-spec.md — what to build: layouts, tokens, components, navigation, loading, acceptance
- `design/screens/*.png` — the target screens (look at them before building each screen)
- `design/artboards/*.dc.html` — the same screens as HTML with exact values (ignore their template tags and scripts)
- `docs/sample-data.json` — all POC content and the Concierge script
- `design/assets/*.webp` — images used by the designs

## Stack and conventions
- Swift + SwiftUI app target named `LifestyleDay1`. If there's no Xcode project yet, create one (XcodeGen via Homebrew is fine).
- One adaptive layout driven by size classes; no device checks, no fixed widths.
- Standard `NavigationStack` and `.toolbar`, so iPhone Duo moves controls to the side bar. Every toolbar item is a `Label` (title + SF Symbol).
- All design tokens in `Theme.swift` (colors, type, radii, materials). No hex values in views.
- Hero points, the carousel and My plans each get their own `@Observable` model (`loading | loaded | failed`) and a mock service with a delay and a failure switch.
- Concierge is scripted from `sample-data.json`; no network calls.
- Day 2–5 destinations are stub views with a title, so every tap goes somewhere.
- `#Preview`s for compact and regular width, new and returning customer, loading and failed.

## How to work
- Plan first, then build in small steps. Build after every step and fix all errors and warnings before moving on.
- After each screen, run the app in the iOS Simulator, take a screenshot and compare it with the matching PNG in `design/screens/`. Fix differences before continuing.
- Don't add features beyond the spec. If something is unclear, ask.
