# PLANCRITIC CORRECTED PLAN: Open Design Amber Dusk Phone Phases 9-12

> Owner: Eros
> Auditor: @PlanCritic
> Planner input: @Planner
> Mode: single-agent source-of-truth gate for this rewrite
> Date: 2026-05-13
> Parent phone plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
> Companion web plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
> Critique artifact: `.TODO/PLAN_CRITIQUE_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness.md`
> Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`

This file supersedes the pre-critique draft plan created by @Planner. Execution must follow this corrected plan plus the critique artifact, not the draft structure.

---

## A) Assumptions And Decisions Needed

### Assumptions

- This PlanCritic pass is planning-only. It does not edit Flutter application code.
- The current gate was performed by one main agent only. No read-only explorer, worker, or reviewer subagent was spawned for this critique rewrite.
- Phase 9, Phase 10, and Phase 11 scope comes from the corrected parent phone plan `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`.
- Phase 12 is not defined by the parent phone plan. This rewrite resolves Phase 12 as a phone-to-web handoff, docs closure, evidence index, and artifact-routing phase.
- Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` remains the visual source of truth.
- Live Open Design evidence is strong for profile, settings, services, portfolio proof, profile hero, edit rows, toggles, and sheets.
- Live Open Design evidence is weak or absent for favorites, saved tasks, categories, notification list details, and several loading/empty/error states. Those surfaces must be adaptation-only unless new Open Design or user screenshot evidence is added.
- Phase 0 and Phase 1 established Amber Dusk as a staged token layer and shared-widget adapter, not a global `MaterialApp` theme flip.
- Phases 2-8 already completed scoped phone-view Amber Dusk work, but runtime emulator visual parity remains separately gated.
- Backend, Supabase schema, RLS, RPCs, triggers, storage policies, Edge Functions, payment authority, notification authority, role-switch authority, and ViewModel/service contracts are out of scope for this visual plan.
- `Sline_everything/UI_SURFACE_INVENTORY.md` is mandatory for UI scope. It lists the affected profile, portfolio, services, categories, search, favorites, saved, notifications, loading, status, and shared-widget surfaces.

### Decisions Resolved By This Rewrite

1. **Phase 12 meaning**
   - Decision: Phase 12 means phone-to-web handoff, docs closure, evidence index, gap register, and `.TODO` artifact routing.
   - Result: Phase 12 cannot become new runtime UI, wallet, backend, or product behavior work.

2. **Missing exact design states**
   - Decision: Phase 10 secondary screens are token-normalization/adaptation work unless exact Open Design or user screenshot evidence exists.
   - Result: Categories, favorites, saved tasks, notification list states, helper states, and CTA/status helper outputs cannot claim pixel parity without a cited evidence path.

3. **Old profile docs**
   - Decision: Archived UI docs are current-code inventory and legacy visual reference only. They do not override live Open Design evidence.
   - Result: Old teal/gold/glass documentation is used to find surfaces and states, not to recreate old visuals.

4. **Theme activation**
   - Decision: Keep Amber Dusk scoped through the existing staged token layer and widget adapter. Do not globally activate Amber Dusk in `AppTheme`.
   - Result: Feature views use existing tokens/adapters and add missing reusable values centrally.

5. **Font and blur evidence**
   - Decision: Do not bundle Open Design font binaries without license/source evidence. Do not implement `BackdropFilter`, `ImageFilter.blur`, glass, or deleted `glass_*` patterns.
   - Result: Use approved typography roles and solid/gradient/elevation surfaces only.

No blocking product decision remains after this rewrite.

---

## B) Gate Status

| Gate | Draft Status | Corrected Status | Reason | Fix Applied |
| --- | --- | --- | --- | --- |
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | Draft had a provider classification section, but it was not promoted to a blocking PlanCritic gate. | Added fixture/provider matrix, Type A/Type B screen rules, singleton cleanup, and bounded test strategy before test edits. |
| Data / Contracts Gate | PASS | PASS | No model, DTO, ViewModel, repository, service, Provider registration, or route contract change is planned. | Added stop rule if visual work exposes a missing data contract. |
| Security / RLS Gate | PASS | PASS | No RLS, storage policy, auth policy, notification authority, favorites privacy, saved privacy, role switch, or payment authority change is planned. | Added direct-Supabase view scan, storage path/signed URL preservation, and no client notification creation invariants. |
| Backend / Supabase Gate | PASS | PASS | Backend is out of scope. | Added no-change guard for `supabase/migrations`, `supabase/functions`, and `supabase/tests`. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | Draft was detailed but not in PlanCritic A-I source-of-truth format and did not list all related TODO evidence as a blocking source set. | Rewrote into A-I structure, added evidence authority matrix, exact/adaptation labels, and affected inventory rows. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; RUNTIME VISUAL CLOSURE STILL GATED | Draft included QA but could still let analyzer/tests substitute for visual evidence. | Added final runtime matrix, PlanCritic approval, docs sync, handoff, and artifact-routing gates. |
| Web Handoff / Docs Gate | PARTIAL | PASS AFTER CORRECTION | Draft defined Phase 12 but did not make the new phase meaning a resolved PlanCritic decision. | Phase 12 is now a non-code closure phase with handoff, evidence index, docs sync, and archive rules. |

---

## C) Critical Gaps Found

### Gap 1: Draft Was Not A PlanCritic Source-Of-Truth Artifact

- Why it will break: Executors may treat a detailed Planner draft as approved even though it lacks the required A-I gate structure.
- Fix: Replace the draft with this corrected plan and persist the companion critique artifact.
- Owner: @PlanCritic.
- Acceptance check: This file and the critique file both exist and the session log references the rewrite.

### Gap 2: Related TODO Evidence Was Incomplete

- Why it will break: Phase 9-12 depends on parent phone/web plans, old profile UI docs, prior phase critiques, handoffs, docs sync reports, and open emulator visual gates.
- Fix: Add a mandatory evidence set covering active `.TODO` plans, `.TODO/WebRedsign/` handoffs, archived Open Design UI docs, prior PlanCritic artifacts, master reports, emulator checklists, docs sync notes, and session logs.
- Owner: @PlanCritic + @DocsKeeper.
- Acceptance check: Execution starts from the `Required Source Set` in Section H.0.

