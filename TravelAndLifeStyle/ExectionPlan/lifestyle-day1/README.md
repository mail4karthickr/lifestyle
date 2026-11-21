# Lifestyle · Day 1 handoff for Claude Code

## Use it
1. Unzip into an empty folder, e.g. `~/code/LifestyleDay1`.
2. In the Claude desktop app, open the **Code** tab and start a local session on that folder (or run `claude` in it from Terminal).
3. Paste the one prompt from PROMPTS.md.

## What's inside
| Path | What it is |
|---|---|
| CLAUDE.md | Instructions Claude Code loads in every session |
| PROMPTS.md | One hands-off prompt, plus step-by-step prompts |
| docs/decisions.md | Decisions from the design session, and the Day 1 requirements transcribed |
| docs/day1-spec.md | The spec: layouts per device and pose, tokens, components, navigation, loading, motion, accessibility, acceptance |
| docs/sample-data.json | All POC content and the scripted Concierge conversation |
| design/screens/ | 20 PNG screenshots of the target screens (2x) |
| design/artboards/ | The same 20 screens as HTML with exact values |
| design/assets/ | 14 images used in the screens |

## Screens
| Screen | iPhone | iPhone Duo |
|---|---|---|
| Landing, new customer | iPhone-Landing | Duo-Closed-Landing, Duo-Closed-Landing-Scrolled, Duo-Open-Landing |
| Landing, returning customer | iPhone-Landing-Returning | Duo-Closed-Landing-Returning, Duo-Closed-Landing-Returning-Scrolled, Duo-Open-Landing-Returning |
| Landing, sections loading | iPhone-Landing-Loading | — |
| Landing, book pose | — | Duo-Book-Landing |
| Concierge 1 · start | iPhone-Concierge-Start | Duo-Closed-Concierge-Start, Duo-Open-Concierge-Start |
| Concierge 2 · follow-ups | iPhone-Concierge-Questions | Duo-Closed-Concierge-Questions, Duo-Open-Concierge-Questions |
| Concierge 3 · picks | iPhone-Concierge-Picks | Duo-Closed-Concierge-Picks, Duo-Open-Concierge-Picks, Duo-Tabletop-Concierge |
