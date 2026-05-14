# PLAN CRITIC CORRECTED PLAN: Open Design Amber Dusk Web Redesign
> Owner: Mohammed  
> Upstream owner: Eros  
> Plan auditor: @PlanCritic  
> Planner: @Planner  
> Execution agents: @Pixel, @Architect, @Sentinel, @DocsKeeper  
> Date: 2026-05-10  
> Companion phone plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
> Critique artifact: `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/PLAN_CRITIQUE_2026-05-10_OpenDesign_AmberDusk.md`

---

## A) Assumptions + Decision Needed

### Assumptions

- Owner @PlanCritic assumes Mohammed works only after Eros finishes the matching phone phase.
- Owner @PlanCritic assumes web design is an adaptation of the completed phone design plus Open Design MCP web artifact evidence.
- Owner @PlanCritic assumes there is one Flutter app, not a separate web app.
- Owner @PlanCritic assumes web-specific design control belongs under `lib/core/theme/designs/amber_dusk/web/`.
- Owner @PlanCritic assumes feature screens must consume theme APIs and must not own reusable breakpoints, widths, shadows, colors, or typography decisions.

### Decision Needed (Blocking)

1. **Desktop navigation decision**
   - Missing decision: Whether web uses side rail, side nav, or adapted bottom nav.
   - Options: Side rail; full side nav; keep bottom nav until later.
   - Recommended: Side rail for desktop and compact bottom nav for phone/tablet until 1024px, because SLine is an operational app.
   - Plan impact: Phase 2 owns this decision through `lib/core/theme/designs/amber_dusk/web/`.

2. **Web layout token decision**
   - Missing decision: Exact location for desktop breakpoints, gutters, panel widths, max widths.
   - Options: Feature-local constants; shared theme web folder.
   - Recommended: Shared theme web folder.
   - Plan impact: Every web phase must add missing values to theme, not feature files.

3. **Screenshot evidence decision**
   - Missing decision: What happens if Open Design web artifact lacks a detail.
   - Options: Ask for screenshot; block until Open Design file is updated.
   - Recommended: Ask for screenshot when pixel-level accuracy is needed.
   - Plan impact: Every web phase has screenshot evidence rule.

---

## B) Gate Status

| Gate | Status | Reason | Required Fix Included |
|---|---|---|---|
| Data / Contracts Gate | PASS | Web work must reuse phone data contracts and existing ViewModels. | @Architect checks no web ViewModel/repository duplicates. |
| Security / RLS Gate | PASS | No security rule changes are planned. | Direct Supabase view access remains blocked. |
| Backend / Supabase Gate | PASS | Backend is out of scope. | Any backend need requires separate Supabase plan with `Skill: supabase-migration`. |
| UI / Integration Gate | PASS AFTER CORRECTION | Original plan needed stronger MCP and theme-web gates. | Every phase includes MCP evidence and web theme-folder check. |
| Release / QA Gate | PASS AFTER CORRECTION | Web must verify phone regression after every section. | Every phase includes web width matrix and phone regression check. |

---

## C) Critical Gaps (Must Fix)

### Gap 1: Web Could Drift From Phone

- Why it will break: Mohammed may redesign web independently and break the shared visual system.
- Fix: Every web phase starts from completed `design/mobile-<section>` and records phone handoff evidence.
- Owner: Mohammed + @PlanCritic
- Acceptance check: Web PR links the completed phone branch and handoff note.

### Gap 2: Web Breakpoints Could Scatter

- Why it will break: Feature-local widths make maintenance impossible.
- Fix: All web design constants live under `lib/core/theme/designs/amber_dusk/web/`.
- Owner: Mohammed + @Architect
- Acceptance check: `rg 'maxWidth|breakpoint|constraints\\.maxWidth|MediaQuery\\.of\\(context\\)\\.size\\.width' lib/features lib/app` finds only approved layout uses and no reusable constants.

### Gap 3: MCP Web Artifact Could Be Ignored

