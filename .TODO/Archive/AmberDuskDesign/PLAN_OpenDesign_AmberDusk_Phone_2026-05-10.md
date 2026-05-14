# PLAN CRITIC CORRECTED PLAN: Open Design Amber Dusk Phone Redesign
> Owner: Eros  
> Plan auditor: @PlanCritic  
> Planner: @Planner  
> Execution agents: @Pixel, @Architect, @Sentinel, @DocsKeeper  
> Date: 2026-05-10  
> Companion web plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`  
> Critique artifact: `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/PLAN_CRITIQUE_2026-05-10_OpenDesign_AmberDusk.md`

---

## A) Assumptions + Decision Needed

### Assumptions

- Owner @PlanCritic assumes this is a visual redesign only; no schema, RLS, RPC, Edge Function, or storage policy changes are intended.
- Owner @PlanCritic assumes the source of truth for the new design is the Open Design MCP server, project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, plus any screenshots explicitly provided by the user for the current phase.
- Owner @PlanCritic assumes Eros owns phone-first implementation and Mohammed starts web only after the matching phone section passes its gate.
- Owner @PlanCritic assumes all design-system decisions must be controlled from `lib/core/theme/`, not scattered through feature views.
- Owner @PlanCritic assumes existing MVVM, Provider, Supabase, storage, payment, and role-switch contracts are unchanged.

### Decision Needed (Blocking)

1. **Font packaging decision**
   - Missing decision: Whether to package Open Design fonts from `assets/fonts/dm-sans-latin.woff2` and `assets/fonts/fraunces-latin.woff2`.
   - Options: Bundle the Open Design fonts; use existing app fonts and only map style roles.
   - Recommended: Bundle the Open Design fonts if licensing is acceptable, because typography is a visible part of Amber Dusk.
   - Plan impact: If bundled, Phase 0 includes asset registration and verification; if not, Phase 0 must document fallback fonts in the MCP evidence note.

2. **Screenshot authority decision**
   - Missing decision: What happens when a design detail is not visible in MCP files.
   - Options: Ask user for a screenshot; block the phase until Open Design project is updated.
   - Recommended: Ask for a screenshot when the user wants pixel-level design direction, then treat the screenshot as evidence for only the visible area.
   - Plan impact: Every phase includes a screenshot evidence branch; no executor may invent missing visuals.

3. **Theme folder structure decision**
   - Missing decision: Exact folder for Amber Dusk design system files.
   - Options: Flat files under `lib/core/theme/`; grouped files under `lib/core/theme/designs/amber_dusk/`.
   - Recommended: Use `lib/core/theme/designs/amber_dusk/` because phone and web tokens need separate but related control files.
   - Plan impact: All new design tokens, surfaces, motion, component specs, phone layout constants, and later web design constants live under that folder and are exposed through existing theme APIs.

---

## B) Gate Status

| Gate | Status | Reason | Required Fix Included |
|---|---|---|---|
| Data / Contracts Gate | PASS | No data contract changes are planned. Existing models and ViewModels remain authoritative. | Every phase includes @Architect MVVM check. |
| Security / RLS Gate | PASS | No RLS/backend change is planned. UI must not create security-only enforcement. | Invariants require no direct Supabase from views and no lifecycle logic changes. |
| Backend / Supabase Gate | PASS | Backend is out of scope. | Any discovered backend need blocks UI phase and requires a separate Supabase plan with `Skill: supabase-migration`. |
| UI / Integration Gate | PASS AFTER CORRECTION | Original plan had UI phases but did not force fresh design evidence per phase. | Every phase now starts with an Open Design MCP Evidence Refresh and screenshot evidence rule. |
| Release / QA Gate | PASS AFTER CORRECTION | Original plan had QA but needed stricter gate checks and no-fake-progress rules. | Each phase has a GATE CHECK and rollback rule. |

---

## C) Critical Gaps (Must Fix)

### Gap 1: Design Truth Was Not Re-Verified Per Phase

- Why it will break: Executors may implement from memory or old docs after Open Design changes.
- Fix: Every phase starts with `Open Design MCP Evidence Refresh`.
- Owner: @Pixel + @Planner
- Acceptance check: Phase PR includes MCP evidence note with project ID, file path, timestamp, extracted cues, and screenshot reference if used.

### Gap 2: Theme Values Could Scatter Into Feature Files

- Why it will break: Phone and web will drift, and redesign control will become impossible.
- Fix: All reusable design decisions must live in `lib/core/theme/designs/amber_dusk/` and be surfaced through `lib/core/theme/`.
- Owner: @Architect + @Pixel
- Acceptance check: `rg '#[0-9A-Fa-f]{6}|Color\\(0x' lib/features lib/app` shows no new raw Amber Dusk values except documented legacy exceptions.

### Gap 3: Web Design Needs Separate Theme-Controlled Files

- Why it will break: Mohammed may add scattered breakpoints and desktop dimensions in feature views.
- Fix: Web-only responsive tokens belong in `lib/core/theme/designs/amber_dusk/web/`, created by the web plan after phone foundation.
- Owner: Mohammed + @Architect
- Acceptance check: Phone plan exposes shared tokens; web plan owns web folder and no feature-owned breakpoint constants are added.

### Gap 4: Screenshots Were Not Defined As Evidence

- Why it will break: If the user says "use this screenshot," implementation may ignore it or over-apply it.
- Fix: Screenshots are phase-specific evidence. Use them only for visible UI decisions and cross-check against MCP design system.
- Owner: @Pixel + @Sentinel
- Acceptance check: Screenshot filename/path appears in the phase evidence note when used.

### Gap 5: Original Phase Gates Were Too Broad

- Why it will break: A section could be marked done while sub-UI, states, sheets, or dialogs remain unfinished.
- Fix: Each phase now lists sub-UI targets, owner, skill tag, evidence, implementation, and gate check.
- Owner: @PlanCritic
- Acceptance check: @PlanCritic signs off before Mohammed starts matching web phase.

---

## D) Invariants & Success Criteria

- Invariant: Open Design MCP is the design source of truth.
  - Enforce: Run MCP evidence refresh before every phase and every major design decision.
  - Verify: PR contains MCP evidence note.

- Invariant: Screenshots are evidence only when provided or requested.
  - Enforce: Do not invent screenshot-only details; ask for screenshot when needed.
  - Verify: Phase note references screenshot path and visible decisions.

- Invariant: Design system is controlled from `lib/core/theme/`.
  - Enforce: New tokens under `lib/core/theme/designs/amber_dusk/`.
  - Verify: Feature views use theme APIs, not raw visual constants.

- Invariant: No View imports or calls Supabase directly.
  - Enforce: @Architect scans changed views.
  - Verify: `rg 'Supabase.instance|\\.from\\(|\\.rpc\\(' lib/features lib/app`.

- Invariant: No ViewModel starts new backend behavior for visual-only work.
  - Enforce: Keep ViewModel changes limited to exposing state already needed by UI.
  - Verify: @Architect checks diffs.

- Invariant: Payment, booking, work, direct-offer, dispute, tender, wallet, and role-switch lifecycle rules remain server/DB enforced.
  - Enforce: Do not move lifecycle checks into UI-only logic.
  - Verify: Existing tests and smoke checks still pass.

- Invariant: Storage records remain paths; signed URLs are generated at render time where applicable.
  - Enforce: Do not store design image URLs in DB.
  - Verify: @Architect checks media-related diffs.

- Invariant: AppLogger discipline remains intact.
  - Enforce: No `print()` debugging.
  - Verify: `rg 'print\\(' lib`.

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---|---:|---:|---|---|---|---|
| MCP not checked before phase | All phases | High | High | Wrong visual system | PR lacks evidence note | Mandatory MCP gate | Block phase until evidence is added |
| Raw design values spread into features | All UI files | High | High | Future design control lost | New hex values in views | Theme folder rule | Move constants into theme before merge |
| Phone and web drift | Handoff | Medium | High | Duplicate redesign work | Web branch changes phone layout | Phone regression check | Revert web layout and add responsive token |
| Payment visual edits break return flow | Payment phases | Medium | High | Checkout broken | Return URL not cleared | Payment smoke tests | Restore prior payment shell |
| Dashboard sub-UI missed | Dashboard | High | Medium | Revisit required | Untouched tab/sheet | Exhaustive target list | Reopen dashboard phase before web starts |
| Typography overflows on phone | All screens | Medium | Medium | Poor UX | 360px screenshot overflow | Width matrix | Add theme text constraints |
| Screenshots over-applied | Screenshot phases | Medium | Medium | Inconsistent UI | Non-visible details copied | Screenshot scope note | Fall back to MCP design system |
| Theme folder gets too abstract | Phase 0/1 | Medium | Medium | Slow implementation | Feature needs many missing tokens | Add tokens only when reused | Keep local layout values only when truly one-off and documented |

---

## F) Pre-Mortem

- This fails when an executor implements from memory and does not re-open the Open Design MCP artifact.
- This fails when feature screens hardcode Amber Dusk colors instead of using `lib/core/theme/`.
- This fails when phone work is marked complete while sheets, dialogs, skeletons, empty states, or error states still use old teal/glass UI.
- This fails when Mohammed starts web before the phone branch is verified.
- This fails when web responsiveness is added with scattered `MediaQuery` magic numbers.
- This fails when payment and booking visuals are changed without testing existing return/status flows.
- This fails when screenshot details are invented beyond what the screenshot shows.
- This fails when old UI docs are treated as visual truth instead of current-code inventory plus Open Design MCP evidence.

---

## G) Plan Fixes Added

1. **Goal:** Force Open Design truth per phase.
   - Why: Prevent stale implementation.
   - How: Add MCP Evidence Refresh sub-phase to every phase.
   - Output artifact: MCP evidence note in each phase PR.
   - Stop condition: Missing evidence blocks the phase.

2. **Goal:** Centralize all design-system control.
   - Why: Avoid future redesign drift.
   - How: Add `lib/core/theme/designs/amber_dusk/` ownership and no-raw-token invariant.
   - Output artifact: Theme files and scan result.
   - Stop condition: New raw design constants block merge.

3. **Goal:** Separate web design tokens from feature code.
   - Why: Mohammed needs desktop control without touching every screen.
   - How: Web plan owns `lib/core/theme/designs/amber_dusk/web/`; phone plan creates shared base and phone files.
   - Output artifact: Theme folder map.
   - Stop condition: Web breakpoint constants in feature views block merge.

4. **Goal:** Make screenshots authoritative when requested.
   - Why: Some design details may not exist in MCP text files.
   - How: Phase evidence note records screenshot path and visible decisions.
   - Output artifact: Screenshot evidence section.
   - Stop condition: Missing screenshot blocks screenshot-driven tasks.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Global MCP Evidence Rule

Primary Agents: @Pixel + @Planner  
Skill Tags: `audit`, `extract`, `normalize`

Every phase and every substantial design implementation must start with:

- Owner @Planner: Call Open Design MCP `get_project` with project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- Owner @Planner: Call Open Design MCP `list_files` with the same project.
- Owner @Planner: Call Open Design MCP `get_file` for `amber-dusk-design-system.html`.
- Owner @Planner: Call Open Design MCP `get_artifact` or `get_file` for the phase-relevant artifact, usually `Sline V2 Amber Dusk.html` or a specific file discovered through `list_files`.
- Owner @Pixel: If the user provides or requests screenshots, inspect the screenshot before implementation and record the screenshot path.
- Owner @Pixel: Write an evidence note containing MCP file names, extracted visual rules, screenshot references, and explicit "do not infer" gaps.
- Owner @PlanCritic: Block the phase if MCP is unavailable and no explicit user approval exists to continue from cached evidence.

### Global Theme Folder Rule

Primary Agents: @Architect + @Pixel  
Skill Tags: `normalize`, `colorize`, `typeset`, `audit`

All reusable design decisions must be controlled from:

```text
lib/core/theme/designs/amber_dusk/
  amber_dusk_tokens.dart
  amber_dusk_colors.dart
  amber_dusk_typography.dart
  amber_dusk_spacing.dart
  amber_dusk_surfaces.dart
  amber_dusk_motion.dart
  amber_dusk_components.dart
  phone/amber_dusk_phone_layout.dart