### Gap 3: Phase 12 Could Be Misread As Runtime Feature Work

- Why it will break: Older roadmap labels use different numbering, and the archived broad UI redesign plan used Phase 12 for dashboard. Future executors could implement the wrong scope.
- Fix: Resolve Phase 12 as handoff/docs closure only and explicitly reject old wallet/dashboard/product meanings for this plan.
- Owner: @PlanCritic.
- Acceptance check: No Phase 12 implementation diff touches `lib/` unless Phase 11 approved docs-linked test harness cleanup.

### Gap 4: Missing Designs Could Become Fake Pixel Parity

- Why it will break: Favorites, saved tasks, categories, notification modal details, loading helpers, and status/CTA helper outputs do not have exact current Open Design phone evidence.
- Fix: Mark those targets as adaptation-only unless new Open Design or user screenshot evidence is cited.
- Owner: @Pixel + @Sentinel.
- Acceptance check: Runtime QA labels exact-match, adaptation, missing evidence, and blocker states separately.

### Gap 5: Existing Raw Visual Constants Need Baseline Handling

- Why it will break: Public profile, profile avatar, manage portfolio, edit profile, portfolio sheets, `StatusPresenter`, `UnifiedCtaResolver`, and `LoadingUtils` currently show raw colors, hardcoded durations, `fontSize`, or shadows. A naive scan can either miss new debt or fail on all old debt.
- Fix: Baseline existing hits before edits and block new unapproved hits in changed files.
- Owner: @CodeGuard + @Sentinel.
- Acceptance check: The session log records before/after raw-token scan results and every exception has a reason.

### Gap 6: Test Setup Can Be Misleading

- Why it will break: `PublicProfileScreen`, `PortfolioScreen`, `CategoriesScreen`, and `SearchScreen` create ViewModels internally; `SavedTasksViewModel` and `NotificationViewModel` initialize auth/listener behavior during construction.
- Fix: Gate widget-test work on fixture/provider classification and singleton/auth-stream cleanup.
- Owner: @Sentinel.
- Acceptance check: Gate 0 matrix is recorded before tests are written.

### Gap 7: Runtime Visual Closure Can Be Overstated

- Why it will break: Open Design screenshots prove design reference, not Flutter runtime. Green analyzer/tests do not prove small-phone layout, text overflow, or route parity.
- Fix: Phase 11 requires runtime emulator/manual proof at 360, 390, 402, and 430 logical widths, or explicit blockers.
- Owner: @Pixel + @Sentinel.
- Acceptance check: Final readiness cannot claim visual completion without route/state runtime evidence.

### Gap 8: Bottom Navigation Contract Can Drift

- Why it will break: Older docs and Open Design variants show five or six nav destinations, while live repo contract is Home, Dashboard, Messages, Profile.
- Fix: Keep `lib/core/navigation/main_nav_destinations.dart` as the live shell contract unless a separate nav plan changes it.
- Owner: @Architect.
- Acceptance check: Phase 9-12 does not add Bookings/Tenders bottom-nav destinations.

### Gap 9: Broad UI Worker Collisions Are A Known Risk

- Why it will break: Prior broad UI phases exposed late worker edits and missing per-file matrices.
- Fix: If the later execution step delegates implementation, the main executor must assign file ownership, require first-edit checkpoints, and treat unreported late edits as untrusted integration patches.
- Owner: @Executor + @Architect.
- Acceptance check: Worker ownership log exists before overlapping files are edited.

---

## D) Invariants And Success Criteria

### Invariants

- No feature view imports or calls Supabase directly.
- No backend, schema, RLS, RPC, trigger, storage policy, Edge Function, SQL test, or live backend mutation is allowed.
- No ViewModel, service, repository, Provider registration, payment helper, role-switch helper, notification service, favorites service, saved service, portfolio service, or auth contract change is allowed unless a separate plan is opened.
- Profile role switch remains atomic and goes through existing role-switch infrastructure.
- Avatar, profile image, task image, and attachment behavior preserves storage path and signed/public URL boundaries.
- Favorites remain client-owned and continue to gate direct DM behavior through existing contracts.
- Saved tasks remain private per user and keep existing manual join behavior.
- Notifications remain server-authoritative; client reads/marks read only.
- Reusable Amber Dusk values live under `lib/core/theme/designs/amber_dusk/`, `lib/core/theme/`, or approved shared widgets.
- No global `MaterialApp` or `AppTheme` Amber Dusk activation occurs.
- No `BackdropFilter`, `ImageFilter.blur`, frosted glass, deleted `glass_*`, or unlicensed Open Design font binaries are introduced.
- Open Design reference evidence and Flutter runtime QA evidence are labeled separately.
- Existing archived UI docs are inventory/reference only and must not override current Open Design evidence.

### Success Criteria

- This corrected plan and the critique artifact are persisted.
- Phase 9 covers own profile, public profile, preview modal, edit profile, avatar, settings, manage portfolio, standalone portfolio, portfolio sheets, portfolio tiles/placeholders, my services, and service cards.
- Phase 10 covers categories, search, favorites, saved, notifications, loading, status, CTA helpers, accessibility, overflow, and dynamic-state hardening.
- Phase 11 runs final evidence, token, MVVM, automated, runtime, and PlanCritic approval gates.
- Phase 12 produces a web handoff, evidence index, gap register, docs-sync note where needed, and artifact-routing closure.
- No backend/Supabase files change.
- Focused tests, full tests, analyzer, format, diff check, raw-token scans, no-glass scans, backend no-change scan, and runtime phone matrices are planned.
- Mohammed receives a clear web continuation handoff that separates exact, adapted, blocked, and unverified surfaces.

---

## E) Risk Register