- Why it will break: Web adaptation may be based only on phone screenshots.
- Fix: Every phase reads Open Design MCP `sline-v2-amber-dusk-web.html` when web-specific layout is involved.
- Owner: @Planner + Mohammed
- Acceptance check: Phase evidence note references `sline-v2-amber-dusk-web.html` or documents why it was not relevant.

### Gap 4: Phone Regression Could Slip In

- Why it will break: Shared responsive changes can alter phone layouts.
- Fix: Every web phase includes 390px phone regression QA.
- Owner: @Sentinel
- Acceptance check: Web phase PR includes phone screenshot/regression note.

---

## D) Invariants & Success Criteria

- Invariant: Web uses Open Design MCP plus completed phone branch as truth.
  - Enforce: MCP evidence and phone handoff evidence in every phase.
  - Verify: PR evidence note exists.

- Invariant: Web design files are separate inside theme design folder.
  - Enforce: `lib/core/theme/designs/amber_dusk/web/` owns breakpoints, max widths, gutters, panel specs, density, hover/focus constants.
  - Verify: No reusable web constants in features.

- Invariant: Feature views consume theme APIs.
  - Enforce: Missing design values must be added to theme first.
  - Verify: @Architect scans diffs.

- Invariant: No duplicated web ViewModels, repositories, or services.
  - Enforce: Web uses existing app architecture.
  - Verify: @Architect checks new file names and imports.

- Invariant: Payment return handling remains intact on web.
  - Enforce: Payment phases must test URL parsing and cleanup.
  - Verify: @Sentinel payment smoke check.

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---|---:|---:|---|---|---|---|
| Web ignores phone handoff | All phases | Medium | High | Phone/web mismatch | Visual divergence | Handoff gate | Rebase web from phone branch |
| Breakpoints scattered in features | Web phases | High | High | Unmaintainable web UI | Repeated width constants | Theme web folder | Move values to theme |
| Wide dashboard becomes marketing-like | Dashboard | Medium | Medium | Low operational density | Oversized cards | Dense layout rule | Switch to split panels/tables |
| Split panes double-fetch | Dashboard/chat/details | Medium | High | Backend load and stale UI | Duplicate loading logs | Single data owner rule | Revert to single screen composition |
| Payment web return breaks | Payment | Medium | High | Checkout broken | URL params remain | Payment smoke | Restore previous return code |
| Hover/focus breaks phone | Shared widgets | Medium | Medium | Phone UI regression | Tap state changed | Phone regression check | Guard responsive behavior |
| Screenshots over-applied | Screenshot phases | Medium | Medium | Incorrect UI | Non-visible guesses | Screenshot scope note | Fall back to MCP |

---

## F) Pre-Mortem

- This fails when Mohammed creates desktop constants inside feature views.
- This fails when web starts before Eros finishes the matching phone phase.
- This fails when desktop dashboard uses large empty cards instead of dense operational panels.
- This fails when web payment screens are restyled and URL cleanup is accidentally skipped.
- This fails when split-pane layouts create two ViewModel instances for the same data.
- This fails when hover/focus logic changes phone tap behavior.
- This fails when screenshots are treated as global truth instead of phase-specific visual evidence.

---

## G) Plan Fixes Added

1. **Goal:** Make web design controlled from theme.
   - Why: Prevent scattered responsive constants.
   - How: Add mandatory `lib/core/theme/designs/amber_dusk/web/` folder rule.
   - Output artifact: Web theme files and scan result.
   - Stop condition: Feature-owned reusable web constants block merge.

2. **Goal:** Force MCP access for every web phase.
   - Why: Prevent stale or invented design work.
   - How: Add Open Design MCP Evidence Refresh to every phase.
   - Output artifact: MCP evidence note.
   - Stop condition: Missing MCP evidence blocks the phase.

3. **Goal:** Protect phone work.
   - Why: Web uses shared files and can regress phone.
   - How: Add 390px phone regression check to every web phase.
   - Output artifact: Phone regression note.
   - Stop condition: Phone regression blocks merge.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Global Web MCP Evidence Rule

Primary Agents: @Planner + Mohammed + @Pixel  
Skill Tags: `audit`, `extract`, `adapt`