```

Existing files in `lib/core/theme/` may re-export or adapt these files:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_typography.dart
lib/core/theme/app_dimens.dart
lib/core/theme/app_decorations.dart
lib/core/theme/app_theme.dart
```

Feature screens must not own reusable colors, typography, shadows, breakpoints, or component-state constants.

---

### Phase 0: Phone Design-System Foundation

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Build the Amber Dusk phone foundation from MCP truth.  
Why: All later phases depend on central tokens and surfaces.  
How: Extract MCP tokens, create theme design files, expose through existing theme APIs.  
Result: Phone UI work has one controlled design system.

#### 0.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract color, typography, surface, motion, component, and phone layout cues.
- Owner @Pixel: If a screenshot is provided, record only the visible design decisions from that screenshot.
- Owner @PlanCritic: Reject Phase 0 if the evidence note is missing.

#### 0.2 Theme Folder Creation

- Owner @Architect: Create `lib/core/theme/designs/amber_dusk/`.
- Owner @Architect: Create `phone/` inside that folder.
- Owner @Pixel: Add planned token files listed in the Global Theme Folder Rule.
- Owner @Architect: Expose tokens through existing app theme files without breaking current imports.

#### 0.3 Token Mapping

- Owner @Pixel, Skill: `colorize`: Map MCP colors into Amber Dusk theme files.
- Owner @Pixel, Skill: `typeset`: Map DM Sans and Fraunces roles.
- Owner @Pixel, Skill: `normalize`: Map spacing, radii, surfaces, shadows, and motion.
- Owner @Architect: Ensure feature code can use existing `AppColors`, `AppTypography`, `AppDimens`, and `AppDecorations` APIs.