| Risk | Where | Probability | Impact | Early Signal | Prevention | Fallback |
| --- | ---: | ---: | ---: | --- | --- | --- |
| Phase 12 becomes a feature bucket | Phase 12 | Medium | High | `lib/` runtime diff under Phase 12 | Handoff/docs-only decision | Split separate Planner pass |
| Missing designs get invented | Phase 10 secondary screens | High | Medium | Pixel-match claim without evidence path | Adaptation-only labels | Request screenshots or defer exact match |
| Profile old teal/gold persists | Public profile, edit, manage portfolio | High | Medium | Raw-token scan hits in changed files | Baseline then centralize/fix | Document old debt or fix before gate |
| Role switch breaks | Profile | Low | High | Profile changes touch role-switch services/providers | UI-only scope and role smoke | Revert behavior-adjacent edits |
| Favorites DM guard regresses | Public profile, favorites | Low | High | UI starts chat outside existing VM/service path | Preserve ViewModel/service boundaries | Revert chat/favorites-adjacent changes |
| Portfolio storage behavior changes | Portfolio/profile | Medium | High | New signed/public URL logic in views | Keep ViewModel/service storage boundary | Split storage plan |
| Notification authority moves client-side | Notifications | Low | High | New insert/create path in view/VM | Server-authority invariant | Revert and open notification backend plan |
| Type B widget tests are false positives | PublicProfile, Portfolio, Search, Categories | Medium | Medium | Provider not found, real Supabase touched, timer leaks | Gate 0 fixture matrix | Lower-level tests or documented manual harness |
| Runtime visual QA overstated | Phase 11/12 | High | Medium | Final report links only Open Design screenshots | Runtime route/state matrix | Keep visual gate open |
| Bottom nav contract drifts | App shell/profile links | Medium | High | Bookings/Tenders added as shell tabs | `MainNavDestinations` invariant | Separate nav plan |
| Wide execution workers collide | Future execution | Medium | High | Two workers edit same screen/shared helper | File ownership checkpoints | Main executor integration review |

---

## F) Pre-Mortem

- This fails if the executor uses the pre-critique draft instead of this corrected plan.
- This fails if old profile UI docs are treated as new visual truth and old teal/gold/glass patterns are recreated.
- This fails if Phase 10 claims exact Open Design parity for favorites, saved, categories, or notifications without evidence.
- This fails if profile visual changes alter role switching, logout, avatar upload, public profile loading, favorites, chat, safety reports, or portfolio CRUD contracts.
- This fails if `PortfolioScreen`, `CategoriesScreen`, or `SearchScreen` tests instantiate real Supabase dependencies because their screens create ViewModels internally.
- This fails if `SavedTasksViewModel` or `NotificationViewModel` tests do not stub auth/listener state before construction.
- This fails if runtime screenshots are skipped and final docs say phone visual parity is complete.
- This fails if Mohammed starts web Phase 9 from narrative notes without route/surface/evidence mapping.
- This fails if `.TODO` archive cleanup hides active plans, handoffs, or open emulator visual gates.

---

## G) Plan Fixes Applied

1. Rewrote the plan into PlanCritic A-I source-of-truth format.
2. Added the persisted critique artifact path and session-log requirement.
3. Added Gate 0 for fixture/provider/test infrastructure.
4. Added the full related TODO and docs source set.
5. Resolved Phase 12 as handoff/docs closure only.
6. Added evidence authority labels for exact, adaptation-only, runtime, and blocker proof.
7. Added baseline/diff rules for raw visual constants and no-glass scans.
8. Added explicit live four-tab navigation contract.
9. Added Phase 9 public profile, portfolio, settings, avatar, and service sub-surface detail.
10. Added Phase 10 secondary surfaces and helper-state detail with adaptation-only constraints.
11. Added Phase 11 final runtime matrix and PlanCritic approval.
12. Added Phase 12 web handoff, docs sync, evidence index, and artifact-routing gates.
13. Added future delegation ownership rules based on prior Phase 5-8 SystemEvolution findings.

---

## H) Corrected Execution Plan

### H.0 Source, Evidence, And Pre-Edit Gates

**Primary agents:** `@PlanCritic`, `@Pixel`, `@Architect`, `@Sentinel`, `@CodeGuard`, `@DocsKeeper`
**Skill tags:** `critique`, `audit`, `extract`, `normalize`, `harden`

Goal: Lock the evidence set, affected routes, and test strategy before any execution edits.

Why: Phase 9-12 touches identity, trust, portfolio, favorites, saved tasks, notifications, and final handoff surfaces.

Result: Execution starts with an exact source set, no fake progress, and no hidden backend or lifecycle work.

#### Required Source Set

Execution must read or re-check these before edits:

- `.cursor/Agents/PlanCritic.md`
- `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`
- `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
- `.TODO/PLAN_CRITIQUE_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/PLAN_CRITIQUE_2026-05-10_OpenDesign_AmberDusk.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/UI_REDESIGN_PLAN_AMBER_DUSK.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/SLINE_UI_INVENTORY.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/SLINE_UI_INVENTORY_V2.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/UI_DOCS_PROFILE_SUMMARY.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/UI_DOCS_PROFILE_SCREENS.md`
- `.TODO/Archive/OpenDesign_AmberDusk_2026-05-10/UI_DOCS_PUBLIC_PROFILE.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/EVIDENCE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/BASELINE_OpenDesign_AmberDusk_Phase0_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets.md`
- `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase0_ToWeb_2026-05-11.md`
- `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phase1_CoreWidgets_ToWeb_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_Step6.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases5_6_7_8_2026-05-13/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases5_6_7_8.md`
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-13.md`
- `README.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/DEVELOPER_GUIDE/Profile Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Portfolio Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Categories Feature.md`
- `Sline_everything/DEVELOPER_GUIDE/Home Feature.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/DOC_SOURCE_MAP.md`
- `Sline_everything/UI_SURFACE_INVENTORY.md`
- `Sline_everything/Sline_Log.md`
- `Sline_everything/AppDigram/README.md`
- `Sline_everything/AppDigram/UI_Sequence/03_home_discovery_ui_sequence.md`
- `Sline_everything/AppDigram/UI_Sequence/08_profile_ui_sequence.md`
- `Sline_everything/AppDigram/All_Diagrams/02_role-switching-flow.md`
- `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`
- `Sline_everything/AppDigram/All_Diagrams/17_storage-signed-urls-flow.md`

