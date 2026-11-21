# Prompts for Claude Code — Day 1

## One prompt (hands-off)
Paste this into a Claude Code session opened on this folder:

> Read CLAUDE.md, docs/decisions.md and docs/day1-spec.md, and look at every image in design/screens. Make a plan for the Day 1 Lifestyle feature, then build it step by step: project setup, Theme.swift and data models, components, the landing page (compact, then regular width and iPhone Duo), the loading states, then the Concierge. After each step, build and run in the iOS Simulator and compare with the matching screenshot; fix differences before moving on. Finish by walking the spec's navigation map and acceptance criteria and listing anything left.

## Step by step (more control)
Use these instead if you'd rather review each stage.

0. **Plan** (plan mode: Shift+Tab until "plan mode on")
   > Read CLAUDE.md, docs/decisions.md and docs/day1-spec.md, and look at design/screens. Propose the file structure and a step-by-step plan. Don't write code yet.
1. **Project, theme, data**
   > Create the LifestyleDay1 SwiftUI project if it doesn't exist. Add Theme.swift with the tokens from spec section 3, add design/assets to the asset catalog, and load docs/sample-data.json into Codable models.
2. **Components**
   > Build the components in spec section 4 as reusable views with previews.
3. **Landing, compact**
   > Build the landing page for compact width in the spec's order. Match design/screens/iPhone-Landing.png and Duo-Closed-Landing.png. Wire tabs, carousels and the navigation stubs from section 5.
4. **Loading**
   > Give hero points, the carousel and My plans their own models and mock services, per section 6. Match iPhone-Landing-Loading.png; add the My plans error with Try again.
5. **Landing, regular width + iPhone Duo**
   > Adapt the landing page to regular width as a split arrangement per section 2. Match Duo-Open-Landing.png, Duo-Open-Landing-Returning.png and Duo-Book-Landing.png. Close and Cart are standard toolbar items. Keep tab and scroll state across size changes.
6. **Concierge**
   > Build the simulated Concierge from the script in sample-data.json: start, follow-up card with working chips, picks with reasons, handoff stubs. On regular width add the trailing pane (Inspire me → live trip brief → picks). Match the Concierge screenshots, including Duo-Tabletop-Concierge.png.
7. **Check**
   > Build and run on an iPhone simulator. Walk every row of the navigation map and the acceptance criteria, compare each screen with design/screens, and list anything that doesn't match.

For iPhone Duo, open the app in Xcode's Device Hub (closed, open, book, tabletop) and paste screenshots of anything off into the session with the matching screen name.