#### 0.4 Foundation Verification

- Owner @Sentinel: Run `flutter analyze`.
- Owner @Sentinel: Scan for new raw hex values outside theme folder.
- Owner @Sentinel: Verify 360, 390, and 430 phone widths with a core preview or smallest touched surface.
- Owner Eros: Write Phase 0 handoff note for Mohammed.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if new reusable design constants live under `lib/core/theme/designs/amber_dusk/`.
- PASS only if no feature screen owns new reusable design tokens.

---

### Phase 1: Core Phone Widgets

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign shared widgets before feature screens.  
Why: Feature phases must reuse finished controls.  
How: Apply Amber Dusk theme APIs to shared widgets only.  
Result: Buttons, inputs, cards, containers, nav, skeletons, and badges are stable.

#### 1.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract button, card, nav, skeleton, chip, and form behaviors.
- Owner @Pixel: Attach screenshot evidence if the user provides widget screenshots.

#### 1.2 Shared Widget Implementation

- Owner @Pixel, Skill: `normalize`: Update `app_button.dart`, `app_text_field.dart`, `circle_icon_button.dart`, `glass_button.dart`, `glass_card.dart`, `glass_container.dart`, `scale_button.dart`.
- Owner @Pixel, Skill: `arrange`: Update `custom_bottom_nav_bar.dart`, `sliver_tab_bar_delegate.dart`.
- Owner @Pixel, Skill: `harden`: Update `status_badge.dart`, `skeleton_card.dart`, `skeleton_loader.dart`.
- Owner @Architect: Preserve public widget APIs unless a change is explicitly documented.