#### Open Design Evidence Lock

- [ ] (`@Pixel | Skill: extract`) Re-check Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- [ ] (`@Pixel | Skill: extract`) Read/list `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, and `sline-v2-amber-dusk-web.html`.
- [ ] (`@Pixel | Skill: audit`) Record strong profile evidence: `.profile-hero`, `.profile-photo`, `.verified-pill`, `.profile-metrics`, `.availability-card`, `.service-card`, `.portfolio-strip`, `.settings-group`, `.edit-row`, `.toggle`, `.danger-zone`, and edit sheet rules.
- [ ] (`@Pixel | Skill: audit`) Record missing/weak exact evidence: favorites, saved, categories, notification modal/list, helper states, and several empty/error/loading states.
- [ ] (`@Sentinel | Skill: audit`) Label every target as `exact Open Design`, `adaptation-only`, `runtime Flutter proof`, or `blocked`.
- **GATE CHECK:** Missing evidence cannot become exact-match implementation.

#### UI Surface Inventory Lock

Affected inventory rows include:

- App shell: `MainNavigationScreen`, `CustomBottomNavBar`, notification badge entry.
- Profile: own profile, edit profile, settings, public profile, public profile action bar, profile preview modal, public profile sections, avatar widget.
- Portfolio: standalone portfolio, manage portfolio, add/edit/detail sheets, portfolio tile, image placeholder.
- Services: my services, service card.
- Secondary: categories, search, search result profile card, favorites, favorite card, saved tasks, saved task tile.
- Notifications: notification badge button, notifications modal, notification modal states, notification tile.
- Helpers: `LoadingUtils`, `StatusPresenter`, `UnifiedCtaResolver`, `StatusBadge`, skeletons, signed media, SnackBars, banners, inline loading/empty/error/disabled states.

- [ ] (`@Planner`) Re-run `rg --files` for all affected feature and helper paths.
- [ ] (`@Architect`) Confirm no affected screen, tab, sheet, dialog, helper, or route is missing from this plan.
- [ ] (`@DocsKeeper`) Route any discovered missing inventory row to `Sline_everything/UI_SURFACE_INVENTORY.md` in Phase 12.
- **GATE CHECK:** Execution stops if the inventory reveals an omitted affected surface.

#### Gate 0: Test Infrastructure Matrix

- [ ] (`@Sentinel`) Classify screens:
  - Type A, provider-injected: `ProfileScreen`, `EditProfileScreen`, `SettingsScreen`, `ManagePortfolioScreen`, `MyServicesScreen`, `FavoritesScreen`, `SavedTasksScreen`, `NotificationsModal`, `NotificationBadgeButton`.
  - Type B, screen-created ViewModel or service harness needed: `PublicProfileScreen`, `PortfolioScreen`, `CategoriesScreen`, `SearchScreen`.
- [ ] (`@Sentinel`) Stub or inject auth/listener state before constructing `SavedTasksViewModel` and `NotificationViewModel`.
- [ ] (`@Sentinel`) Avoid `pumpAndSettle()` for unbounded animations or shimmer loops; use bounded `pump(Duration)` where needed.
- [ ] (`@Sentinel`) Record which render paths get widget tests and which require manual/runtime fixtures.
- **GATE CHECK:** No Phase 9/10 widget-test edits begin before the matrix is in the session log.

#### Backend Non-Change Gate

- [ ] (`@CodeGuard`) Confirm no planned backend changes under `supabase/migrations`, `supabase/functions`, or `supabase/tests`.
- [ ] (`@Architect`) If visual work exposes missing data, stop and open a separate Planner pass. Do not patch data access inside a view.
- [ ] (`@Sentinel`) Confirm `Sline_everything/SUPABASE_SETUP.md` remains unchanged unless backend objects changed.
- **GATE CHECK:** Any backend diff blocks this visual plan.

---

### Phase 9: Phone Profile, Public Profile, Portfolio, Settings, Services

**Primary agents:** `@Pixel`, `@Architect`, `@Sentinel`, `@CodeGuard`
**Goal:** Finish the profile ecosystem against Open Design evidence while preserving identity, storage, chat, favorites, safety, role, and portfolio contracts.
**Result:** Profile and related portfolio/services surfaces are ready for final phone integration and Mohammed's matching web phase.

#### 9.1 Design Context Lock For Profile Ecosystem

- [ ] (`@Pixel | Skill: extract`) Map Open Design profile hero to current `ProfileScreen` sections: identity, role/location, verified pill, bio, edit/public actions, metrics, availability, services, portfolio, trust/review, settings.
- [ ] (`@Pixel | Skill: normalize`) Map Open Design grouped settings rows to current `ProfileScreen`, `SettingsScreen`, edit profile, manage portfolio, my services, and settings entries.
- [ ] (`@Pixel | Skill: audit`) Mark public profile header/stats/portfolio/reviews as legacy-token targets because current files still contain old `AppColors` and raw Flutter colors.
- [ ] (`@Pixel | Skill: audit`) Mark manage portfolio and standalone portfolio as raw-token/layout targets where current files contain raw `Duration`, `fontSize`, danger colors, shadows, or sheet dimensions.
- [ ] (`@Sentinel | Skill: audit`) Record exact evidence vs adaptation-only for own profile, public profile, portfolio, settings, services, avatar, sheets, and modals.
- **GATE CHECK:** Phase 9 target proof is recorded before source edits.

#### 9.2 Own Profile Screen And Account Modules

- [ ] (`@Pixel | Skill: arrange`) Keep own-profile order as hero, proof metrics, availability, services, portfolio, settings, saved/favorites/wallet/profile actions where currently available, and account controls.
- [ ] (`@Pixel | Skill: normalize`) Ensure profile hero, metrics, availability, services, portfolio strip, trust/review placeholder, settings group, and logout controls consume `AmberDuskTokens`, `AmberDuskTokens.widgetTheme`, `AppDimens`, `AppMotion`, `AppDecorations`, and existing core widgets.
- [ ] (`@Pixel | Skill: harden`) Verify loading, loaded, retry/error, missing name, missing title, missing location, no bio, no skills, no portfolio, missing avatar, avatar loading, long name, and long email states.
- [ ] (`@Architect`) Preserve `ProfileViewModel.loadUserData`, role switch, logout, avatar upload, public profile opening, saved/favorites/wallet navigation, and current state ownership.
- [ ] (`@Sentinel | Skill: audit`) Add or update widget coverage for own-profile loading/error/loaded states if rendered structure changes.
- **GATE CHECK:** Own profile passes MVVM and visual-token scans.

#### 9.3 Edit Profile, Avatar, And Settings

- [ ] (`@Pixel | Skill: normalize`) Replace old `AppColors.teal/lightRed/gold`, raw `Colors.*`, raw `fontSize`, and raw `Duration(milliseconds:)` in `EditProfileScreen`, `SettingsScreen`, `ProfileAvatarWidget`, and `ManagePortfolioScreen` where changed.
- [ ] (`@Pixel | Skill: arrange`) Align edit forms with Open Design edit-sheet hierarchy: scoped fields, clear labels, save/cancel actions, compact help text, and no browser-default black text.
- [ ] (`@Pixel | Skill: harden`) Preserve long names, long emails, long bios, many skills, avatar upload failure, logout confirmation, dark-mode toggle, coming-soon rows, and destructive action confirmation.
- [ ] (`@Architect`) Preserve `ProfileViewModel.updateProfile`, `pickAndUploadAvatar`, `AuthSessionViewModel.logout`, `ThemeModeProvider`, current validators, and navigation behavior.
- [ ] (`@Sentinel | Skill: audit`) Add widget coverage for validation, avatar failure, logout confirmation, and theme toggle only when those render paths change.
- **GATE CHECK:** Account behavior remains unchanged and new visual values are centralized.

#### 9.4 Public Profile And Profile Preview Modal

- [ ] (`@Pixel | Skill: normalize`) Tokenize `PublicProfileScreen`, `PublicProfileHeader`, `PublicProfileStats`, `PublicProfilePortfolio`, `PublicProfileReviews`, sticky action bar, tabs, and `ProfilePreviewModal`.
- [ ] (`@Pixel | Skill: arrange`) Keep public profile structure scannable: identity, proof stats, about, portfolio, history, reviews, and sticky Message/Hire/report actions.
- [ ] (`@Pixel | Skill: harden`) Verify `User not found`, loading, self-message block, unauthenticated message block, chat creation error, report empty reason, report failure, favorite toggle, long review text, long portfolio title, missing avatar, and action-bar overflow.
- [ ] (`@Architect`) Preserve `PublicProfileViewModel.loadProfile`, `FavoritesViewModel.ensureLoaded`, `ChatViewModel.createOrGetConversation`, `SafetyViewModel.submitReport`, `LoadingUtils`, and profile preview route ownership.
- [ ] (`@Sentinel | Skill: audit`) Add widget coverage or a documented manual harness for public profile tabs, action bar, report, favorite, and message paths when production dependency setup is too costly.
- **GATE CHECK:** Public profile adds no direct data access and no new raw legacy visual constants.

#### 9.5 Portfolio Screens, Sheets, Tiles, And Manage Portfolio

- [ ] (`@Pixel | Skill: arrange`) Align `PortfolioScreen` grid/list, empty state, loading-more tiles, pull-to-refresh, add action, details sheet, edit sheet, and delete confirmation with Amber Dusk proof-tile and sheet patterns.
- [ ] (`@Pixel | Skill: normalize`) Replace raw paddings, raw `TextStyle(fontSize:)`, raw red/error colors, raw sheet radii, raw placeholders, raw shadows, and legacy constants in changed portfolio files.
- [ ] (`@Pixel | Skill: harden`) Verify no image, broken image, long title, long description, upload failure, add failure, edit failure, delete failure, infinite-scroll loading, and empty portfolio.
- [ ] (`@Architect`) Preserve `PortfolioViewModel.load`, `loadMore`, `addItem`, `updateItem`, `deleteItem`, `PortfolioRepository`, `PortfolioService`, public portfolio bucket behavior, and current path/public URL reality.
- [ ] (`@Sentinel | Skill: audit`) Add widget tests for portfolio empty/error/populated/detail/delete states or document exact manual fixture limits.
- **GATE CHECK:** Portfolio remains ViewModel-driven and storage behavior is unchanged.

#### 9.6 Services And Availability Modules

- [ ] (`@Pixel | Skill: arrange`) Align `MyServicesScreen` and `ServiceCard` with Open Design package rows: title, concise description, price, delivery, status, and action affordance.
- [ ] (`@Pixel | Skill: normalize`) Replace raw chip paddings, raw icon sizes, raw white/transparent colors, and legacy status colors in changed service/profile service surfaces.
- [ ] (`@Pixel | Skill: harden`) Verify empty services, loading, error, long title, long price, missing price, missing delivery days, draft/active/paused badges, and coming-soon create/edit feedback.
- [ ] (`@Architect`) Preserve `MyServicesViewModel`, `ServicesRepository`, `ServiceModel`, `ServiceStatus`, and current create/update/status behavior.
- [ ] (`@Sentinel | Skill: audit`) Add widget coverage for `ServiceCard` status/price/missing-data states if visuals change.
- **GATE CHECK:** Services are visual-only unless a separate product/backend plan is approved.

#### 9.7 Phase 9 Verification

- [ ] (`@Sentinel`) Run `dart format --set-exit-if-changed .`.
- [ ] (`@Sentinel`) Run `flutter analyze --no-fatal-infos`.
- [ ] (`@Sentinel`) Run `flutter test test/unit/profile test/features/profile/services test/unit/portfolio test/unit/services`.
- [ ] (`@Sentinel`) Run any new or updated Phase 9 widget tests.
- [ ] (`@CodeGuard`) Run `rg 'Supabase\.instance|\.from\(|\.rpc\(' lib/features/profile/view lib/features/portfolio/view lib/features/services/view`.
- [ ] (`@CodeGuard`) Run raw visual scan over changed Phase 9 files: `Color\(0x|#[0-9A-Fa-f]{6}|Colors\.|BoxShadow\(|Duration\(milliseconds:|fontSize:`.
- [ ] (`@Pixel | Skill: audit`) Capture runtime screenshots or manual notes for 360, 390, 402, and 430 logical-width phone targets for all changed Phase 9 routes.
- **GATE CHECK:** Phase 9 passes tests, guard scans, and runtime visual proof labels.

---

### Phase 10: Phone Secondary Screens, State Audit, Accessibility

**Primary agents:** `@Pixel`, `@Architect`, `@Sentinel`, `@CodeGuard`
**Goal:** Close remaining phone UI gaps across secondary routes, helper states, accessibility, and overflow.
**Result:** No known phone section remains unfinished before final integration readiness.

#### 10.1 Design Context Lock For Secondary Surfaces

- [ ] (`@Pixel | Skill: extract`) Re-check Open Design search bar, segment, bottom nav, state, notification, profile settings, and helper evidence.
- [ ] (`@Pixel | Skill: normalize`) Map missing secondary screens to established Amber Dusk primitives: search field, segment, task/profile cards, skeletons, empty/error panels, notification rows, status pills, and CTA buttons.
- [ ] (`@Sentinel | Skill: audit`) Label categories, favorites, saved, notifications, loading utilities, status presenter, and CTA resolver as adaptation-only unless exact proof is found.
- [ ] (`@Sentinel | Skill: audit`) Record any user-provided screenshot path before exact visual matching.
- **GATE CHECK:** Adaptation-only surfaces are not claimed as pixel matched.

#### 10.2 Categories, Search, Favorites, And Saved

- [ ] (`@Pixel | Skill: arrange`) Align `CategoriesScreen` search, grid, skeleton, empty, error, and category-tap feedback with Amber Dusk card/list rhythm.
- [ ] (`@Pixel | Skill: arrange`) Align `SearchScreen` search field, Find Work/Find Talent segment, task result cards, profile result cards, loading, initial empty, no-result, and error states.
- [ ] (`@Pixel | Skill: arrange`) Align `FavoritesScreen` and `FavoriteCard` loading, empty, error, favorite list, remove action, chat entry, and sign-in-blocked feedback.
- [ ] (`@Pixel | Skill: arrange`) Align `SavedTasksScreen` and `SavedTaskTile` loading, empty, error, list, task-open, remove/refresh, and empty CTA behavior.
- [ ] (`@Pixel | Skill: harden`) Verify long names, long category names, long task titles, unavailable profiles, missing avatars, no saved tasks, no favorites, no search results, and signed-out paths.
- [ ] (`@Architect`) Preserve `CategoriesViewModel`, `SearchViewModel`, `FavoritesViewModel`, `SavedTasksViewModel`, `CategoriesService` cache, favorites DM guard, saved task privacy, route helpers, and task/profile navigation limits.
- [ ] (`@Sentinel | Skill: audit`) Add widget tests for changed secondary states where provider setup is practical; otherwise record manual fixture limits.
- **GATE CHECK:** Secondary discovery surfaces pass provider, MVVM, privacy, and state checks.

#### 10.3 Notifications, Loading, Status, And CTA Helpers

- [ ] (`@Pixel | Skill: normalize`) Align `NotificationsModal`, `NotificationBadgeButton`, and `NotificationTile` with Amber Dusk modal/list/empty/error/loading patterns.
- [ ] (`@Pixel | Skill: normalize`) Align `LoadingUtils` with approved solid scrim, no-glass rule, and current app tokens.
- [ ] (`@Pixel | Skill: normalize`) Audit `StatusPresenter`, `UnifiedCtaResolver`, and `StatusBadge` for old teal/gold/red/orange color leakage.
- [ ] (`@Pixel | Skill: harden`) Verify notification loading, empty, error/retry, unread tint, mark-all-read success/failure, unread badge `9+`, deep-link tap, and transient realtime reconnect cached-state display.
- [ ] (`@Architect`) Preserve `NotificationViewModel`, `NotificationService`, `DeepLinkService`, foreground sync, server-authority notification creation, and transient reconnect behavior from the 2026-05-13 fix.
- [ ] (`@Sentinel | Skill: audit`) Run notification VM/modal tests and add regression coverage if visual changes affect unread/error/mark-all-read rendering.
- **GATE CHECK:** Shared helpers preserve semantics and no backend/realtime behavior changes.

#### 10.4 Accessibility, Overflow, And Responsive Hardening

- [ ] (`@Pixel | Skill: harden`) Verify every primary action has a minimum 48px tap target or a documented design exception.
- [ ] (`@Pixel | Skill: harden`) Verify long localized-ish English strings and long user-generated content do not overflow at 360, 390, 402, and 430 logical widths.
- [ ] (`@Pixel | Skill: harden`) Verify contrast for amber, forest, rust, cream, muted text, disabled controls, unread states, destructive actions, and skeleton placeholders.
- [ ] (`@Pixel | Skill: clarify`) Keep user-facing copy concise and preserve existing error meaning; do not introduce raw exception text.
- [ ] (`@Sentinel | Skill: audit`) Use widget tests, emulator checks, or manual screenshots to record semantics, tap-target, and overflow proof for each changed route.
- **GATE CHECK:** No changed screen has known overflow, contrast, or inaccessible primary controls.

#### 10.5 Phase 10 Verification

- [ ] (`@Sentinel`) Run `flutter test test/features/favorites test/unit/categories test/unit/search test/unit/saved`.
- [ ] (`@Sentinel`) Run `flutter test test/unit/notifications test/widget/notifications`.
- [ ] (`@Sentinel`) Run any new or updated Phase 10 widget tests.
- [ ] (`@CodeGuard`) Run direct-Supabase guard scan over changed Phase 10 view files.
- [ ] (`@CodeGuard`) Run raw visual constant scan over changed Phase 10 files and document intentional exceptions.
- [ ] (`@Pixel | Skill: audit`) Complete a route/device-width matrix for categories, search, favorites, saved, notifications, loading helper, status helper, and CTA helper outputs.
- **GATE CHECK:** Phase 10 has no known unfinished phone section.

---

### Phase 11: Phone Final Integration Readiness

**Primary agents:** `@PlanCritic`, `@Sentinel`, `@Architect`, `@CodeGuard`, `@DocsKeeper`
**Goal:** Validate the full phone work before web continuation or final integration.
**Result:** Phone design is sealed for handoff, except for explicitly recorded blockers or open visual QA.

#### 11.1 Evidence And Screenshot Audit

- [ ] (`@PlanCritic | Skill: critique`) Confirm Phase 9 and Phase 10 have Open Design evidence notes.
- [ ] (`@PlanCritic | Skill: critique`) Confirm screenshot-driven decisions cite screenshot file paths or Open Design screenshot identities.
- [ ] (`@Sentinel | Skill: audit`) Confirm Open Design screenshots are not counted as Flutter runtime QA.
- [ ] (`@Pixel | Skill: audit`) Confirm every changed route has runtime screenshot, emulator note, or explicit manual QA blocker.
- **GATE CHECK:** Evidence labels are complete before final QA.

#### 11.2 Token Centralization And MVVM Audit

- [ ] (`@Architect`) Confirm reusable design values live in `lib/core/theme/designs/amber_dusk/`, `lib/core/theme/`, or existing shared widgets.
- [ ] (`@CodeGuard`) Run `rg 'Supabase\.instance|\.from\(|\.rpc\(' lib/features/*/view lib/app`.
- [ ] (`@CodeGuard`) Run `rg 'Color\(0x|#[0-9A-Fa-f]{6}|Colors\.|BoxShadow\(|Duration\(milliseconds:|fontSize:' lib/features lib/app`.
- [ ] (`@CodeGuard`) Run `rg 'BackdropFilter|ImageFilter\.blur|glass_' lib/core lib/features`.
- [ ] (`@Sentinel`) Confirm every static-scan exception has a reason in the session log.
- **GATE CHECK:** No unapproved visual or MVVM violations remain.

#### 11.3 Automated Verification

- [ ] (`@Sentinel`) Run `dart format --set-exit-if-changed .`.
- [ ] (`@Sentinel`) Run `flutter analyze --no-fatal-infos`.
- [ ] (`@Sentinel`) Run `git diff --check`.
- [ ] (`@Sentinel`) Run `flutter test test/core/theme/ test/core/widgets/`.
- [ ] (`@Sentinel`) Run `flutter test test/unit/profile test/features/profile/services test/unit/portfolio test/unit/services`.
- [ ] (`@Sentinel`) Run `flutter test test/features/favorites test/unit/categories test/unit/search test/unit/saved`.
- [ ] (`@Sentinel`) Run `flutter test test/unit/notifications test/widget/notifications`.
- [ ] (`@Sentinel`) Run `flutter test`.
- [ ] (`@CodeGuard`) If a coverage percentage target is introduced later, run `flutter test --coverage` and parse `coverage/lcov.info` before setting that target.
- **GATE CHECK:** Final automated gates pass or blockers are documented with exact failing commands.

#### 11.4 Phone Runtime Smoke Matrix

- [ ] (`@Sentinel | Skill: audit`) Smoke app shell Home, Dashboard, Messages, Profile, and bottom nav at 360, 390, 402, and 430 logical widths.
- [ ] (`@Sentinel | Skill: audit`) Smoke Phase 9: own profile, edit profile, public profile tabs, profile preview modal, settings, portfolio screen, add/edit/details portfolio sheets, manage portfolio, my services.
- [ ] (`@Sentinel | Skill: audit`) Smoke Phase 10: categories, search, favorites, saved, notifications modal, notification badge, loading utility, status helper, and CTA helper outputs.
- [ ] (`@Pixel | Skill: polish`) Record visual deviations from Open Design as accepted adaptation, missing evidence, or implementation blocker.
- [ ] (`@Architect`) Confirm no smoke finding requires data-layer work unless a separate plan is opened.
- **GATE CHECK:** Manual/emulator visual QA is complete or open gates are explicitly carried forward.

#### 11.5 PlanCritic Final Approval

- [ ] (`@PlanCritic | Skill: critique`) Confirm implementation covers all Phase 9 and Phase 10 targets from the root phone plan.
- [ ] (`@PlanCritic | Skill: critique`) Confirm Phase 12 handoff/docs closure is ready and not substituting for missing Phase 9/10 implementation.
- [ ] (`@Sentinel`) Confirm final verification commands are recorded in the session log.
- [ ] (`@DocsKeeper`) Confirm docs updates needed by implementation are queued for Phase 12.
- **GATE CHECK:** PASS only if `@PlanCritic` approves or exact blockers are recorded.

---

### Phase 12: Phone-To-Web Handoff, Docs Closure, And Artifact Routing

**Primary agents:** `@DocsKeeper`, `@Planner`, `@Pixel`, `@Sentinel`, `@Architect`
**Goal:** Close the phone planning/execution loop and prepare Mohammed's web continuation.
**Result:** Mohammed can start web Phase 9+ from current phone truth, and future Codex runs can see what is done, open, or blocked.

#### 12.1 Handoff Scope Definition

- [ ] (`@Planner`) Record `Phase 12 = phone-to-web handoff/docs closure` in the execution session log.
- [ ] (`@Sentinel`) Confirm no Phase 12 implementation diff touches `lib/` unless it is a docs-linked typo or test harness cleanup approved by Phase 11.
- [ ] (`@DocsKeeper`) Record that older roadmap/dashboard/wallet Phase 12 labels do not apply to this Amber Dusk closure phase.
- **GATE CHECK:** Phase 12 is not allowed to become a new feature implementation bucket.

#### 12.2 Evidence Index And Gap Register

- [ ] (`@Pixel | Skill: audit`) List Open Design files and screenshot identities used for Phase 9/10.
- [ ] (`@Sentinel | Skill: audit`) List Flutter runtime screenshot/manual evidence for every changed route/state.
- [ ] (`@Sentinel | Skill: audit`) List static scans, focused tests, full tests, and pass/fail status.
- [ ] (`@DocsKeeper`) List unresolved product/data/design gaps such as missing exact proof, route TODOs, old roadmap naming, or manual QA blockers.
- **GATE CHECK:** Evidence index separates complete, adapted, blocked, and unverified surfaces.

#### 12.3 Mohammed Web Handoff

- [ ] (`@DocsKeeper`) Create or update `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phases9_10_11_12_ToWeb_2026-05-13.md` after implementation.
- [ ] (`@Pixel | Skill: adapt`) Map phone profile modules to web profile modules: identity hero, proof stats, services, portfolio, reviews, grouped settings, edit modal/sheet parity.
- [ ] (`@Pixel | Skill: adapt`) Map phone secondary surfaces to web parity requirements: search, categories, favorites, saved, notifications, loading/error states, status helpers.
- [ ] (`@Architect`) Preserve web/phone contract: Home, Dashboard, Messages, Profile remain primary destinations unless a separate nav plan changes it.
- [ ] (`@Sentinel`) Include open visual QA and missing screenshot evidence as explicit web blockers.
- **GATE CHECK:** Mohammed handoff has enough route/screen detail to start web continuation.

#### 12.4 Docs Sync

- [ ] (`@DocsKeeper`) Update `README.md` status only if Phase 9/10 implementation changes shipped surfaces or open gates.
- [ ] (`@DocsKeeper`) Update `Sline_everything/DEVELOPER_GUIDE.md` and feature docs only when behavior/architecture descriptions changed.
- [ ] (`@DocsKeeper`) Update `Sline_everything/STRUCTURE.md` if files are added, moved, or materially reclassified.
- [ ] (`@DocsKeeper`) Update `Sline_everything/MVP_ROADMAP.md` Amber Dusk status and phase numbering notes.
- [ ] (`@DocsKeeper`) Update `Sline_everything/CODE_REVIEW.md` with any durable review rule learned from Phase 9/10.
- [ ] (`@DocsKeeper`) Update `Sline_everything/Sline_Log.md` with session outcome.
- [ ] (`@DocsKeeper`) Update `Sline_everything/UI_SURFACE_INVENTORY.md` if any UI surface was discovered, renamed, added, or removed.
- [ ] (`@DocsKeeper`) Update `Sline_everything/DOC_SOURCE_MAP.md` only if source routing changes.
- [ ] (`@Sentinel`) Confirm `Sline_everything/SUPABASE_SETUP.md` remains unchanged unless backend objects changed.
- **GATE CHECK:** Docs sync is scoped to actual code/workflow changes.

#### 12.5 Artifact Routing And Closure

- [ ] (`@DocsKeeper`) Create `.TODO/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md` after implementation if docs changed.
- [ ] (`@DocsKeeper`) Create final master report or closure note after implementation and verification.
- [ ] (`@DocsKeeper`) Archive completed generated evidence only after final closure; keep root master plans and active handoffs available.
- [ ] (`@Sentinel`) Run `git diff --check` after docs/artifact updates.
- [ ] (`@Planner`) Ensure the session log contains final status, evidence pointers, and known open gates before closure.
- **GATE CHECK:** Phase 12 closes the workflow without hiding active plans or open blockers.

---

## I) Change Report

### Original Issues Summary

- The draft was a Planner plan, not a PlanCritic source-of-truth gate.
- The draft did not persist a critique artifact.
- Related TODO evidence was broad but did not fully promote prior phase critiques, handoffs, old UI docs, and open emulator gates to a mandatory source set.
- Phase 12 existed but needed a resolved non-code scope decision.
- Missing exact design states needed stricter adaptation-only labels.
- Raw-token scans needed baseline/diff handling.
- Test infrastructure needed a blocking Gate 0.
- Runtime visual closure needed stronger release language.

### Added Steps

- Added PlanCritic A-I structure.
- Added critique artifact path.
- Added required related source set.
- Added Gate 0 test infrastructure matrix.
- Added Open Design evidence authority labels.
- Added Phase 12 handoff/docs-only decision.
- Added live four-tab nav contract.
- Added raw-token/no-glass/backend no-change guard scans.
- Added final runtime visual smoke matrix.
- Added Mohammed web handoff requirements.

### Removed Steps

- Removed any implicit permission to use old UI docs as current visual truth.
- Removed any implicit Phase 12 runtime feature work.
- Removed any implicit exact-match claim for missing design states.

### Reordered Steps

- PlanCritic source-of-truth gate now precedes execution.
- Evidence/source lock now precedes Phase 9 edits.
- Gate 0 test setup now precedes test edits.
- Runtime visual QA now precedes Phase 12 closure.
- Docs/handoff now happens after implementation truth is known.

### Expanded Steps

- Expanded Phase 9 into own profile, edit/settings/avatar, public profile, portfolio, and services sub-surfaces.
- Expanded Phase 10 into categories/search/favorites/saved, notifications/helper states, and accessibility/overflow.
- Expanded Phase 11 into evidence, tokens/MVVM, automated verification, runtime matrix, and PlanCritic approval.
- Expanded Phase 12 into scope, evidence index, web handoff, docs sync, and artifact routing.

### Residual Risks

- Runtime visual parity remains open until emulator/manual proof is captured.
- Exact designs for several secondary states are still missing.
- Widget tests for Type B screens may require lower-level harnesses or documented manual fixtures.
- Font asset licensing remains unresolved.
- Web continuation still depends on phone execution truth after this plan is implemented.