Every web phase and every substantial web design implementation must start with:

- Owner @Planner: Call Open Design MCP `get_project` for project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- Owner @Planner: Call Open Design MCP `list_files` for the same project.
- Owner @Planner: Call Open Design MCP `get_file` for `amber-dusk-design-system.html`.
- Owner @Planner: Call Open Design MCP `get_file` for `sline-v2-amber-dusk-web.html` when web layout decisions are involved.
- Owner Mohammed: Read the completed phone phase handoff note from Eros.
- Owner @Pixel: If user provides screenshots, inspect them and record screenshot path.
- Owner Mohammed: Write a web evidence note with MCP files, phone branch reference, screenshot references, responsive decisions, and unknowns.
- Owner @PlanCritic: Block web phase if MCP evidence or phone handoff is missing.

### Global Web Theme Folder Rule

Primary Agents: Mohammed + @Architect + @Pixel  
Skill Tags: `normalize`, `adapt`, `audit`

All web-specific reusable design files must live in:

```text
lib/core/theme/designs/amber_dusk/web/
  amber_dusk_web_breakpoints.dart
  amber_dusk_web_layout.dart
  amber_dusk_web_density.dart
  amber_dusk_web_panels.dart
  amber_dusk_web_navigation.dart
  amber_dusk_web_interactions.dart
```

These files may depend on shared base files:

```text
lib/core/theme/designs/amber_dusk/
  amber_dusk_tokens.dart
  amber_dusk_colors.dart
  amber_dusk_typography.dart
  amber_dusk_spacing.dart
  amber_dusk_surfaces.dart
  amber_dusk_motion.dart
  amber_dusk_components.dart
```

Feature files may use `LayoutBuilder` to choose layout, but reusable thresholds, widths, gutters, panel specs, nav sizes, hover/focus specs, and density values must come from theme.

---

### Phase 0: Web Responsive Foundation

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 0 complete.  
Goal: Establish web design control under theme.  
Why: Web needs separate responsive design files without forking app logic.  
How: Create web folder, define breakpoints, densities, panel sizes, and hover/focus rules.  
Result: Later web phases use centralized responsive tokens.

#### 0.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Confirm phone Phase 0 token handoff.
- Owner @Pixel: Extract web-specific width, density, and layout direction from MCP and screenshots if provided.

#### 0.2 Web Theme Folder Setup

- Owner @Architect: Create `lib/core/theme/designs/amber_dusk/web/`.
- Owner @Pixel, Skill: `adapt`: Add web breakpoint, layout, density, panel, navigation, and interaction files.
- Owner @Architect: Expose web tokens through safe theme APIs.
- Owner Mohammed: Avoid feature-local reusable constants.

#### 0.3 Verification

- Owner @Sentinel: Run `flutter analyze`.
- Owner @Sentinel: Check 768, 1024, 1280, 1440 widths on a core preview or shell target.
- Owner @Sentinel: Check 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if web design files are under `lib/core/theme/designs/amber_dusk/web/`.
- PASS only if phone Phase 0 remains stable.

---

### Phase 1: Web Core Widgets

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 1 complete.  
Goal: Add web behavior to shared widgets without changing phone contracts.  
Why: Web needs hover, focus, keyboard, cursor, and wider density variants.  
How: Extend shared widgets using theme web tokens.  
Result: Later web screens use finished controls.

#### 1.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone widget handoff.
- Owner @Pixel: Extract web control behavior from MCP and screenshots if provided.

#### 1.2 Implementation

- Owner @Pixel, Skill: `harden`: Add hover/focus/keyboard behavior to buttons, icon buttons, text fields, cards, nav, tabs, skeletons, and status badges.
- Owner @Architect: Preserve widget APIs where possible.
- Owner Mohammed: Add missing reusable hover/focus constants to `amber_dusk_web_interactions.dart`.

#### 1.3 Verification

- Owner @Sentinel: Verify focus ring and tab order.
- Owner @Sentinel: Verify mouse hover states.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if shared widgets use web theme tokens.