#### 1.3 State Coverage

- Owner @Pixel: Cover default, pressed, disabled, loading, success, error, focus, and long-label states.
- Owner @Sentinel: Verify no layout shift between skeleton and final widgets.
- Owner @Sentinel: Verify icon-only buttons have semantics or tooltips.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if shared widgets consume theme APIs.
- PASS only if `flutter analyze` passes.
- PASS only if old teal/glass styling is intentionally retained or replaced.

---

### Phase 2: Phone Shell, Navigation, And Create Post

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign the phone app shell and create-post entry flow.  
Why: Navigation and create action define the phone app frame.  
How: Use Amber Dusk shell tokens and keep existing navigation contracts.  
Result: Home owns the create action; bottom nav remains compact.

#### 2.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract shell, bottom nav, FAB, and create-post flow evidence.
- Owner @Pixel: Use screenshots only if provided for shell or create flow details.

#### 2.2 Implementation

- Owner @Pixel, Skill: `arrange`: Update `lib/app/main_navigation_screen.dart`.
- Owner @Pixel, Skill: `normalize`: Update `lib/core/widgets/custom_bottom_nav_bar.dart`.
- Owner @Pixel, Skill: `clarify`: Update create-post labels in `lib/features/tasks/view/create_task_screen.dart` without changing business logic.
- Owner @Architect: Preserve `NavigationProvider` and `NavView` behavior.

