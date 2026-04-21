# SLine Design System — Final Synthesis & Master Direction

## Internal Verdict (Pre-Synthesis Assessment)

**Which report is strongest overall?** Report 3. By a significant margin. It is the only report that reads like it was written by someone who has actually shipped a design system in Flutter. It names specific components, defines specific pixel values, provides actual Dart code, and makes opinionated decisions backed by concrete reasoning. It is not theoretical — it is buildable.

**Which report has the best color system?** Report 3. It builds a proper tonal family per hue (teal 50-900, amber 50-700, indigo 50-600), provides dark-mode-specific variants per hue, and defines a warm-neutral base that avoids the cold blue-gray trap. Report 1 has a defensible color direction but provides reference-level tokens without a full tonal palette. Report 2 uses Tailwind-adjacent grays (#111827, #4B5563, #9CA3AF) that are generic and cold.

**Which report has the best typography system?** Report 3. It selects Plus Jakarta Sans with clear reasoning (geometric + humanist, not Inter, not Roboto), provides an 11-step scale with specific sizes/weights/line-heights/tracking for every role, and explains *why* each weight was chosen. Report 2 has useful Arabic scaling notes (15-20% increase, 1.8 line-height) worth extracting. Report 1's Noto Sans recommendation is sensible but conservative.

**Which report has the best component philosophy?** Report 3. It defines every component — primary button, secondary button, destructive button, text button, FAB, input, search bar, segmented control, tab bar, filter chip, bottom nav, top nav, card variants, chat bubbles, offer card, bottom sheet, settings row, notification item, empty state, skeleton loader, avatar, toggle — with exact heights, radii, colors, and states. No other report comes close to this level of specification.

**Which report has the best screen architecture?** Report 3. It provides screen-by-screen layouts for every major screen (Home, Tenders, Tender Detail, Bookings, Booking Detail, Create Task, Chat, Messages List, Dashboard, Wallet, Profile, Settings, Saved, Notifications, Search) with specific layout decisions. Report 1 provides screen guidelines but they are more abstract. Report 2 provides screens but in a verbose, adjective-heavy style with fewer concrete layout decisions.

**Which report has the best implementation realism?** Report 3. It provides actual Dart code (primitives class, ThemeExtension class, factory constructors for light/dark, widget access pattern, ThemeData assembly), a realistic file structure, and a phased migration plan that accounts for side-by-side comparison with old themes. Report 1 provides JSON token structure and a sensible migration order but no code. Report 2 provides a high-level migration timeline but it is unrealistically compressed (9 weeks for everything) and lacks code.

**Which report has the weakest parts?** Report 2. It contains the most noise: "post-neumorphic glassmorphism," "Bento Grid modularism," floating pill-shaped bottom navigation, "spring-based physics for interactive components," and extensive prose that sounds impressive but actively harms implementation. The glassmorphism direction conflicts with the stated goal of a calm, trustworthy marketplace. The Bento Grid suggestion adds visual complexity without solving a real problem. The floating nav bar is a Dribbble pattern that fails in production (wasted screen space, unclear tap targets, rendering issues on lower-end Android). Report 2 also uses a green/emerald primary (#2D6A4F / #52B788) that abandons SLine's existing teal brand identity without justification.

---

## 1. Executive Verdict

Report 3 is the winner. It is not close. Reports 1 and 2 both contain useful ideas, but Report 3 is the only one that functions as a complete, implementable design system specification. It makes specific, opinionated decisions; it provides exact values; it delivers Dart code; and its choices are grounded in product reality rather than design trend vocabulary.

Report 1 is the second strongest. It has good strategic thinking, correct accessibility awareness, and a solid philosophical framework. But it stays at the semantic/conceptual level too often and does not descend to component-level specification. It is a good brief, not a design system.

Report 2 is the weakest. It mistakes complexity for sophistication. Its glassmorphism direction, Bento Grid obsession, floating nav bar, and spring-physics motion system are all ideas that sound premium in a case study but create implementation nightmares and usability problems in production. Its prose is 40% longer than the other reports while delivering less actionable information. The emerald/sage color pivot abandons SLine's brand for no defensible reason.

**Final synthesis approach:** Report 3 forms 85% of the final system. Report 1 contributes accessibility depth and a few refined token-naming ideas. Report 2 contributes exactly two things: the Arabic typography scaling rules and the observation about avoiding pure black on OLED. Everything else from Report 2 is rejected.

---

## 2. Overall Ranking of the 3 Reports

| Rank | Report | Strength | Fatal Weakness |
|------|--------|----------|----------------|
| 1st | Report 3 | Complete, specific, buildable, opinionated | Minor: screen edge padding of 20px is debatable |
| 2nd | Report 1 | Good philosophy, good accessibility, correct M3 alignment | Stays abstract — not enough component-level spec |
| 3rd | Report 2 | Some useful RTL/Arabic insights | Glassmorphism direction is wrong for the product; verbose with low actionable density |

---

## 3. Brutal Critique of Report 1

**What it gets right:** The "Reduce anxiety, increase confidence" philosophy is excellent and should be the north star. The accessibility section is the strongest of all three reports — it explicitly calls out non-text contrast requirements (3:1 for interactive boundaries), which Reports 2 and 3 mention but don't emphasize as strongly. The "Porcelain + Ink + Jade" direction name is evocative and correct. The semantic token layering (ref / sys / comp) is architecturally sound. The migration order (Wallet/escrow first, then bookings/tenders, then chat, then discovery) is smart — it prioritizes trust-sensitive screens.

**What it gets wrong:** It never descends from philosophy to specifics. "Cards: Replace border-heavy cards with surface containers + spacing" is a principle, not a spec. What height? What padding? What border? What radius? A developer cannot build from Report 1 without making 200 decisions that Report 1 punted on. The color palette lacks tonal depth — it provides 7-8 key hex values but not a complete palette that covers all component states. The typography recommendation (Noto Sans) is safe but characterless — Noto is a fallback font family designed to cover every script, not to be a brand statement. The spacing scale (0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64) has 12 values including 2px, which is too granular and creates decision paralysis. The motion durations (80ms, 140ms, 220ms, 320ms) are oddly specific without explanation. The radius scale (8, 12, 16, 24, 999) is too narrow — it lacks both a micro value (4px for badges) and a value between 16 and 24.

**Verdict on Report 1:** Good brief, insufficient spec. Use its philosophy and accessibility depth; reject its specifics wherever Report 3 provides better ones.

---

## 4. Brutal Critique of Report 2

**What it gets right:** The observation about OLED smearing with pure black is correct and worth integrating. The Arabic typography scaling guidance (15-20% larger, 1.8-2.0 line-height) is the most specific RTL typographic recommendation across all three reports. The semantic token naming convention (Category.Component.Variant.Property) is well-structured, though overly enterprise-heavy for a Flutter app. The observation that the legacy #888888 muted text is too bright on some surfaces and too dim on others is a precise, useful critique.

**What it gets wrong — and there is a lot:**

1. **Glassmorphism is wrong for this product.** Frosted glass surfaces require `BackdropFilter` in Flutter, which is expensive on low-end Android devices common in Iraq. More importantly, glassmorphism creates variable text contrast depending on what's behind the blur — a direct contradiction of the WCAG requirements the report itself advocates. It looks great in Figma mockups; it fails in production.

2. **Bento Grid is a layout fad, not a system.** "Asymmetric, modular blocks" sound editorial, but in a marketplace app where cards display jobs, bookings, and financial data, consistent card layouts are more important than visual variety. Bento Grids make scanning harder because the eye cannot predict where the next item will be. This is exactly the wrong approach for a marketplace.

3. **The floating pill-shaped bottom navigation is a Dribbble trap.** It wastes 32px+ of vertical space (16px float above bottom + 16px margin), creates an ambiguous touch zone below the nav (users tap the gap thinking they'll hit the nav), and on Android with gesture navigation, the bottom-of-screen swipe zone conflicts with a floating element. Every production app that tried this has either reverted to a grounded nav or added workarounds that negate the aesthetic benefit.

4. **The emerald/sage color pivot (#2D6A4F / #52B788) abandons the brand.** SLine has a teal identity. Report 2 switches to forest green without acknowledging this is a brand change, not just a palette refinement. The justification ("muted greens convey wealth") is color-psychology pseudoscience that does not survive contact with real users.

5. **Inter is the most generic font choice possible.** Half of all modern SaaS products use Inter. Choosing Inter for SLine guarantees it looks like every other product. This is the opposite of "distinctive."

6. **The prose-to-signal ratio is terrible.** Phrases like "methodically shedding the enterprise-heavy noise, aggressive outlines, and jarring color palettes of the past" and "a digital sanctuary for freelance commerce" add zero actionable information. The report is ~30% longer than Report 3 while defining fewer concrete specifications.

7. **The migration timeline (9 weeks) is unrealistic.** "Weeks 4-5: Rebuild buttons, inputs, badges, and chat bubbles" and "Weeks 6-8: Replace legacy UI screens" implies rebuilding 20+ screens in 2-3 weeks, which is fantasy.

**Verdict on Report 2:** Reject the visual direction entirely. Extract only the Arabic scaling rules and the OLED observation. Discard everything else.

---

## 5. Brutal Critique of Report 3

**What it gets right (most things):**
- The diagnosis of the legacy system is devastatingly accurate: 22 near-black backgrounds, 17 font sizes, 13+ radius values, teal-on-everything.
- The "Structured Warmth" direction is the correct creative choice. It's premium without being cold, modern without being trendy, and distinctive without being risky.
- The teal palette (#0E9E9E as the new primary, with a full 50-900 tonal scale) is well-calibrated.
- The amber (tender) and indigo (booking) semantic secondaries are a genuinely good system design decision that no other report proposes. This gives users a visual vocabulary: amber = opportunity, indigo = commitment, teal = action.
- The "four dark surfaces only" rule is exactly right and solves the 22-background problem with brutal simplicity.
- The component specifications are production-ready.
- The actual Dart code with ThemeExtension is immediately usable.
- The migration plan is phased, realistic, and includes a rollback strategy (keep old theme for 30 days behind a flag).

**What it gets slightly wrong or could improve:**
- **Screen edge padding of 20px** is an odd choice. 16px is the Material 3 standard; 24px is the generous alternative. 20px sits between the two and will require a custom override everywhere, since M3 defaults to 16. This creates friction. Recommendation: use 16px as the standard, 24px for breathing room on detail screens — not 20px.
- **Plus Jakarta Sans** is a good choice but the report should acknowledge it is not a Google Fonts default in Flutter — it needs to be bundled or loaded. This is a minor implementation note but matters for offline support and initial load performance.
- **The radius scale has 7 values** (4, 8, 12, 16, 20, 28, 9999). The 28px value (radius.2xl) is questionable — when would you use 28px instead of 20px or 9999? In practice, the search bar at radius.xl (20px) already looks pill-shaped at 48px height. Recommend collapsing to 6 values by removing radius.2xl.
- **The motion system lacks a spring specification** for the FAB and modals. The report mentions spring easing but only provides stiffness: 300, damping: 28 without explaining whether this is a Flutter `SpringDescription` or a conceptual reference. This should be made explicit.
- **Arabic font pairing (IBM Plex Sans Arabic)** is a strong recommendation but the report lacks the explicit scaling rules that Report 2 provides. Arabic text at the same pixel size as Latin text looks optically smaller. The report should specify a scale multiplier.

**Verdict on Report 3:** This is the foundation. Fix the minor issues, incorporate Arabic scaling from Report 2 and accessibility depth from Report 1, and this becomes the final system.

---

## 6. Comparative Score Matrix

| Category | R1 | R2 | R3 | Winner |
|---|---|---|---|---|
| 1. Quality of design thinking | 8 | 6 | 9 | R3 |
| 2. Originality | 6 | 7 | 8 | R3 |
| 3. Strategic fit for SLine | 8 | 5 | 9 | R3 |
| 4. Premium feel | 7 | 7 | 8 | R3 |
| 5. Simplicity | 8 | 4 | 9 | R3 |
| 6. Readability | 8 | 6 | 9 | R3 |
| 7. Hierarchy clarity | 7 | 6 | 9 | R3 |
| 8. Mobile-first usability | 7 | 5 | 9 | R3 |
| 9. Trust-building potential | 8 | 6 | 9 | R3 |
| 10. Distinctiveness | 6 | 7 | 8 | R3 |
| 11. Color system quality | 6 | 5 | 9 | R3 |
| 12. Dark mode quality | 6 | 6 | 9 | R3 |
| 13. Light mode quality | 7 | 6 | 9 | R3 |
| 14. Typography quality | 6 | 6 | 9 | R3 |
| 15. Spacing system quality | 6 | 7 | 9 | R3 |
| 16. Token system quality | 7 | 7 | 9 | R3 |
| 17. Component system quality | 4 | 5 | 10 | R3 |
| 18. Layout system quality | 5 | 6 | 9 | R3 |
| 19. Screen architecture quality | 6 | 6 | 9 | R3 |
| 20. Motion philosophy quality | 7 | 5 | 8 | R3 |
| 21. Accessibility awareness | 9 | 7 | 8 | R1 |
| 22. RTL / Arabic readiness | 7 | 8 | 7 | R2 |
| 23. Flutter / M3 implementation realism | 7 | 5 | 10 | R3 |
| 24. Scalability into real design system | 7 | 5 | 9 | R3 |
| 25. Risk of visual noise | LOW | HIGH | LOW | R1/R3 |
| 26. Risk of generic output | MED | HIGH | LOW | R3 |
| 27. Risk of inconsistency | MED | HIGH | LOW | R3 |
| 28. Long-term product maturity | 7 | 4 | 9 | R3 |

**Summary:** Report 3 wins 25 of 28 categories. Report 1 wins accessibility. Report 2 wins RTL/Arabic readiness.

---

## 7. Best Ideas from Report 1

1. **"Reduce anxiety, increase confidence"** — the single best design philosophy statement across all three reports. Adopted as the north star.
2. **Non-text contrast requirement (3:1 for interactive boundaries)** — explicitly called out and should be a hard rule.
3. **"Stroke.interactive must satisfy non-text contrast"** — the distinction between decorative borders and functional interactive boundaries is valuable.
4. **Migration order (wallet/escrow first)** — correct prioritization of trust-sensitive screens. Adopted.
5. **"Accent is earned"** — the principle that brand color appears only where action is possible. This aligns with Report 3's anti-rules.
6. **Dynamic color as an optional layer** — the suggestion to support Android 12+ dynamic color with brand fallback is worth noting for future enhancement.
7. **Tabular numerals for wallet and pricing** — a specific typographic detail that the other reports miss. Critical for financial UI.

---

## 8. Best Ideas from Report 2

1. **Arabic text scaling multiplier (15-20%)** — the most specific RTL typographic guidance. Adopted at 1.15x.
2. **Arabic line-height (1.8-2.0)** — necessary for diacritics clearance. Adopted at 1.8.
3. **OLED smearing observation** — pure black scrolling causes visible smearing on OLED panels. Confirms Report 3's dark surface approach.
4. **"Color cannot be the sole communicator of state"** — the requirement to pair color with icon/label for accessibility. Reinforces a rule already in Report 3.

That is all. Everything else from Report 2 is rejected.

---

## 9. Best Ideas from Report 3

Essentially the entire report. The key standouts that define the final system:

1. **Tri-color semantic system:** teal = action, amber = tender/opportunity, indigo = booking/commitment. This is the single most valuable design decision across all three reports.
2. **Four dark surfaces only:** base, container, raised, high. Solves the 22-background disaster.
3. **Warm-neutral base** (#FAFAF8 range) instead of cold blue-gray or pure white.
4. **"Components Know Their Role"** philosophy.
5. **Complete tonal palette per hue** (50-900 for teal, amber, indigo, neutral).
6. **Full component specification** with exact heights, radii, colors, and state definitions.
7. **Actual Dart code** with ThemeExtension pattern.
8. **Phased migration plan** with rollback strategy.
9. **Plus Jakarta Sans** font recommendation with clear reasoning.
10. **"No font weight above 700"** — a rule that solves the weight-900-everywhere problem.

---

## 10. Weak Ideas That Must Be Rejected

| Idea | Source | Reason for Rejection |
|---|---|---|
| Glassmorphism / frosted glass surfaces | R2 | Expensive in Flutter (BackdropFilter), variable contrast, fails WCAG on dynamic backgrounds |
| Bento Grid layouts | R2 | Harms scannability in a marketplace; adds complexity without solving a real problem |
| Floating pill-shaped bottom navigation | R2 | Wastes vertical space, creates ambiguous tap zones, conflicts with Android gesture nav |
| Emerald/sage primary color (#2D6A4F) | R2 | Abandons SLine's teal brand identity without justification |
| Inter as the font choice | R2 | Too generic; used by half of all modern SaaS products |
| Spring-based physics for all interactive components | R2 | Overly complex, performance concern on low-end devices, unnecessary for most interactions |
| Noto Sans as the primary Latin font | R1 | Too conservative; it is a coverage font, not a brand font |
| 80ms / 140ms / 220ms / 320ms motion scale | R1 | Arbitrary increments; Report 3's 0/100/200/350/500 is cleaner |
| Spacing scale with 12 values including 2px | R1 | Too many values; 2px is never used in practice as layout spacing |
| Ivory + Ink + Subtle Brass direction | R1 | Brass accent risks "fintech" feel; unnecessary complexity |
| "Calm Commerce" as a philosophy name | R2 | Sounds like a marketing deck, not a design system; the actual philosophy it describes is weaker than Report 1's or Report 3's |
| "Post-Neumorphic" anything | R2 | Neumorphism failed in production 3 years ago; adding "post-" does not resurrect it |
| 44x44dp for ALL touch targets as absolute minimum | R2 | Material 3 specifies 48x48dp recommended; 44x44dp is the Apple HIG floor. The final system should specify 48dp as target with 44dp as absolute minimum |
| 9-week migration timeline | R2 | Unrealistic for a 20+ screen app with full component rebuild |
| "Conveying wealth through muted green" | R2 | Color psychology is not a reliable design foundation |

---

## 11. Final Selection Logic

The final system is Report 3 with three surgical additions:

1. **From Report 1:** The "Reduce anxiety, increase confidence" philosophy statement; the non-text contrast rule for interactive boundaries; the wallet/escrow-first migration priority; the tabular numerals requirement.

2. **From Report 2:** The Arabic text scaling multiplier (1.15x) and line-height requirement (1.8); the OLED smearing confirmation.

3. **Corrections to Report 3:** Screen edge padding changed from 20px to 16px standard (with 24px for detail screens); radius.2xl (28px) removed from the scale; explicit Arabic scaling rules added; explicit spring parameters for FAB specified in Flutter terms.

Everything else comes from Report 3 unchanged.

---

## 12. Final Design Philosophy for SLine

**"Reduce anxiety, increase confidence."**

This is the only design philosophy SLine needs. Every decision — color, typography, spacing, motion, component design, screen layout — is evaluated against this single question: does this make the user more confident or less confident?

Five operating principles serve this philosophy:

1. **Calm Authority.** Screens feel settled, not anxious. Generous whitespace, restrained accent color, hierarchy through size and weight contrast.

2. **Purposeful Color.** Color earns its place by communicating something. If removing a color makes the screen less understandable, it belongs. If it only makes it less "designed," it does not.

3. **One Hierarchy, Everywhere.** The most important element is largest and highest contrast. Supporting information is smaller and lower contrast. Metadata is smallest and muted. This never inverts.

4. **Components Know Their Role.** Cards are containers. Buttons are actions. Inputs are invitations. No component is designed for its own sake.

5. **Bilingual by Architecture.** RTL is not bolted on. Every layout uses start/end, not left/right. Every type decision works in both Arabic and Latin.

---

## 13. Final Brand / Emotional Direction

**"Structured Warmth"** — the intersection of a premium productivity tool and a trusted marketplace.

Target feeling: **trusted capability.** Not excitement. Not power. The user opens SLine and feels: "This product knows what it is, doesn't waste my time, and makes the next step obvious."

Visual reference points (for the *feeling*, not the *look*): Wise (financial trust without sterility), Linear (calm productivity without coldness), Airbnb (warm professionalism).

Anti-targets: Fiverr (cluttered auction energy), Upwork (enterprise density), generic dark apps (no personality), Dribbble fantasy UI (not buildable).

---

## 14. Final Color Strategy

**Mono-primary with semantic secondaries.**

- **Teal** is the primary brand color. It appears on primary actions, active state indicators, brand moments, and positive data (prices, stats). One hue, one job: action and trust.
- **Amber** is the tender/urgency semantic. It appears on tender category badges, urgency indicators, and pending states. One hue, one job: opportunity and urgency.
- **Indigo** is the booking/scheduled semantic. It appears on booking category badges, calendar-related elements, and scheduled states. One hue, one job: commitment and reliability.
- **Red** is exclusively destructive: errors, delete confirmations, critical warnings. Never used as a decorative accent.
- **Green** is exclusively positive: success states, completion confirmations, verification badges.

**Anti-rules:**
- Never use teal as both a surface color AND a button color on the same screen
- Never show more than two accent colors simultaneously on a single screen
- Never use #000000 or #FFFFFF as a surface color
- Never express status through color alone — always pair with icon or label
- Never use opacity variants of accent colors as borders — use proper tonal palette values

---

## 15. Final Light Mode Palette

Built on a warm-neutral base (not cold blue-gray, not pure white). The slight warm tint (#FAFAF8) creates quality without going ivory.

```
--- BRAND / TEAL FAMILY ---
brand.teal.50   #E8F7F7   (teal container background)
brand.teal.100  #C5ECEC   (teal subtle border)
brand.teal.200  #96DADA   (teal light)
brand.teal.300  #5EC4C4
brand.teal.400  #2DAEAE
brand.teal.500  #0E9E9E   ← PRIMARY
brand.teal.600  #0B8888   (hover/active on primary)
brand.teal.700  #097272   (pressed state)
brand.teal.800  #075B5B
brand.teal.900  #054444

--- AMBER / TENDER FAMILY ---
brand.amber.50  #FFF8E6   (tender subtle background)
brand.amber.100 #FFEAB8
brand.amber.200 #FFD878   (tender border)
brand.amber.300 #FFC73C
brand.amber.500 #F5A623   ← TENDER PRIMARY
brand.amber.600 #E09000   (tender text on light surfaces)
brand.amber.700 #B87400

--- INDIGO / BOOKING FAMILY ---
brand.indigo.50  #EEF0FF  (booking subtle background)
brand.indigo.100 #D5D9FF
brand.indigo.200 #A8B0FF
brand.indigo.500 #3B4FE8  ← BOOKING PRIMARY
brand.indigo.600 #2C3DCC

--- NEUTRAL FAMILY (warm-tinted) ---
neutral.0    #FFFFFF       (card surfaces)
neutral.50   #FAFAF8       ← APP BACKGROUND
neutral.100  #F3F2F0       (raised surfaces, dividers)
neutral.200  #E8E7E4       (borders, outlines)
neutral.300  #D0CFC9       (inactive borders, disabled fills)
neutral.400  #A8A7A2       (disabled text, placeholders)
neutral.500  #7A7974       (muted text, captions)
neutral.600  #504F4B       (secondary text)
neutral.700  #2E2D2A       (primary body text)
neutral.800  #1A1918       (headings)
neutral.900  #0C0B09       (near-black)

--- SEMANTIC ---
semantic.success     #1A8A5A
semantic.success.bg  #E8F5EE
semantic.warning     #C47A00
semantic.warning.bg  #FFF3D6
semantic.error       #C8372D
semantic.error.bg    #FEECE9
semantic.info        #2655CC
semantic.info.bg     #EBF0FF

--- SURFACE ROLES ---
surface.background   neutral.50   (#FAFAF8)
surface.base         neutral.0    (#FFFFFF) — cards, sheets
surface.raised       neutral.100  (#F3F2F0) — bottom nav, elevated elements
surface.overlay      rgba(12,11,9, 0.48)    — modal backdrop
```

---

## 16. Final Dark Mode Palette

Built on a single tonal surface family with a slight cool-teal lean. Exactly four surface levels — nothing more.

```
--- DARK SURFACES ---
dark.surface.base      #0E1212   ← Page background
dark.surface.container #161C1C   ← Cards, inputs, modals
dark.surface.raised    #1D2626   ← Bottom nav, elevated cards
dark.surface.high      #253030   ← Tooltips, highest surfaces

--- DARK NEUTRALS ---
dark.neutral.0    #0E1212   (darkest)
dark.neutral.100  #161C1C
dark.neutral.200  #1D2626
dark.neutral.300  #253030
dark.neutral.400  #3A4848   ← Borders, dividers
dark.neutral.500  #516060   ← Inactive borders
dark.neutral.600  #7A9090   ← Muted text
dark.neutral.700  #A8BCBC   ← Secondary text
dark.neutral.800  #D4E4E4   ← Primary body text
dark.neutral.900  #EDF5F5   ← Headings, high-contrast text

--- BRAND IN DARK MODE ---
brand.teal.on-dark.active   #2DAEAE   (buttons, active icons)
brand.teal.on-dark.surface  #1A3A3A   (tinted card surfaces)
brand.teal.on-dark.border   #2A4848   (subtle teal borders)
brand.teal.on-dark.text     #5EC4C4   (teal text — 7.2:1 on base)

brand.amber.on-dark.active  #FFB830
brand.amber.on-dark.surface #2A1E00
brand.amber.on-dark.border  #3A2A00
brand.amber.on-dark.text    #FFC84A

brand.indigo.on-dark.active  #8496FF
brand.indigo.on-dark.surface #151A2E
brand.indigo.on-dark.border  #252E4A
brand.indigo.on-dark.text    #9AAEFF

--- SEMANTIC IN DARK MODE ---
semantic.success.dark     #2DBD7A
semantic.success.dark.bg  #0A1E14
semantic.warning.dark     #FFBA36
semantic.warning.dark.bg  #1E1400
semantic.error.dark       #F27066
semantic.error.dark.bg    #1E0B09
semantic.info.dark        #6B8FFF
semantic.info.dark.bg     #0D1428

--- DARK MODE RULES ---
- Exactly four surface levels. No exceptions.
- NO shadows in dark mode. Elevation = tonal stepping only.
- Teal on dark (#2DAEAE on #0E1212) = 7.2:1 contrast. Safe for all uses.
- Primary text on card (#EDF5F5 on #161C1C) = ~12:1. Safe.
- Muted text on card (#7A9090 on #161C1C) ≈ 4.6:1. Safe for non-essential info.
  Never use muted text for essential information.
```

---

## 17. Final Semantic Token System

```
=== TEXT TOKENS ===
color.text.primary          neutral.800 / dark.neutral.900
color.text.secondary        neutral.600 / dark.neutral.700
color.text.tertiary         neutral.500 / dark.neutral.600
color.text.disabled         neutral.400 / dark.neutral.500
color.text.inverse          neutral.0 / dark.neutral.0
color.text.brand            brand.teal.500 / brand.teal.on-dark.text
color.text.danger           semantic.error / semantic.error.dark
color.text.success          semantic.success / semantic.success.dark
color.text.warning          semantic.warning / semantic.warning.dark
color.text.tender           brand.amber.600 / brand.amber.on-dark.text
color.text.booking          brand.indigo.500 / brand.indigo.on-dark.text

=== SURFACE TOKENS ===
color.surface.page          surface.background / dark.surface.base
color.surface.card          surface.base / dark.surface.container
color.surface.elevated      surface.raised / dark.surface.raised
color.surface.overlay       rgba(12,11,9,0.48) / rgba(0,0,0,0.60)
color.surface.brand-subtle  brand.teal.50 / brand.teal.on-dark.surface
color.surface.tender-subtle brand.amber.50 / brand.amber.on-dark.surface
color.surface.booking-subtle brand.indigo.50 / brand.indigo.on-dark.surface
color.surface.danger-subtle semantic.error.bg / semantic.error.dark.bg
color.surface.success-subtle semantic.success.bg / semantic.success.dark.bg

=== BORDER TOKENS ===
color.border.default        neutral.200 / dark.neutral.400
color.border.subtle         neutral.100 / dark.neutral.300
color.border.strong         neutral.300 / dark.neutral.500
color.border.brand          brand.teal.500 / brand.teal.on-dark.border
color.border.danger         semantic.error / semantic.error.dark
color.border.focus          brand.teal.500 / brand.teal.on-dark.active
color.border.interactive    neutral.400 / dark.neutral.500
  (MUST satisfy 3:1 non-text contrast — from Report 1)

=== ACTION TOKENS ===
color.action.primary.default    brand.teal.500 / brand.teal.on-dark.active
color.action.primary.hover      brand.teal.600 / brand.teal.400
color.action.primary.pressed    brand.teal.700 / brand.teal.300
color.action.primary.disabled   neutral.300 / dark.neutral.400
color.action.primary.on         neutral.0 / neutral.0

color.action.secondary.default  color.surface.card
color.action.secondary.border   color.border.default
color.action.secondary.on       color.text.primary

color.action.danger.default     semantic.error.bg / semantic.error.dark.bg
color.action.danger.border      semantic.error / semantic.error.dark
color.action.danger.on          semantic.error / semantic.error.dark

=== STATUS TOKENS ===
color.status.active       { text: teal.600/on-dark.text, bg: teal.50/on-dark.surface, border: teal.200/on-dark.border }
color.status.pending      { text: amber.600/on-dark.text, bg: amber.50/on-dark.surface, border: amber.200/on-dark.border }
color.status.completed    { text: success/success.dark, bg: success.bg/success.dark.bg }
color.status.delivered    { text: info/info.dark, bg: info.bg/info.dark.bg }
color.status.cancelled    { text: neutral.500/dark.neutral.600, bg: neutral.100/dark.neutral.200 }
color.status.danger       { text: error/error.dark, bg: error.bg/error.dark.bg }
```

---

## 18. Final Typography System

**Font:** Plus Jakarta Sans (Latin) + IBM Plex Sans Arabic (Arabic)

**Why Plus Jakarta Sans:** Geometric enough to feel modern and premium, with subtle humanist touches that prevent coldness. Excellent weight range (200-800). Renders well on both iOS and Android at small sizes. Does not look like Inter, does not look like Roboto — it has personality without sacrificing readability.

**Arabic handling:** IBM Plex Sans Arabic is the companion. Apply a 1.15x size multiplier for Arabic text and increase line-height to 1.8 (from Report 2).

**Weight policy:** Maximum weight is 700. Weights 800 and 900 are banned from the entire system. No exceptions. When everything is bold, nothing is bold.

**Tabular numerals:** Required for all wallet, pricing, and financial displays (from Report 1). Enable `fontFeatures: [FontFeature.tabularFigures()]` in Flutter for numeric text styles.

```
=== DISPLAY ===
display.large    48px  w700  lineHeight: 1.10  tracking: -0.5px
                 (wallet balance, hero numbers — use sparingly)
display.medium   36px  w700  lineHeight: 1.15  tracking: -0.3px
                 (large price displays)

=== HEADLINE ===
headline.large   28px  w700  lineHeight: 1.20  tracking: -0.2px
                 (screen titles: Home, Wallet, Profile)
headline.medium  24px  w700  lineHeight: 1.25  tracking: -0.1px
                 (section headers with top-level importance)
headline.small   20px  w600  lineHeight: 1.30  tracking: 0
                 (sub-section titles, sheet headers)

=== TITLE ===
title.large      18px  w600  lineHeight: 1.35  tracking: 0
                 (card titles, nav bar titles)
title.medium     16px  w600  lineHeight: 1.40  tracking: 0.1px
                 (menu items, settings rows, conversation names)
title.small      14px  w600  lineHeight: 1.45  tracking: 0.1px
                 (card subtitles)

=== BODY ===
body.large       16px  w400  lineHeight: 1.60  tracking: 0.1px
                 (primary body text, descriptions, chat messages)
body.medium      14px  w400  lineHeight: 1.65  tracking: 0.2px
                 (supporting descriptions, detail text)
body.small       13px  w400  lineHeight: 1.60  tracking: 0.2px
                 (metadata, timestamps)

=== LABEL ===
label.large      14px  w600  lineHeight: 1.30  tracking: 0.3px
                 (button text, active tab labels, form labels)
label.medium     12px  w600  lineHeight: 1.30  tracking: 0.4px
                 (tags, badges, filter chips, nav labels)
label.small      11px  w600  lineHeight: 1.30  tracking: 0.6px
                 (status badges — UPPERCASE ONLY HERE)

=== CAPTION ===
caption          12px  w400  lineHeight: 1.50  tracking: 0.3px
                 (timestamps, footnotes, "FROM" prefixes)
```

**M3 TextTheme mapping:**
- `displayLarge` = display.large
- `displayMedium` = display.medium
- `headlineLarge` = headline.large
- `headlineMedium` = headline.medium
- `headlineSmall` = headline.small
- `titleLarge` = title.large
- `titleMedium` = title.medium
- `titleSmall` = title.small
- `bodyLarge` = body.large
- `bodyMedium` = body.medium
- `bodySmall` = body.small
- `labelLarge` = label.large
- `labelMedium` = label.medium
- `labelSmall` = label.small (+ uppercase + 0.6px tracking)

---

## 19. Final Spacing / Radius / Elevation System

### Spacing (Base-8, with 4px micro-steps inside components only)

```
space.0    0px
space.1    4px    (tight icon gaps, badge padding — inside components only)
space.2    8px    (inline element gaps, chip padding)
space.3    12px   (component internal spacing, list item gaps)
space.4    16px   (standard padding, card horizontal, screen edge padding)
space.5    20px   (section gaps, card vertical)
space.6    24px   (section breaks, sheet padding, detail screen edge padding)
space.8    32px   (large section breaks)
space.10   40px   (major layout divisions)
space.12   48px   (screen top padding)
space.16   64px   (large empty state spacing)
```

**Layout rules:**
- Screen edge padding: **16px** standard (matches M3 default), **24px** for detail screens and sheets
- Card internal padding: 16px horizontal, 16px vertical
- Section gaps (between groups): 24px
- Between title and first card: 12px
- Between cards in a list: 12px
- Bottom navigation height: 72px (+ safe area)
- Top navigation height: 52px

### Radius (6 values only — collapsed from Report 3's 7)

```
radius.xs    4px   (badges, tags, micro components)
radius.sm    8px   (chips, filter pills, small controls)
radius.md    12px  (inputs, search bar, icon buttons, small cards)
radius.lg    16px  (standard cards, primary buttons — the workhorse)
radius.xl    20px  (bottom sheet top corners, large hero cards, pill buttons)
radius.full  9999px (avatars, circular elements, online dots)
```

No value between these may be used. If a component doesn't fit, adjust the component, not the scale.

### Elevation

```
Light mode:
  elevation.0  No shadow (use border: color.border.default)
  elevation.1  0px 1px 3px rgba(0,0,0,0.08), 0px 1px 2px rgba(0,0,0,0.06)
               → Cards
  elevation.2  0px 4px 12px rgba(0,0,0,0.10), 0px 2px 4px rgba(0,0,0,0.06)
               → Bottom nav, FAB, floating sheets
  elevation.3  0px 8px 24px rgba(0,0,0,0.14), 0px 4px 8px rgba(0,0,0,0.08)
               → Modals, drawers

Dark mode:
  NO SHADOWS. Elevation = surface tonal stepping only.
  base (#0E1212) → container (#161C1C) → raised (#1D2626) → high (#253030)
```

---

## 20. Final Component-by-Component Rules

### Buttons

| Variant | Height | Radius | Background | Label | Border |
|---------|--------|--------|------------|-------|--------|
| Primary | 52px | radius.lg (16px) | action.primary | label.large, white | none |
| Secondary | 52px | radius.lg (16px) | transparent | label.large, text.primary | 1.5px border.default |
| Destructive | 52px | radius.lg (16px) | action.danger.default | label.large, action.danger.on | action.danger.border |
| Text/Link | 36px target | none | none | text.brand | none (underline on hover) |
| FAB | 56x56px | radius.full | action.primary | 24px icon, white | none; elevation.2 |

- Primary button pressed state: scale transform 0.97 + action.primary.pressed
- Full-width buttons: ONLY for auth flows and form submission
- Icon in button: 18px, 8px gap to text

### Input Field
- Height: 52px. Radius: radius.md (12px)
- Background: surface.card. Border: 1px border.default
- Focused: 2px border.focus (teal)
- Error: border.danger, error message below in body.small text.danger
- Label above: body.small w600, text.secondary
- Placeholder: body.large, text.tertiary

### Search Bar
- Height: 48px. Radius: radius.xl (20px)
- Background: surface.card (dark) / neutral.100 (light)
- Left: 16px + search icon (18px, text.tertiary) + 10px + placeholder
- Right: filter icon button (40x40, radius.md, teal)

### Cards

**General card rules:**
- Light mode: elevation.1 shadow, 1px border.subtle
- Dark mode: no shadow, 1px border.default, surface.container background
- Internal padding: 16px
- Radius: radius.lg (16px)
- No image headers — use colored category badge or 4px left stripe

**Tender Card:** amber category badge (top-right, label.small). No red left border. Standard card border.

**Booking Card:** indigo category badge. 4px colored left stripe in booking color OR category icon in tinted container.

**Status Card (Dashboard):** Background uses status surface tokens. ACTIVE = surface.brand-subtle. PENDING = surface.tender-subtle. COMPLETED = surface.success-subtle.

### Chat Bubbles
- Sent: action.primary.default background, white text, radius 18/18/4/18
- Received: surface.card background, text.primary, radius 18/18/18/4
- Max width: 72% of screen
- Timestamp: 10px, white@60% (sent) / text.tertiary (received)

### Offer Card (in chat)
- Background: surface.brand-subtle. Border: 1.5px border.brand. Radius: radius.lg
- Contains: OFFER badge, price (headline.small, teal), title, description, delivery time, action button

### Bottom Navigation
- Height: 72px + safe area. Background: surface.elevated
- Top border: 1px border.subtle
- 6 tabs: Home, Tenders, Bookings, Dashboard, Messages, Profile
- Active: icon + label in text.brand. 4x4px teal dot indicator below label
- Inactive: icon + label in text.tertiary
- Icon: 22px. Label: label.medium. Gap: 3px

### Bottom Sheet
- Background: surface.card. Top radius: radius.xl (20px). Bottom: 0
- Drag handle: 36x4px, radius.full, neutral.300/dark.neutral.400
- Header padding: 20px horizontal. Content padding: 20px
- Max height: 85%. Always has overlay backdrop

### Segmented Control
- Container radius.md (12px), height 44px, background surface.raised
- Active segment: radius.sm (8px) inset, surface.card background, label.large w600
- Inactive: label.large w400, text.tertiary
- No accent color — navigation pattern, not action pattern

### Filter Chip
- Height: 36px. Radius: radius.sm (8px). Padding: 14px horizontal
- Inactive: transparent, 1px border.default, label.medium text.secondary
- Active: surface.brand-subtle, border.brand, label.medium text.brand
- ONE chip style only — no separate "pill" and "tag" variants

### Avatar
- 32px (list items): radius.sm square
- 44px (card headers): radius.sm square
- 56px (profiles, conversations): radius.md square
- 88px (full profile): radius.full circular

### Settings Row
- Height: 60px. Padding: 16px horizontal
- Left: 40x40 icon container (radius.md), 12px gap, title (title.medium) + subtitle (body.small, tertiary)
- Right: ChevronRight (16px) for nav, Toggle for toggles
- Separator: inset divider at border.subtle

### Empty State
- Centered. Icon (48px, text.tertiary) in 72x72 tinted circle (surface.brand-subtle)
- Title: headline.small. Body: body.medium, text.secondary, max 2 lines
- Optional CTA (secondary button). 16px between elements. 64px top margin.
- No decorative illustrations.

### Skeleton Loader
- Same shape as target card. Base: surface.card. Shimmer: surface.card → surface.raised
- Duration: 1.2s ease-in-out loop. Match card structure exactly.

### Toggle
- 48x28px. radius.full. On: action.primary + white knob right. Off: neutral.300/dark.neutral.400 + white knob left
- Knob: 22px, white. Transition: 180ms ease.

---

## 21. Final Screen-by-Screen Architecture

### Home / Discovery
- Header: greeting + avatar + bell icon (headline.large)
- Search bar + filter button
- Horizontal filter chips (All, Design, Development, Marketing, Writing...)
- Single column for Tenders, two-column grid for Services/Bookings
- No "Recent Activity" — that belongs in Dashboard only

### Tenders List
- Single column. Cards: amber badge (top-right), title (2 lines max), description (2 lines, tertiary), tags (max 3), footer (bids + deadline + budget)
- FAB: "Post a Tender"

### Tender Detail
- Title (headline.large), client avatar + name + verified + rating
- Horizontal info row (budget, deadline, bids) in compact stat blocks
- Body description (body.large, generous line height)
- Tags. Sticky bottom: Message (secondary) + Apply/Bid (primary)

### Bookings / Services
- Two-column grid. Cards: category stripe (4px left), provider avatar + name + rating, title, price (teal), "Book Now" (small secondary)

### Booking Detail
- Provider header (avatar, name, rating, stats)
- Plan selector (segmented control: Basic / Standard / Premium)
- Deliverables list (checkmark rows). Reviews
- Sticky bottom: price + Book Now

### Create Task
- 3-step progress indicator (dots: filled teal = done, outlined teal = current, outlined neutral = future)
- Step 1: Task type (Tender vs Booking — two large cards, amber vs indigo)
- Step 2: Category + details
- Step 3: Logistics (deadline, budget)
- Each step: single scrollable page

### Chat
- Top: back + avatar + name + online status
- Context banner (booking/tender reference, collapsible)
- Messages: sent right-teal, received left-surface
- Offer cards: inline, full-width
- Bottom: attachment icon + text input (radius.full) + send. "+" menu for offers

### Messages List
- Avatar (56px square), name + context prefix ("BOOKING:" indigo, "TENDER:" amber), last message, timestamp, unread badge

### Dashboard
- Tab bar: Overview / Bookings / Work / Wallet / Inbox
- Overview: 2x2 stat cards, recent bookings (3), recent work (3)
- Each tab stands alone

### Wallet
- Hero: display.large balance, caption "Available Balance" (tabular numerals)
- Three balance indicators: Available, Pending, Held
- Withdraw + Add Funds (secondary buttons)
- Transaction list with date grouping. Colored dots: teal=received, amber=pending, error=paid out

### Profile (own)
- Avatar 88px circular + name (headline.large) + role (body.medium, secondary)
- Stats row (3 stats). Role toggle (segmented: Client / Freelancer)
- Menu list: Edit Profile, Portfolio, Settings, Help, Log Out

### Settings
- Section-grouped. Labels: label.small, uppercase, tertiary
- Rows use settings row component
- Log Out: destructive button, full width, bottom, generous spacing above

### Notifications
- Date-grouped (Today, Yesterday, This Week)
- Notification component. Mark all as read (text button, right)
- Unread: surface.brand-subtle background

### Search Results
- Full-screen. Filter chips (horizontal) at top
- Same cards as respective sections
- Empty state with suggestion chips

---

## 22. Final Motion System

**Philosophy:** Motion serves navigation and feedback, never decoration. If turning off the animation causes no information loss, question whether the animation should exist.

### Duration Scale
```
motion.instant   0ms    (checkboxes, toggles — immediate)
motion.fast      100ms  (button press, color state changes)
motion.medium    200ms  (component transitions, sheet expand, card press)
motion.slow      350ms  (screen transitions, modal entry/exit)
motion.lazy      500ms  (skeleton shimmer, long loading animations)
```

### Easing Curves
```
easing.standard    cubic-bezier(0.2, 0.0, 0, 1.0)    → most transitions
easing.decelerate  cubic-bezier(0.0, 0.0, 0.2, 1.0)  → elements entering
easing.accelerate  cubic-bezier(0.4, 0.0, 1.0, 1.0)  → elements leaving
easing.spring      SpringDescription(mass: 1, stiffness: 300, damping: 28)
                   → FAB, modal bounce — use sparingly
```

### Transition Rules
- Screen push: horizontal slide, 300ms, standard easing
- Bottom sheet: vertical slide up, 300ms decelerate. Dismiss: 250ms accelerate
- Cards loading: staggered fade + translateY(8px→0), 200ms per card, 30ms stagger, max 180ms total
- FAB: scale 0→1 on mount, spring. Press: scale 0.92 in 80ms, return 120ms
- Tab switching: indicator slides 200ms standard. Content cross-fades 150ms
- Skeleton→content: fade, 250ms. No snap.

### Reduced Motion
When `AccessibilityFeatures.disableAnimations` is active, ALL transitions become instant opacity changes. No exceptions.

---

## 23. Final Accessibility / Usability Standards

### Contrast (hard requirements)
- Text on surfaces: 4.5:1 minimum (normal), 3:1 (large text 18px+ or 14px+ bold)
- Interactive boundaries (from Report 1): 3:1 non-text contrast minimum
- Verified dark mode contrasts: teal on base (#2DAEAE on #0E1212) = 7.2:1. Primary text on card (#EDF5F5 on #161C1C) = ~12:1. Muted text on card (#7A9090 on #161C1C) = ~4.6:1
- Do NOT use text.tertiary for essential information

### Touch Targets
- Target: 48x48dp (Material 3 recommended)
- Absolute minimum: 44x44dp (Apple HIG floor)
- Implement via `MaterialTapTargetSize.padded` and sufficient padding

### Typography
- Minimum text size: 11px (label.small). No exceptions.
- Support large text scaling without layout breakage
- Tabular numerals for all financial data

### State Communication
- Every interactive element: default, focused, pressed, disabled, loading, error states
- Color never sole communicator — always pair with icon or label
- Disabled buttons: pair with tooltip or visible reason
- Loading buttons: 20px CircularProgressIndicator replacing label

### RTL Readiness
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end` everywhere
- Never hardcode left/right
- Category badge approach is direction-agnostic (replaces left-stripe where directionality matters)
- Arabic text: 1.15x size multiplier, 1.8 line-height minimum
- Latin text, URLs, numbers maintain LTR within RTL environment

### Visual QA Checklist (per screen)
- [ ] All touch targets >= 44x44px
- [ ] No text smaller than 11px
- [ ] Primary action obvious within 2 seconds
- [ ] Status badges pair color with icon/label
- [ ] Empty state exists with recovery action
- [ ] Loading state for all async data
- [ ] Error state communicates clearly
- [ ] Screen functions without color (grayscale test)
- [ ] Screen functions in RTL
- [ ] Animations respect reduced motion

---

## 24. Final Flutter + Material 3 Implementation Guidance

### File Structure
```
lib/
  core/
    theme/
      tokens/
        primitives.dart         ← Layer 1: raw values
        semantic.dart           ← Layer 2: SLineColorTokens ThemeExtension
        typography.dart         ← TextTheme + font configuration
        component_tokens.dart   ← Layer 3: component-specific tokens
      app_theme.dart            ← ThemeData assembly (light + dark)
      theme_extensions.dart     ← All ThemeExtension registrations
```

### ColorScheme Assembly
Use `ColorScheme.fromSeed(seedColor: teal500)` then override surface roles manually. The seed algorithm generates unexpectedly warm/cool surfaces — always override `surface`, `onSurface`, `surfaceContainerLow`, `surfaceContainerHigh`, and `outline`.

### ThemeExtension Pattern
SLineColorTokens extends ThemeExtension<SLineColorTokens> with light() and dark() factory constructors. Access in widgets: `Theme.of(context).extension<SLineColorTokens>()!`

### TextTheme
Map directly to M3 TextTheme roles. Plus Jakarta Sans loaded via Google Fonts package or bundled locally. Arabic locale detection triggers font switch to IBM Plex Sans Arabic with 1.15x multiplier.

### Key ThemeData Settings
- `useMaterial3: true` (default, embrace it)
- `materialTapTargetSize: MaterialTapTargetSize.padded`
- `CardTheme.elevation: 0` (we control elevation through our own tokens)
- Component themes (ElevatedButtonTheme, InputDecorationTheme, etc.) wired to semantic tokens

---

## 25. Final Ready-to-Use Design Token Table

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| surface.page | #FAFAF8 | #0E1212 | App background |
| surface.card | #FFFFFF | #161C1C | Cards, sheets |
| surface.elevated | #F3F2F0 | #1D2626 | Bottom nav, elevated |
| text.primary | #1A1918 | #EDF5F5 | Headings |
| text.secondary | #504F4B | #A8BCBC | Body copy |
| text.tertiary | #7A7974 | #7A9090 | Captions, muted |
| text.disabled | #A8A7A2 | #3A4848 | Disabled text |
| text.brand | #0E9E9E | #5EC4C4 | Brand-colored text |
| border.default | #E8E7E4 | #3A4848 | Standard borders |
| border.subtle | #F3F2F0 | #253030 | Faint dividers |
| border.focus | #0E9E9E | #2DAEAE | Focus rings |
| action.primary | #0E9E9E | #2DAEAE | Primary buttons |
| action.primary.pressed | #097272 | #5EC4C4 | Pressed state |
| status.active.bg | #E8F7F7 | #1A3A3A | Active status |
| status.active.text | #0B8888 | #5EC4C4 | Active label |
| status.pending.bg | #FFF8E6 | #2A1E00 | Pending status |
| status.pending.text | #E09000 | #FFC84A | Pending label |
| status.completed.bg | #E8F5EE | #0A1E14 | Complete status |
| status.completed.text | #1A8A5A | #2DBD7A | Complete label |
| status.danger.bg | #FEECE9 | #1E0B09 | Error status |
| status.danger.text | #C8372D | #F27066 | Error label |
| success | #1A8A5A | #2DBD7A | Success color |
| warning | #C47A00 | #FFBA36 | Warning color |
| error | #C8372D | #F27066 | Error color |
| info | #2655CC | #6B8FFF | Info color |

**Spacing:** 0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

**Radius:** 4, 8, 12, 16, 20, 9999

**Elevation:** 0/1/2/3 (light only; dark uses tonal stepping)

**Motion:** 0ms / 100ms / 200ms / 350ms / 500ms

**Font:** Plus Jakarta Sans (Latin) / IBM Plex Sans Arabic (Arabic)

**Weight range:** 400, 500, 600, 700 only. No 800/900.

---

## 26. Final Do / Don't Rules

### DO
- Use semantic tokens for every color, spacing, and radius value
- Use teal ONLY for primary actions and brand moments
- Use amber ONLY for tender/opportunity contexts
- Use indigo ONLY for booking/scheduled contexts
- Use exactly four dark surface levels
- Use weight 700 for headlines, 600 for titles, 400 for body
- Use tabular numerals for all financial displays
- Pair every color-based status with an icon or label
- Test every screen in grayscale, RTL, and 150% text scale
- Respect reduced motion settings — always
- Use EdgeInsetsDirectional, not EdgeInsets
- Build new components before migrating screens

### DON'T
- Don't use font weight 800 or 900 — anywhere
- Don't use pure black (#000000) or pure white (#FFFFFF) as surfaces
- Don't use shadows in dark mode
- Don't use more than 2 accent colors on one screen
- Don't use teal as both a surface color and button color on the same screen
- Don't use opacity variants of accent colors as borders
- Don't use red for anything except errors and destructive actions
- Don't use gradient backgrounds on any surface
- Don't render text below 11px
- Don't create touch targets smaller than 44x44dp
- Don't use color as the sole status communicator
- Don't use a left-border red accent on cards (email pattern, not marketplace)
- Don't use glassmorphism / frosted glass surfaces
- Don't use floating detached navigation bars
- Don't use spring physics on standard interactions (reserve for FAB only)
- Don't use more than 4 surface levels in dark mode
- Don't use Bento Grid asymmetric layouts for marketplace cards
- Don't hardcode left/right in layout code

---

## 27. Final Migration Plan

### Phase 0 — Preparation (1-2 days)
Create `primitives.dart` and `semantic.dart` without touching screens. Add new light/dark ThemeData alongside old theme. Dev-mode toggle for comparison. Zero production risk.

### Phase 1 — Token System (3-5 days)
Replace all hardcoded hex values with semantic token references. Pure refactoring — no visual changes. Test: changing brand color from teal to blue by editing one value should propagate everywhere.

### Phase 2 — Foundation Components (5-7 days)
Build new: Button (primary, secondary, destructive, text), Input, Search Bar, Segmented Control, Filter Chip, Tab Bar, Bottom Sheet, Avatar, Badge, Toggle. New files alongside old ones.

### Phase 3 — Cards (3-5 days)
Rebuild: ServiceCard, TenderCard, BookingStatusCard, WorkCard. One card type at a time.

### Phase 4 — Navigation (2-3 days)
Bottom Navigation + Top Navigation Bar. Test: notch/no-notch, iOS/Android, 150% text scaling.

### Phase 5 — Screen Rollout (ongoing, by priority)
**Order:** Wallet/Escrow → Booking/Tender flows → Chat → Home/Discovery → Profile → Dashboard → Settings → Saved → Notifications → Search

This order (from Report 1) prioritizes trust-sensitive screens first.

### Phase 6 — Typography (parallel to Phase 5)
Switch to Plus Jakarta Sans. Bundle font files. Add IBM Plex Sans Arabic. Configure locale-aware font selection.

### Phase 7 — Light Mode (after dark mode is stable)
Full light mode palette. Verify all custom surface/border colors.

### Risk Mitigations
- Never migrate more than one screen per PR
- Run E2E tests after every component replacement
- Keep old theme for 30 days behind feature flag
- Rollback capability at all times

---

## 28. Final Master Creative Direction Statement

SLine exists to make professional freelancing accessible and trustworthy in Iraq — a market that deserves a product built with the same care as the best global tools, designed for its own context, language, and pace.

The visual language is one of calm confidence. We do not use visual noise to communicate urgency. We do not use decorative complexity to signal quality. We build trust through clarity: every element earns its space by making the next action more obvious, more understandable, or more trustworthy.

Teal is the color of action and trust. Amber is the color of opportunity. Indigo is the color of commitment. These three colors, used with discipline, give users a visual grammar they learn once and use confidently everywhere. Nothing else competes for attention.

The typography is confident — titles are clear, body text is readable, metadata is minimal. The spacing is generous — screens breathe, cards have room, content is never cramped. The motion is purposeful — transitions tell you where you came from and where you're going, then they get out of the way.

SLine should feel, in its best moments, like the product that makes the user say: "I trust this." That trust is built in the smallest details — consistent spacing, reliable component behavior, readable typography, status colors that actually mean something.

This is not about making beautiful screens. This is about building a product that earns the confidence of the people who use it to make their living.

---

*Final Design System Synthesis v1.0*
*Source: Best of Reports 1 + 2 + 3, critically evaluated and unified*
*Ready for implementation*