---

### Phase 2: Web Shell, Navigation, And Create Post

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 2 complete.  
Goal: Build web shell and create-post adaptation.  
Why: Web needs a desktop frame before feature layouts.  
How: Add side rail/side nav behavior through theme-controlled dimensions.  
Result: App shell is responsive and phone shell remains intact.

#### 2.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone shell/create handoff.
- Owner @Pixel: Extract web shell, nav, and create flow evidence.

#### 2.2 Implementation

- Owner @Pixel, Skill: `adapt`: Update `main_navigation_screen.dart` and `custom_bottom_nav_bar.dart` using web nav theme specs.
- Owner @Pixel, Skill: `arrange`: Adapt create-post flow to desktop modal or side panel.
- Owner @Architect: Preserve navigation provider, routes, and create task logic.

#### 2.3 Verification

- Owner @Sentinel: Verify all nav destinations at 768, 1024, 1280, 1440.
- Owner @Sentinel: Verify create Tender/Booking flow.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if web nav constants live in theme web folder.

---

### Phase 3: Web Home, Discovery, Search, Categories, Saved, Favorites

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 3 complete.  
Goal: Adapt complete discovery section to web.  
Why: Discovery has shared cards, filters, search, saved, favorites, and categories.  
How: Use grids, constrained lists, persistent filters, or split panels based on theme breakpoints.  
Result: Discovery web section is complete.

#### 3.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone discovery handoff.
- Owner @Pixel: Extract web feed/card/filter/search evidence.

#### 3.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt Home feed and filters using theme web layout tokens.
- Owner @Pixel, Skill: `arrange`: Adapt task, tender, booking, favorite, saved, search, and category cards.
- Owner @Architect: Preserve existing ViewModels and repositories.

#### 3.3 Verification

- Owner @Sentinel: Verify populated, loading, empty, error, no-results, filter-active states.
- Owner @Sentinel: Verify no duplicate data fetch from responsive layout.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if no feature-local reusable web dimensions are introduced.

---

### Phase 4: Web Dashboard And All Dashboard Sub-UI

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 4 complete.  
Goal: Adapt every dashboard tab and sub-UI to web.  
Why: Dashboard is the highest-risk operational area for partial completion.  
How: Use dense grids, split panels, and theme-controlled dashboard dimensions.  
Result: Dashboard is final for web integration.

#### 4.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone dashboard handoff.
- Owner @Pixel: Extract dashboard web evidence from MCP and screenshots if provided.

#### 4.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt dashboard shell and tabs.
- Owner @Pixel, Skill: `arrange`: Adapt Overview counters/activity/next actions.
- Owner @Pixel, Skill: `harden`: Adapt Inbox, Work, Bookings, and Wallet tabs with all states.
- Owner Mohammed: Add any reusable dashboard widths/panel values to `amber_dusk_web_panels.dart`.
- Owner @Architect: Preserve DashboardViewModel lazy loading, delegates, cache, CTA resolver, and status presenter.

#### 4.3 Verification

- Owner @Sentinel: Verify every tab at 768, 1024, 1280, 1440.
- Owner @Sentinel: Verify no tab double-load.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if every dashboard sub-UI is covered.

---

### Phase 5: Web Auth, Account Gates, System Screens

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 5 complete.  
Goal: Adapt auth and system gates to web.  
Why: These screens must look trustworthy and remain behaviorally strict.  
How: Use constrained form panels and system surfaces controlled by theme.  
Result: Auth/gate web section is complete.

#### 5.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone auth handoff.
- Owner @Pixel: Extract auth/system web evidence or screenshot details.

#### 5.2 Implementation

- Owner @Pixel, Skill: `clarify`: Adapt login, signup, forgot password, reset password.
- Owner @Pixel, Skill: `harden`: Adapt restricted, maintenance, update-required screens.
- Owner @Architect: Preserve AuthFormViewModel, AuthSessionViewModel, and account guard behavior.

#### 5.3 Verification

- Owner @Sentinel: Verify browser autofill, keyboard submit, validation, loading, error, blocked gates.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if account gates remain unbypassable.