#### 2.3 State And Flow Checks

- Owner @Sentinel: Verify FAB appears only on Home.
- Owner @Sentinel: Verify Tender Post and Booking Post choices.
- Owner @Sentinel: Verify create-post loading, validation, review, publish, and failure states.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if shell values come from theme.
- PASS only if no Tender/Booking nav item is added.

---

### Phase 3: Phone Home, Discovery, Search, Categories, Saved, Favorites

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Finish the entire discovery section in one pass.  
Why: Home cards, filters, search, categories, saved, and favorites share patterns.  
How: Redesign every related sub-UI before moving to web.  
Result: Mohammed can adapt a complete discovery system.

#### 3.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract feed, card, filter, booking, and profile-result evidence.
- Owner @Pixel: Record screenshot evidence if the user provides any discovery screenshot.

#### 3.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update `home_screen.dart`, `discovery_task_sliver.dart`, `filters_modal.dart`.
- Owner @Pixel, Skill: `normalize`: Update `task_card.dart`, `tender_task_card.dart`, `booking_task_card.dart`, `booking_card.dart`.
- Owner @Pixel, Skill: `clarify`: Update visible hierarchy for title, price, category, location, deadline, owner, and CTA.
- Owner @Pixel, Skill: `polish`: Update `categories_screen.dart`, `search_screen.dart`, `search_result_profile_card.dart`, `favorite_card.dart`, `saved_task_tile.dart`.
- Owner @Architect: Preserve HomeViewModel, search, categories, favorites, and saved services.

#### 3.3 Required States

- Owner @Sentinel: Verify populated, loading, empty, error, saved, unsaved, favorite, no-results, and filter-active states.
- Owner @Sentinel: Verify 360px long title and large price overflow.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if every discovery sub-UI listed above is touched or explicitly documented as already compliant.
- PASS only if `flutter analyze` passes.

---

### Phase 4: Phone Dashboard And All Dashboard Sub-UI

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Complete Dashboard as a full section, including every tab and launched sub-UI.  
Why: Partial dashboard redesign will force repeated revisits.  
How: Redesign dashboard shell, overview, inbox, work, bookings, wallet, cards, sheets, and states together.  
Result: Dashboard phone section is final before Mohammed starts web dashboard.

#### 4.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract dashboard, wallet, booking card, work card, counters, and next-action evidence.
- Owner @Pixel: Attach screenshot evidence if user provides dashboard screenshots.

#### 4.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update `dashboard_screen.dart` and tab layout.
- Owner @Pixel, Skill: `normalize`: Update `overview_tab.dart`, `inbox_tab.dart`, `work_tab.dart`, `bookings_tab.dart`, `wallet_tab.dart`.
- Owner @Pixel, Skill: `polish`: Update `dashboard_counters_grid.dart`, `activity_feed_preview.dart`, `next_actions_list.dart`, `work_item_card.dart`.
- Owner @Pixel, Skill: `colorize`: Update `dashboard_booking_card.dart`, `dashboard_offer_card.dart`, wallet cards, and status surfaces.
- Owner @Architect: Preserve DashboardViewModel lazy load, delegates, cache, CTA resolver, and `StatusPresenter`.

#### 4.3 Required States

- Owner @Sentinel: Verify each tab populated, empty, loading, error, and role-sensitive states.
- Owner @Sentinel: Verify inbox accepted-unpaid Pay Now.
- Owner @Sentinel: Verify work active, delivered, completed, disputed, no-show, canceled states.
- Owner @Sentinel: Verify wallet loading, empty activity, error, and withdraw Coming Soon.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if every dashboard tab and sub-widget is covered.
- PASS only if phone dashboard has no old visual leftovers unless documented.

---

### Phase 5: Phone Auth, Account Gates, And System Screens

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign auth and blocking system screens.  
Why: These screens are first-run and high-trust surfaces.  
How: Apply Amber Dusk form, error, and system-state patterns without changing auth logic.  
Result: Auth and gates are visually aligned and behaviorally unchanged.

#### 5.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract form, CTA, system message, and empty/error surface evidence.
- Owner @Pixel: Use screenshots if user provides auth/system examples.

#### 5.2 Implementation Targets

- Owner @Pixel, Skill: `clarify`: Update `login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`, `reset_password_update_screen.dart`.
- Owner @Pixel, Skill: `harden`: Update `account_restricted_screen.dart`, `maintenance_screen.dart`, `update_required_screen.dart`.
- Owner @Architect: Preserve AuthFormViewModel, AuthSessionViewModel, and account guard behavior.

#### 5.3 Required States

- Owner @Sentinel: Verify validation, loading, auth error, disabled signup, forgot success, reset success, restricted, maintenance, and update required.
- Owner @Sentinel: Verify raw backend errors do not appear.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if account gates still block correctly.
- PASS only if `flutter analyze` passes.

---

### Phase 6: Phone Chat, Direct Offers, Attachments, Notifications

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign communication surfaces as one section.  
Why: Chat, offers, attachments, and notifications share realtime and action-state risks.  
How: Apply Amber Dusk list, bubble, offer, attachment, and modal systems.  
Result: Messaging section is complete before web continuation.

#### 6.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract conversation, bubble, offer, notification, and sheet evidence.
- Owner @Pixel: Record screenshot evidence if provided.

#### 6.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update `messages_screen.dart`, `chat_screen.dart`.
- Owner @Pixel, Skill: `polish`: Update `conversation_list_tile.dart`, `message_bubble.dart`, `offer_message_bubble.dart`, `attachment_message_tile.dart`.
- Owner @Pixel, Skill: `clarify`: Update `create_offer_sheet.dart`, `chat_context_widget.dart`.
- Owner @Pixel, Skill: `harden`: Update `notifications_modal.dart`, `notification_badge_button.dart`, `notification_tile.dart`.
- Owner @Architect: Preserve realtime topology, direct-offer service contracts, attachment storage privacy, and notification read/update-only rule.

#### 6.3 Required States

- Owner @Sentinel: Verify empty inbox, unread, active chat, own/other bubbles, typing, attachments, offer states, notification empty/loading/read/unread.
- Owner @Sentinel: Verify no double subscription or N+1 query is introduced.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if realtime and direct-offer behavior remain intact.

---

### Phase 7: Phone Tasks, Tenders, Proposals, Direct Offers, Work Details

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign all work-intent and work-detail surfaces.  
Why: These screens carry money, status, delivery, dispute, and contract risk.  
How: Redesign visuals while preserving existing lifecycle logic.  
Result: Work execution surfaces are complete and safe.