---

### Phase 6: Web Chat, Direct Offers, Attachments, Notifications

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 6 complete.  
Goal: Adapt communication surfaces to web.  
Why: Chat requires responsive density without double subscriptions.  
How: Use conversation list + active thread where width allows.  
Result: Communication web section is complete.

#### 6.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone chat handoff.
- Owner @Pixel: Extract chat/notification web evidence.

#### 6.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt messages and chat screens to split layout.
- Owner @Pixel, Skill: `polish`: Adapt bubbles, conversation tiles, attachments, offer bubbles.
- Owner @Pixel, Skill: `harden`: Adapt create offer sheet and notifications modal.
- Owner @Architect: Preserve realtime subscriptions, direct offer contracts, attachment privacy, notification read/update-only behavior.

#### 6.3 Verification

- Owner @Sentinel: Verify no double subscription.
- Owner @Sentinel: Verify keyboard send, focus, scrolling, attachment, offer states, notifications.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if split layout has one data owner.

---

### Phase 7: Web Tasks, Tenders, Proposals, Direct Offers, Work Details

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 7 complete.  
Goal: Adapt work-intent and work-detail surfaces to web.  
Why: These screens carry lifecycle and money risk.  
How: Use two-column detail layouts and theme-controlled panels without changing lifecycle logic.  
Result: Work web section is complete.

#### 7.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone work handoff.
- Owner @Pixel: Extract work/detail web evidence.

#### 7.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt task details, tenders, tender payment.
- Owner @Pixel, Skill: `arrange`: Adapt requests, proposals, direct offer details, work details.
- Owner @Pixel, Skill: `harden`: Adapt delivery, review, extension, and management modals/panels.
- Owner @Architect: Preserve tender, proposal, payment, direct-offer, dispute, and work lifecycle behavior.

#### 7.3 Verification

- Owner @Sentinel: Verify all lifecycle states and no UI-only lifecycle enforcement.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if lifecycle behavior remains server/DB/ViewModel driven.

---

### Phase 8: Web Booking, Payment, Wallet Standalone

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 8 complete.  
Goal: Adapt booking, payment, and wallet to web safely.  
Why: Payment return and booking status are high-risk.  
How: Use desktop forms, summary panels, and wallet grids controlled by theme.  
Result: Booking/payment/wallet web section is complete.

#### 8.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone booking/payment/wallet handoff.
- Owner @Pixel: Extract booking/payment/wallet web evidence.

#### 8.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt booking discovery/list/details.
- Owner @Pixel, Skill: `harden`: Adapt checkout, method, return, webview, order summary.
- Owner @Pixel, Skill: `polish`: Adapt wallet screen, dashboard screen, shared wallet body.
- Owner @Architect: Preserve payment intent, trusted callback, return parsing, URL cleanup, booking lifecycle, and ledger boundaries.

#### 8.3 Verification

- Owner @Sentinel: Verify payment success, failure, pending, canceled, retry, trusted callback, URL cleanup.
- Owner @Sentinel: Verify all booking statuses.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if payment web return smoke passes.

---

### Phase 9: Web Profile, Public Profile, Portfolio, Settings, Services

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 9 complete.  
Goal: Adapt profile ecosystem to web.  
Why: Profile has many screens and old docs that can mislead implementation.  
How: Use phone handoff plus MCP evidence to create desktop identity, tabs, and portfolio layouts.  
Result: Profile web section is complete.

#### 9.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read phone profile handoff.
- Owner @Pixel: Extract profile/portfolio/settings/services web evidence.

#### 9.2 Implementation

- Owner @Pixel, Skill: `adapt`: Adapt profile, edit profile, public profile, settings, manage portfolio, my services.
- Owner @Pixel, Skill: `polish`: Adapt avatar, preview modal, public profile widgets, portfolio sheets, service cards.
- Owner @Architect: Preserve role switch, avatar upload, public profile, favorites, chat, safety, storage, and logout behavior.

#### 9.3 Verification