#### 7.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract task detail, proposal, payment, direct offer, and management evidence.
- Owner @Pixel: Use screenshots if the user requests exact detail-screen matching.

#### 7.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update `task_details_screen.dart`, `tenders_screen.dart`, `tender_payment_screen.dart`.
- Owner @Pixel, Skill: `polish`: Update requests list, request tile, submit request sheet, proposal list, proposal tile, proposal details, submit proposal sheet.
- Owner @Pixel, Skill: `harden`: Update `direct_offer_details_screen.dart`, `work_item_details_screen.dart`, submit delivery, review delivery, request extension, and management timeline widgets.
- Owner @Architect: Preserve tender-only bid rules, payment assignment rules, direct-offer escrow rules, frozen/dispute guards, and CTA resolver.

#### 7.3 Required States

- Owner @Sentinel: Verify pending, accepted, rejected, expired, unpaid, paid, active, delivered, revision, disputed, completed, canceled, and error states.
- Owner @Sentinel: Verify payment and dispute controls remain governed by existing logic.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if no lifecycle behavior moved into UI-only code.

---

### Phase 8: Phone Booking, Payment, Wallet Standalone

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign booking, payment, and wallet screens without breaking payment authority.  
Why: These are high-risk money and lifecycle surfaces.  
How: Apply Amber Dusk hero/card/payment patterns while preserving existing flows.  
Result: Booking and wallet phone sections are complete.

#### 8.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract booking card, checkout, return, webview shell, wallet hero, and wallet activity evidence.
- Owner @Pixel: Record screenshot evidence if provided.

#### 8.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update booking discovery, bookings list, booking details.
- Owner @Pixel, Skill: `harden`: Update payment checkout, method, return, webview, and order summary card.
- Owner @Pixel, Skill: `polish`: Update wallet screen, wallet dashboard screen, and shared wallet body.
- Owner @Architect: Preserve hardened payment intent, trusted callback, return parsing, URL cleanup, booking lifecycle guard, and ledger boundaries.

#### 8.3 Required States

- Owner @Sentinel: Verify booking pending, confirmed, active, delivered, completed, canceled, refunded, disputed, no-show.
- Owner @Sentinel: Verify payment success, failure, pending, canceled, retry, trusted callback.
- Owner @Sentinel: Verify wallet loading, empty, activity, error, Coming Soon withdraw.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if payment smoke checks pass.

---

### Phase 9: Phone Profile, Public Profile, Portfolio, Settings, Services

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Redesign complete profile ecosystem.  
Why: Profile has many sub-screens and existing docs that must be superseded carefully.  
How: Use Open Design identity hero and compact module patterns.  
Result: Profile section is final before web continuation.

#### 9.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Extract profile, public profile, settings, portfolio, service, and identity card evidence.
- Owner @Pixel: Use screenshots if user requests exact profile matching.

#### 9.2 Implementation Targets

- Owner @Pixel, Skill: `arrange`: Update profile, edit profile, public profile, settings, manage portfolio, my services.
- Owner @Pixel, Skill: `polish`: Update avatar, preview modal, public profile header/stats/portfolio/reviews.
- Owner @Pixel, Skill: `normalize`: Update portfolio screen, add/edit/details sheets, portfolio tile, image placeholder, service card.
- Owner @Architect: Preserve role switch, avatar upload, public profile ViewModel, favorites, chat, safety, portfolio storage, and logout behavior.

#### 9.3 Required States

- Owner @Sentinel: Verify profile loaded/loading/error, avatar upload, edit validation, public profile all tabs, favorite toggle, message validation, report action, portfolio CRUD, settings logout, service empty state.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if existing profile docs are referenced but not treated as new visual truth over MCP.

---

### Phase 10: Phone Secondary Screens, State Audit, Accessibility

Primary Agents: Eros + @Pixel + @Architect + @Sentinel  
Goal: Close every remaining phone UI gap.  
Why: Small screens and secondary states are where redesigns usually remain unfinished.  
How: Audit every route, state, and shared utility against Amber Dusk.  
Result: Phone design is ready for final web continuation.

#### 10.1 Open Design MCP Evidence Refresh

- Owner @Planner: Run the Global MCP Evidence Rule.
- Owner @Pixel: Re-check all Open Design files for missed screens, assets, or updated screenshots.
- Owner @Pixel: Use screenshots for any user-reported mismatch.

#### 10.2 Implementation Targets

- Owner @Pixel, Skill: `audit`: Review categories, favorites, saved tasks, search, notifications, loading utils, status presenter, and CTA resolver outputs.
- Owner @Pixel, Skill: `harden`: Fix missing loading, empty, error, disabled, success, destructive, permission, and offline-like states.
- Owner @Sentinel: Verify semantics, tap target size, contrast, and overflow.

#### GATE CHECK

- PASS only if MCP evidence exists.
- PASS only if no known phone section has unfinished sub-UI.

---

### Phase 11: Phone Final Integration Readiness

Primary Agents: Eros + @PlanCritic + @Sentinel + @DocsKeeper  
Goal: Validate phone work before Mohammed starts full web completion or final integration.  
Why: Web should not build on incomplete phone design.  
How: Audit evidence, theme centralization, behavior, and section handoffs.  
Result: Phone design is sealed.

#### 11.1 Final Evidence Audit

- Owner @PlanCritic: Confirm every phase has MCP evidence.
- Owner @PlanCritic: Confirm every screenshot-driven decision references a screenshot path.
- Owner @Architect: Confirm new reusable design decisions live under `lib/core/theme/designs/amber_dusk/`.
- Owner @Sentinel: Confirm no raw Amber Dusk values were added to features.

#### 11.2 Final QA

- Owner @Sentinel: Run `flutter analyze`.
- Owner @Sentinel: Run practical targeted tests for touched areas.
- Owner @Sentinel: Smoke test phone app shell, Home, Dashboard, Auth, Chat, Tasks, Booking, Wallet, Profile, Search, Saved, Favorites, Notifications.
- Owner @DocsKeeper: Update docs or phase notes with final token decisions and deviations from MCP.

#### GATE CHECK

- PASS only if @PlanCritic approves.
- PASS only if Mohammed can start each web phase with a clear phone handoff.

---

## I) Change Report

### Original Issues Summary

- The original plan did not force MCP access before every phase.
- The original plan allowed possible design token scattering.
- The original plan did not separate web design control files under theme.
- The original plan did not define screenshot evidence rules.
- The original plan had broad gates that could miss sub-UI states.

### Added Steps

- Added PlanCritic A-I structure.
- Added global MCP evidence rule.
- Added global theme folder rule.
- Added phase-specific MCP evidence subphase.
- Added theme centralization scans.
- Added screenshot evidence rule.
- Added risk register and pre-mortem.
- Added gate checks to every phase.

### Removed Steps

- Removed implicit reliance on cached Open Design data.
- Removed any possibility that old UI docs override MCP truth.

### Reordered Steps

- Theme foundation now happens before any feature UI.
- MCP evidence now happens before every implementation phase.
- Final PlanCritic audit now happens before web continuation/final integration.

### Expanded Steps

- Dashboard now explicitly includes every tab and sub-widget.
- Profile now explicitly includes public profile, portfolio, settings, and services.
- Work phase now explicitly includes tenders, proposals, direct offers, work details, and management.
- Payment phase now explicitly includes checkout, return, webview, and wallet.

### Residual Risks

- Font licensing still needs confirmation before bundling Open Design fonts.
- MCP can be unavailable; phase must block unless the user explicitly approves cached evidence.
- Large theme refactor may affect many screens; Phase 0 and Phase 1 need careful review.