- Owner @Sentinel: Verify all public profile tabs, favorite, message, report, portfolio CRUD, settings, services.
- Owner @Sentinel: Verify 390px phone regression.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if old profile docs are reference only, not the new visual source of truth.

---

### Phase 10: Web Secondary Screens, State Audit, Accessibility

Primary Agents: Mohammed + @Pixel + @Architect + @Sentinel  
Depends on: Phone Phase 10 complete.  
Goal: Close all remaining web UI and accessibility gaps.  
Why: Secondary states often expose inconsistency.  
How: Audit every web route and state against MCP, phone handoff, and theme folder rules.  
Result: Web redesign is integration-ready.

#### 10.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global Web MCP Evidence Rule.
- Owner Mohammed: Read final phone handoff.
- Owner @Pixel: Check for missed web artifact updates and screenshot mismatch reports.

#### 10.2 Implementation

- Owner @Pixel, Skill: `audit`: Review categories, favorites, saved, search, notifications, loading, statuses, CTAs.
- Owner @Pixel, Skill: `harden`: Fix loading, empty, error, disabled, success, destructive, permission, and offline-like states.
- Owner @Sentinel: Verify focus order, hover, escape/back behavior, contrast, overflow.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if phone regression check passes.
- PASS only if web theme constants are centralized.

---

### Phase 11: Web Final Integration Readiness

Primary Agents: Mohammed + Eros + @PlanCritic + @Sentinel + @DocsKeeper  
Goal: Prepare final redesign integration.  
Why: Main must stay clean until phone and web are both verified.  
How: Merge section pairs into integration branches, then final branch.  
Result: `design/final-redesign` is ready for final QA.

#### 11.1 Final Evidence Audit

- Owner @PlanCritic: Confirm every web phase has MCP evidence.
- Owner @PlanCritic: Confirm every web phase has phone handoff evidence.
- Owner @Architect: Confirm web constants live under `lib/core/theme/designs/amber_dusk/web/`.
- Owner @Sentinel: Confirm 390px phone regression evidence exists for every web phase.

#### 11.2 Integration Branches

- Owner Mohammed: Merge each pair into `design/integration-<section>`.
- Owner Eros: Review phone behavior after each integration.
- Owner @Sentinel: Verify each integration branch before final branch.

#### 11.3 Final QA

- Owner @Sentinel: Run `flutter analyze`.
- Owner @Sentinel: Run practical targeted tests.
- Owner @Sentinel: Smoke test web at 768, 1024, 1280, 1440.
- Owner @Sentinel: Smoke test phone at 390.
- Owner @DocsKeeper: Update docs and handoff notes.

#### GATE CHECK

- PASS only if @PlanCritic approves.
- PASS only if no phase lacks MCP evidence, phone handoff, web theme centralization, or regression proof.

---

## I) Change Report

### Original Issues Summary

- The original web plan did not force MCP access before every web phase.
- The original web plan did not require web design files under a separate theme folder.
- The original web plan did not block feature-local reusable breakpoints.
- The original web plan did not require phone regression checks every phase.

### Added Steps

- Added PlanCritic A-I structure.
- Added Global Web MCP Evidence Rule.
- Added Global Web Theme Folder Rule.
- Added phase-level MCP evidence refresh.
- Added phone handoff dependency to every phase.
- Added 390px phone regression check to every web phase.

### Removed Steps

- Removed implicit permission to implement web from memory.
- Removed implicit permission to add responsive constants inside feature views.

### Reordered Steps

- Web responsive foundation now happens before any web feature phase.
- MCP and phone handoff evidence now happen before implementation in every phase.
- Final PlanCritic audit now happens before final integration.

### Expanded Steps

- Dashboard, profile, payment, chat, and work phases now list sub-UI and risk-specific verification.
- Web theme folder ownership is explicit.
- Screenshot handling is explicit.

### Residual Risks

- Desktop navigation choice still needs confirmation during Phase 2.
- Open Design web artifact may be less detailed than phone artifact; screenshots may be needed.
- Large shared widget changes can still regress phone; every phase includes regression checks.

