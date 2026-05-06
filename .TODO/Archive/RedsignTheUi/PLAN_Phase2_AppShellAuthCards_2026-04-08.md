# Plan: Phase 2 — App Shell, Authentication & Cards Redesign

## 1) Goal
- **Goal:** Redesign the app shell (navigation, transitions), all 7 authentication screens, and all 8 card widgets to use the design system tokens established in Phase 0/1, with purposeful motion, semantic color tokens, and accessibility.
- **Why:** The app shell uses default `MaterialPageRoute` transitions everywhere and the FAB has no entrance animation. Auth screens are the first impression and currently have zero motion, SnackBar-only errors, and no password strength feedback. Cards appear on nearly every screen and still use hardcoded shadows, colors, and InkWell-only tap feedback. Upgrading these 18 files transforms the perceived quality of the entire app.
- **Result:** Custom `SlinePageRoute` transition system wired via `onGenerateRoute`, animated FAB with scroll-aware visibility, 7 auth screens with stagger entrance + inline validation + password strength, 8 card widgets with ScaleButton press states + semantic tokens + elevation scale. ~8 new widget test files.

## 2) Scope

### In-Scope
- Route transition infrastructure (`custom_route_transitions.dart`, `main.dart`)
- Main navigation screen redesign (`main_navigation_screen.dart`)
- Auth screens: login, signup, forgot password, reset password, maintenance, update required, account restricted
- Task cards: `task_card.dart`, `tender_task_card.dart`, `booking_task_card.dart`
- Booking cards: `booking_card.dart`, `dashboard_booking_card.dart`
- Dashboard cards: `work_item_card.dart`, `dashboard_offer_card.dart`, `dashboard_counters_grid.dart`
- Widget tests for auth screens and card widgets

### Out-of-Scope
- Any Supabase/backend changes
- Auth logic changes (only UI presentation)
- Home/Discovery screen redesign (Phase 3)
- Chat/Messaging redesign (Phase 4)
- Dashboard screen structure (Phase 5) — only dashboard card widgets are in scope
- Profile screens (Phase 6)
- Adding `package:animations` to pubspec.yaml (all transitions use core Flutter APIs)

## 3) Evidence & Findings (From Scan)

### Existing
- **Phase 0 deliverables confirmed:**
  - `app_motion.dart` (117 lines) — duration, curve, scale, stagger tokens
  - `app_states.dart` (114 lines) — 8-state interaction model constants
  - `app_decorations.dart` — `elevation()` method with 5-level shadow scale
  - `app_colors.dart` — semantic colors (success/warning/info/danger + muted variants + interactive overlays)
  - `app_typography.dart` — per-style line heights (body 1.4-1.5, headings 1.1-1.2)
  - `app_theme.dart` — 7 component themes (Card, Dialog, BottomSheet, Chip, Divider, SnackBar, TabBar)
  - `.impeccable.md` — design context established
- **Phase 1 deliverables confirmed:**
  - `ScaleButton` (129 lines) — spring physics + haptics + reduced-motion support
  - `AppButton` — 8-state model
  - `GlassContainer` — solid surface migration
  - `StatusBadge` — semantic colors + icon + pulse
  - `SkeletonCard` — expanded variants
- **Route transitions:** `custom_route_transitions.dart` (117 lines) — only `SlideUpRoute` (400ms, easeOutCubic) and `FadeRoute` (300ms). No `SlinePageRoute` factory.
- **main.dart:** Uses `routes:` named route map (NOT `onGenerateRoute`). 598 lines.
- **main_navigation_screen.dart:** 186 lines. `AnimatedSwitcher` with default fade between 7 tabs. FAB at fixed position.
- **Auth screens:** 7 files, 1,204 lines total. Login (321), Signup (371), ForgotPassword (179), ResetPassword (165), AccountRestricted (78), Maintenance (46), UpdateRequired (44).
- **Card widgets:** 8 files, 2,987 lines total. TaskCard (334), TenderTaskCard (305), BookingTaskCard (477), BookingCard (222), DashboardBookingCard (223), WorkItemCard (298), DashboardOfferCard (528), DashboardCountersGrid (152).
- **Existing tests:** `test/widget/auth/login_screen_test.dart` (1 file), `test/unit/auth/` (3 files). No card widget tests.

### Missing
- `SlinePageRoute` factory — does NOT exist
- `onGenerateRoute` — main.dart uses `routes:` map instead
- Stagger animation on any auth screen — zero instances
- Inline form validation on auth screens — errors use `ScaffoldMessenger.showSnackBar` only
- Password strength indicator — does NOT exist
- `ScaleButton` usage on any card — cards still use `InkWell` or `GestureDetector`
- Semantic color tokens on any card — status colors hardcoded in switch statements
- `AppDecorations.elevation()` usage on any card — shadows hardcoded per widget
- Widget tests for cards — zero exist
- FAB entrance animation — none
- FAB scroll-aware hide/show — none

### Must NOT Duplicate
- `ScaleButton` already exists in `core/widgets/` — cards must USE it, not re-implement tap-to-scale
- `StatusBadge` already redesigned in Phase 1 — cards must USE it, not have inline status rendering
- `AppMotion` tokens exist — no hardcoded `Duration(milliseconds:` allowed
- `AppDecorations.elevation()` exists — no hardcoded `BoxShadow` allowed
- Semantic colors exist in `AppColorScheme` — no hardcoded `Color(0x` for status indicators

### Conflicts / Risks
- **`package:animations` NOT available:** Master Plan references `OpenContainer` and `SharedAxisTransition`. Must build all transitions with core Flutter APIs only.
- **`booking_task_card.dart` Transform.translate:** `Transform.translate(offset: Offset(0, -24))` overlaps avatar on header. Removing this changes card height — regression risk for all callers.
- **`dashboard_offer_card.dart` complexity:** 528 lines, 10+ conditional branches for different offer states. Too complex for single-pass redesign.
- **Auth screen StatefulWidget status:** Login and Signup may need conversion to StatefulWidget for `AnimationController` support.
- **Named route map migration:** Moving from `routes:` to `onGenerateRoute` is mechanical but high-blast-radius if a route name is misspelled.
- **Typography line-height spillover:** Phase 0 changed body text from `height: 1.2` to `1.5`. Cards may now have text wrapping differently.

## 4) System Impact Map
- **UI:** 18 view/widget files modified. Route transition affects every screen navigation. Typography line-height spillover from Phase 0 may subtly shift card layouts.
- **MVVM / App Logic:** `main.dart` route resolution changes from map to factory. No ViewModel changes.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** None.
- **Compatibility & Migration:** Route migration is additive (old named routes still work). Card layout changes may affect parent screen layouts.
- **Contracts:** None.

## 5) Agent Map
- **Phase 1 (Pre-Flight):** `@Sentinel` (primary), `@Architect` (review)
- **Phase 2 (Route Foundation):** `@Architect` (primary), `@Pixel` (transitions), `@Sentinel` (gate)
- **Phase 3 (App Shell):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 4 (Auth — Login & Signup):** `@Pixel` (primary), `@Architect` (conversion), `@Sentinel` (gate)
- **Phase 5 (Auth — Supporting Screens):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6 (Task Cards):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (Booking Cards):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 8 (Dashboard Cards):** `@Pixel` (primary), `@Architect` (extraction), `@Sentinel` (gate)
- **Phase 9 (Widget Tests):** `@Sentinel` (primary), `@Architect` (test infrastructure)
- **Phase 10 (Visual QA & Polish):** `@Sentinel` (primary), `@Pixel` (fixes)
- **Phase 11 (Documentation):** `@SlineDocs` (primary), `@Sentinel` (gate)

**Session Log:** `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md`

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

### 0.1 Spec Lock
- [ ] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [ ] (`@Architect`) Confirm touched modules: `lib/app/`, `lib/core/utils/`, `lib/features/auth/view/`, `lib/features/tasks/view/widgets/`, `lib/features/booking/view/widgets/`, `lib/features/dashboard/view/widgets/`.
- [ ] (`@SlineDocs`) Confirm Phase 0 and Phase 1 deliverables exist: `app_motion.dart`, `app_states.dart`, `AppDecorations.elevation()`, semantic colors in `AppColorScheme`, `ScaleButton` upgraded, `StatusBadge` upgraded.
- **GATE CHECK:** Scope, acceptance criteria, and Phase 0/1 prerequisites confirmed.

### 0.2 Phase 0/1 Dependency Verification
- [ ] (`@Sentinel`) Verify `ScaleButton` has spring physics and `disabled` parameter.
- [ ] (`@Sentinel`) Verify `AppMotion` has all required tokens: `micro`, `fast`, `standard`, `slow`, `emphasis`, `curveStandard`, `curveDecel`, `curveSpring`, `pressScale`, stagger delays.
- [ ] (`@Sentinel`) Verify `AppDecorations.elevation()` returns correct shadow lists for levels 0-4.
- [ ] (`@Sentinel`) Verify `AppColorScheme` has `success`, `warning`, `info`, `danger` + muted variants.
- [ ] (`@Sentinel`) Verify `StatusBadge` uses semantic colors and has icon support.
- **GATE CHECK:** All Phase 0/1 tokens and components are available and functional.

---

## Phase 1: Pre-Flight & Analyzer Baseline

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Establish a clean analyzer baseline so Phase 2 changes can be verified in isolation.
**Why:** Pre-existing analyzer warnings conflated with new changes make gate checks impossible.
**How:** Run `flutter analyze`, document baseline, fix any errors (not warnings).
**Result:** Zero analyzer errors. Warnings documented in session log.

### 1.1 Analyzer Baseline
- [ ] (`@Sentinel`) Run `flutter analyze`. Document error count and warning count in session log.
- [ ] (`@Architect`) Fix any analyzer errors (not warnings) in files that will be modified in Phase 2.
- [ ] (`@Sentinel`) Re-run `flutter analyze`. Confirm 0 errors.
- **GATE CHECK:** `flutter analyze` returns 0 errors. Warning baseline documented.

---

## Phase 2: Route Transition Foundation

**Primary Agent(s):** `@Architect`, `@Pixel`
**Goal:** Create `SlinePageRoute` transition factory and migrate `main.dart` to `onGenerateRoute`.
**Why:** The named `routes:` map doesn't support custom page transitions. Every downstream screen transition depends on this infrastructure.
**How:** Create `SlinePageRoute` with named constructors in `custom_route_transitions.dart`. Migrate `main.dart` from `routes:` to `onGenerateRoute`.
**Result:** Centralized route resolution with custom transitions. All existing navigation preserved.

### 2.1 Create SlinePageRoute Factory
**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Define the transition vocabulary for the entire app.
**Why:** Consistent, intentional motion on every screen change.
**How:** Add `SlinePageRoute` class to `custom_route_transitions.dart`.
**Result:** Three transition types available: `forwardPush`, `modalSheet`, `fade`.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/core/utils/custom_route_transitions.dart`, add `SlinePageRoute` class with:
  - Sub-step 2.1.1: `SlinePageRoute.forwardPush({required Widget child})` — slide up + fade (vertical shared-axis feel). Duration: `AppMotion.standard` (300ms). Curve: `AppMotion.curveDecel`. Uses `SlideTransition` + `FadeTransition` via `PageRouteBuilder`.
  - Sub-step 2.1.2: `SlinePageRoute.modalSheet({required Widget child})` — slide up from bottom with spring curve. Duration: `AppMotion.emphasis` (500ms). Curve: `AppMotion.curveSpring`. Barrier color: black38.
  - Sub-step 2.1.3: `SlinePageRoute.fade({required Widget child})` — simple crossfade. Duration: `AppMotion.fast` (200ms). Curve: `AppMotion.curveStandard`.
  - Sub-step 2.1.4: `respectMotion` integration — if `MediaQuery.disableAnimations`, use `Duration.zero` for all transitions.
  - Sub-step 2.1.5: Keep existing `SlideUpRoute` and `FadeRoute` with `@Deprecated` annotations pointing to `SlinePageRoute`.
- [ ] (`@Architect`) Review: confirm `SlinePageRoute` uses only core Flutter APIs (no `package:animations`). Confirm it returns `PageRoute<T>` for type safety.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.2 Migrate main.dart to onGenerateRoute
**Primary Agent(s):** `@Architect`
**Goal:** Centralize route resolution so transitions are consistent app-wide.
**Why:** `routes:` map doesn't support transition customization per route.
**How:** Convert the existing route map into an `onGenerateRoute` factory function. Every entry gets `SlinePageRoute.forwardPush` by default.
**Result:** All existing navigation works with new default transition.

- [ ] (`@Architect`) In `lib/main.dart`:
  - Sub-step 2.2.1: Extract the existing `routes` map entries into a `_resolveRoute(RouteSettings settings)` function that returns `Route<dynamic>?`.
  - Sub-step 2.2.2: Each route entry returns `SlinePageRoute.forwardPush(child: ScreenWidget())`.
  - Sub-step 2.2.3: Remove the `routes:` parameter from `MaterialApp`. Add `onGenerateRoute: _resolveRoute`.
  - Sub-step 2.2.4: Add fallback: unknown route returns `SlinePageRoute.fade(child: NotFoundScreen())` or the existing 404 behavior.
  - Sub-step 2.2.5: Preserve all existing route names exactly (verify against current `routes` map).
- [ ] (`@Sentinel`) Verify every named route still resolves. Test: navigate to each major screen by route name.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** All named routes resolve. Default transition is `forwardPush`. `flutter analyze` clean. No navigation regressions.

---

## Phase 3: App Shell — Main Navigation Screen

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Add fluid tab transitions, FAB entrance animation, and scroll-aware FAB to `MainNavigationScreen`.
**Why:** The app shell is visible on every tab. Default fade transitions and a static FAB make the app feel basic.
**How:** Replace `AnimatedSwitcher` fade with slide+fade transition. Add `ScaleTransition` FAB entrance. Add `NotificationListener<ScrollNotification>` for FAB hide/show.
**Result:** Polished app shell with intentional motion.

### 3.1 Tab Transition Upgrade
**Primary Agent(s):** `@Pixel`
**Goal:** Replace default fade with directional slide+fade between tabs.
**Why:** Horizontal direction hints at peer navigation (left/right between tabs), which is more intuitive than fade.
**How:** Custom `AnimatedSwitcher` transitionBuilder with `SlideTransition` + `FadeTransition`. Direction based on tab index change.
**Result:** Tabs feel connected and navigable.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/app/main_navigation_screen.dart`:
  - Sub-step 3.1.1: Track `_previousTabIndex` to determine slide direction (left→right or right→left).
  - Sub-step 3.1.2: Replace `AnimatedSwitcher` child transition with custom builder: entering screen slides in from direction of new tab, exiting slides out opposite direction.
  - Sub-step 3.1.3: Duration: `AppMotion.standard` (300ms). Curve: `AppMotion.curveStandard`.
  - Sub-step 3.1.4: Fade: concurrent opacity 0→1 entering, 1→0 exiting.
  - Sub-step 3.1.5: Respect `MediaQuery.disableAnimations` — if true, use instant switch (no animation).
- [ ] (`@Sentinel`) Verify all 7 tabs transition correctly in both directions.

### 3.2 FAB Entrance Animation
**Primary Agent(s):** `@Pixel`
**Goal:** FAB scales in on first render for a delightful entrance.
**Why:** A static FAB appearing feels dead. A spring entrance communicates interactivity.
**How:** `ScaleTransition` with `AnimationController` triggered once in `initState`.
**Result:** FAB springs in on app launch.

- [ ] (`@Pixel` | Skill: `delight`) In `lib/app/main_navigation_screen.dart`:
  - Sub-step 3.2.1: Add `late AnimationController _fabController` with `AppMotion.emphasis` (500ms) duration.
  - Sub-step 3.2.2: Add `late Animation<double> _fabScale` with `CurvedAnimation(curve: AppMotion.curveSpring)`.
  - Sub-step 3.2.3: Wrap FAB in `ScaleTransition(scale: _fabScale)`.
  - Sub-step 3.2.4: Call `_fabController.forward()` in `initState` after frame callback.
  - Sub-step 3.2.5: Add `_fabController.dispose()` in `dispose()`.
- [ ] (`@Sentinel`) Verify FAB animates in on cold launch. Verify `dispose()` cleans up.

### 3.3 FAB Scroll-Aware Visibility
**Primary Agent(s):** `@Pixel`
**Goal:** FAB hides when scrolling down (content focus), shows when scrolling up (action available).
**Why:** Material 3 pattern for FAB behavior. Reduces visual noise during content browsing.
**How:** `NotificationListener<UserScrollNotification>` wrapping the tab content. Animate FAB scale to 0 on scroll-down, back to 1 on scroll-up.
**Result:** FAB responds to scroll direction naturally.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/app/main_navigation_screen.dart`:
  - Sub-step 3.3.1: Wrap tab content in `NotificationListener<UserScrollNotification>`.
  - Sub-step 3.3.2: On `ScrollDirection.reverse` (scrolling down): animate `_fabController` to 0 (hide).
  - Sub-step 3.3.3: On `ScrollDirection.forward` (scrolling up): animate `_fabController` to 1 (show).
  - Sub-step 3.3.4: Use `AppMotion.fast` (200ms) for hide/show transition.
  - Sub-step 3.3.5: Debounce: ignore rapid direction changes within 50ms to prevent jitter.
- [ ] (`@Sentinel`) Verify FAB hides/shows smoothly. Verify no jank on rapid scroll direction changes.
- [ ] (`@Pixel` | Skill: `harden`) Verify FAB is always visible when at top of scroll (not accidentally hidden).

### 3.4 Runtime Banner Animation
**Primary Agent(s):** `@Pixel`
**Goal:** Animate the runtime environment banner instead of instant appearance.
**Why:** Even debug UI should feel intentional.
**How:** `SlideTransition` from top. Swipe-up to dismiss.
**Result:** Banner slides in, can be dismissed.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/app/main_navigation_screen.dart`:
  - Sub-step 3.4.1: Wrap runtime banner in `SlideTransition` with `Offset(0, -1)` → `Offset(0, 0)`.
  - Sub-step 3.4.2: Duration: `AppMotion.standard` (300ms). Curve: `AppMotion.curveDecel`.
  - Sub-step 3.4.3: Add `GestureDetector` for swipe-up dismiss (reverse animation then remove).
- [ ] (`@Sentinel`) Verify banner animates in. Verify swipe dismiss works.
- **GATE CHECK:** Tab transitions directional. FAB has spring entrance + scroll-aware visibility. Banner animated. `flutter analyze` clean.

---

## Phase 4: Authentication — Login & Signup

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Transform login and signup into premium first-impression screens with stagger entrance, inline validation, password strength, and shake-on-error.
**Why:** Auth screens are the first thing users see. Currently zero motion, SnackBar-only errors, no password feedback. This directly impacts user perception of app quality.
**How:** Convert to StatefulWidget, add AnimationControllers for stagger, replace SnackBars with inline errors, add password strength bar, add form shake.
**Result:** Premium auth experience with purposeful motion and clear feedback.

### 4.1 LoginScreen — StatefulWidget Conversion
**Primary Agent(s):** `@Architect`
**Goal:** Prepare LoginScreen for animation controllers.
**Why:** `AnimationController` requires `StatefulWidget` + `TickerProviderStateMixin`.
**How:** Convert class, add mixin, add controller fields, preserve existing behavior.
**Result:** LoginScreen is StatefulWidget with animation infrastructure ready.

- [ ] (`@Architect`) In `lib/features/auth/view/login_screen.dart` (321 lines):
  - Sub-step 4.1.1: If currently `StatelessWidget`, convert to `StatefulWidget` + `State` class.
  - Sub-step 4.1.2: Add `TickerProviderStateMixin` to State class.
  - Sub-step 4.1.3: Add `late AnimationController _staggerController` (duration: `AppMotion.emphasis` 500ms).
  - Sub-step 4.1.4: Add `late AnimationController _shakeController` (duration: `AppMotion.standard` 300ms).
  - Sub-step 4.1.5: Add `dispose()` method cleaning up both controllers.
  - Sub-step 4.1.6: Preserve ALL existing widget tree and behavior. No visual changes yet.
- [ ] (`@Sentinel`) Verify screen compiles and renders identically to before.

### 4.2 LoginScreen — Stagger Entrance Animation
**Primary Agent(s):** `@Pixel`
**Goal:** Fields and button appear with staggered slide-up + fade-in.
**Why:** Creates a premium first impression with intentional reveal timing.
**How:** Interval-based animations for each form element, triggered in `initState`.
**Result:** Logo → email → password → button appear sequentially.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/features/auth/view/login_screen.dart`:
  - Sub-step 4.2.1: Define animation intervals: Logo 0.0-0.3, Email field 0.15-0.45, Password field 0.30-0.60, Sign In button 0.45-0.75, Sign Up link 0.55-0.85.
  - Sub-step 4.2.2: For each element: `SlideTransition` (Offset(0, 0.3) → Offset.zero) + `FadeTransition` (0→1).
  - Sub-step 4.2.3: Create `CurvedAnimation` with `Interval` for each element, curve: `AppMotion.curveDecel`.
  - Sub-step 4.2.4: Trigger `_staggerController.forward()` in `initState` via `WidgetsBinding.instance.addPostFrameCallback`.
  - Sub-step 4.2.5: Total stagger time: 500ms. First interactive element (email) is usable at 450ms.
- [ ] (`@Sentinel`) Verify stagger timing. First input field must be interactive within 500ms.

### 4.3 LoginScreen — Inline Error Handling
**Primary Agent(s):** `@Pixel`
**Goal:** Replace SnackBar errors with inline field errors + form shake.
**Why:** SnackBars are dismissable and disconnected from the error source. Inline errors are contextual and persistent.
**How:** Add error text below each field with animated entrance. Shake entire form on invalid submit.
**Result:** Clear, contextual error feedback.

- [ ] (`@Pixel` | Skill: `clarify`) In `lib/features/auth/view/login_screen.dart`:
  - Sub-step 4.3.1: Add `String? _emailError` and `String? _passwordError` state fields.
  - Sub-step 4.3.2: Replace `ScaffoldMessenger.showSnackBar` calls with state field updates.
  - Sub-step 4.3.3: Below each `AppTextField`, add `AnimatedSize` + `AnimatedOpacity` wrapping error `Text` widget. Error text uses `AppTypography.caption` with `colorScheme.danger` color.
  - Sub-step 4.3.4: Error text slides in from top (`ClipRect` + `SlideTransition`) with `AppMotion.fast` (200ms).
  - Sub-step 4.3.5: Field border turns `colorScheme.danger` when error is set (pass error state to `AppTextField`).
- [ ] (`@Pixel` | Skill: `animate`) Form shake on invalid submit:
  - Sub-step 4.3.6: Wrap form in `AnimatedBuilder` driven by `_shakeController`.
  - Sub-step 4.3.7: Transform: `Transform.translate(offset: Offset(sin(_shakeController.value * pi * AppInteractionStates.shakeCycles) * AppInteractionStates.shakeAmplitude, 0))`.
  - Sub-step 4.3.8: Trigger shake on validation failure: `_shakeController.forward(from: 0)`.
  - Sub-step 4.3.9: Add `HapticFeedback.mediumImpact()` on shake trigger.
- [ ] (`@Sentinel`) Verify: invalid email shows inline error under email field. Invalid password shows inline error under password field. No SnackBars remain.

### 4.4 LoginScreen — Per-Field Validation Icons
**Primary Agent(s):** `@Pixel`
**Goal:** Show green check or red X inline as fields validate.
**Why:** Real-time feedback reduces submit-and-fail cycles.
**How:** Suffix icon on `AppTextField` that changes based on validation state.
**Result:** Immediate visual validation feedback.

- [ ] (`@Pixel` | Skill: `delight`) In `lib/features/auth/view/login_screen.dart`:
  - Sub-step 4.4.1: Add validation state enum: `none`, `valid`, `invalid`.
  - Sub-step 4.4.2: Email field: validate on `onChanged` with regex. Show green check (valid) or red X (invalid) as suffix icon.
  - Sub-step 4.4.3: Password field: validate on `onChanged` (min length). Show green check or red X.
  - Sub-step 4.4.4: Icons animate in with `AnimatedSwitcher` crossfade (duration: `AppMotion.fast`).
  - Sub-step 4.4.5: Add `Semantics` labels: "Email valid" / "Email invalid", "Password valid" / "Password invalid".
- [ ] (`@Sentinel`) Verify icons appear/change correctly. Verify Semantics labels.

### 4.5 SignupScreen — StatefulWidget Conversion + Stagger
**Primary Agent(s):** `@Architect`, `@Pixel`
**Goal:** Convert SignupScreen and add stagger entrance matching LoginScreen.
**Why:** Consistency between login and signup. Same premium feel.
**How:** Same pattern as LoginScreen conversion + stagger.
**Result:** SignupScreen has stagger entrance matching login.

- [ ] (`@Architect`) In `lib/features/auth/view/signup_screen.dart` (371 lines):
  - Sub-step 4.5.1: Convert to `StatefulWidget` + `TickerProviderStateMixin` (if not already).
  - Sub-step 4.5.2: Add `_staggerController` and `_shakeController` (same as login).
  - Sub-step 4.5.3: Add `dispose()`.
- [ ] (`@Pixel` | Skill: `animate`) Add stagger entrance:
  - Sub-step 4.5.4: Intervals: Logo 0.0-0.25, Name 0.10-0.35, Email 0.20-0.45, Password 0.30-0.55, Confirm Password 0.40-0.65, Button 0.50-0.75.
  - Sub-step 4.5.5: Same `SlideTransition` + `FadeTransition` pattern as login.
- [ ] (`@Pixel` | Skill: `clarify`) Add inline errors (same pattern as login 4.3).
- [ ] (`@Sentinel`) Verify stagger and inline errors work. No SnackBars remain.

### 4.6 SignupScreen — Password Strength Indicator
**Primary Agent(s):** `@Pixel`
**Goal:** Animated colored bar below password field showing strength.
**Why:** Users need real-time feedback on password quality. Reduces failed submissions.
**How:** Linear progress bar with color transitions (red → orange → yellow → green) based on strength score.
**Result:** Password strength is visible and motivating.

- [ ] (`@Pixel` | Skill: `delight`) In `lib/features/auth/view/signup_screen.dart`:
  - Sub-step 4.6.1: Add `_passwordStrength` double (0.0 - 1.0) state field.
  - Sub-step 4.6.2: Calculate strength on `onChanged`: +0.25 for length ≥ 8, +0.25 for uppercase, +0.25 for number, +0.25 for special char.
  - Sub-step 4.6.3: Below password field: `AnimatedContainer` bar with `width: strength * totalWidth`. Duration: `AppMotion.fast`.
  - Sub-step 4.6.4: Color: `Color.lerp` through red → orange → yellow → green based on strength value.
  - Sub-step 4.6.5: Label below bar: "Weak" (red), "Fair" (orange), "Good" (yellow), "Strong" (green). Uses `AppTypography.micro`.
  - Sub-step 4.6.6: Add `Semantics` label: "Password strength: [level]".
- [ ] (`@Pixel` | Skill: `clarify`) Add confirm password match/mismatch:
  - Sub-step 4.6.7: Suffix icon on confirm password: green check if matches, red X if doesn't (same pattern as login validation icons).
- [ ] (`@Sentinel`) Verify strength bar updates in real time. Verify color transitions are smooth. Verify confirm password indicator works.
- **GATE CHECK:** Login and Signup have stagger entrance, inline errors, form shake, validation icons, password strength. No SnackBars. `flutter analyze` clean.

---

## Phase 5: Authentication — Supporting Screens

**Primary Agent(s):** `@Pixel`
**Goal:** Polish the 5 supporting auth screens (forgot password, reset password, maintenance, update required, account restricted) with animated icons, success states, and illustrated empty states.
**Why:** These are edge-case screens but they represent the brand when users are already frustrated (forgot password, account restricted). Quality here builds trust.
**How:** Add animated icons, success/redirect states, Support CTAs.
**Result:** Every auth edge-case feels considered and helpful.

### 5.1 ForgotPasswordScreen — Success State
**Primary Agent(s):** `@Pixel`
**Goal:** Show animated email-sent success state instead of SnackBar.
**Why:** Users need clear confirmation that the reset email was sent. SnackBar is dismissable and easy to miss.
**How:** After successful submission, transition form to success view with animated mail icon.
**Result:** Clear "Check your inbox" state with visual feedback.

- [ ] (`@Pixel` | Skill: `clarify`) In `lib/features/auth/view/forgot_password_screen.dart` (179 lines):
  - Sub-step 5.1.1: Add `bool _emailSent` state field.
  - Sub-step 5.1.2: On successful API call, set `_emailSent = true` instead of showing SnackBar.
  - Sub-step 5.1.3: `AnimatedSwitcher` between form view and success view.
  - Sub-step 5.1.4: Success view: large mail icon (48px, `colorScheme.success`) with `ScaleTransition` entrance (scale 0→1, `AppMotion.curveSpring`).
  - Sub-step 5.1.5: "Check your inbox" title (h4) + "We sent a reset link to [email]" body (bodyMedium, secondary color).
  - Sub-step 5.1.6: "Back to Login" button below.
- [ ] (`@Sentinel`) Verify success state appears after submission. No SnackBars.

### 5.2 ResetPasswordScreen — Requirements Checklist
**Primary Agent(s):** `@Pixel`
**Goal:** Show password requirements with real-time check animations.
**Why:** Users need to know exactly what the password needs. A checklist is more helpful than a single error message.
**How:** List of requirements, each turns green with check animation as met.
**Result:** Clear, real-time password requirement feedback.

- [ ] (`@Pixel` | Skill: `clarify`) In `lib/features/auth/view/reset_password_update_screen.dart` (165 lines):
  - Sub-step 5.2.1: Define requirements list: ≥8 chars, ≥1 uppercase, ≥1 number, ≥1 special char.
  - Sub-step 5.2.2: Each requirement: `Row` with animated icon (grey circle → green check, `AnimatedSwitcher` crossfade `AppMotion.fast`) + requirement text.
  - Sub-step 5.2.3: Text color: `colorScheme.textSecondary` when unmet, `colorScheme.success` when met.
  - Sub-step 5.2.4: Auto-redirect after successful reset: show "Password updated! Redirecting in 3..." with countdown.
- [ ] (`@Pixel` | Skill: `animate`) Countdown redirect:
  - Sub-step 5.2.5: 3-second `Timer.periodic` countdown displayed below success message.
  - Sub-step 5.2.6: Navigate to login screen when countdown reaches 0.
- [ ] (`@Sentinel`) Verify requirements update in real time. Verify redirect works.

### 5.3 MaintenanceScreen — Animated Icon
**Primary Agent(s):** `@Pixel`
**Goal:** Add a slowly rotating wrench icon and retry capability.
**Why:** A static dead-end screen is frustrating. Animation shows the app is alive. Retry gives users agency.
**How:** `RotationTransition` on wrench icon. Retry button that checks server status.
**Result:** Friendly maintenance experience.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/features/auth/view/maintenance_screen.dart` (46 lines):
  - Sub-step 5.3.1: Add wrench icon (48px) with `RotationTransition` (slow: 8 seconds per rotation, `Curves.linear`, repeat).
  - Sub-step 5.3.2: "We'll be back soon" title (h4) + explanation body text.
  - Sub-step 5.3.3: "Try Again" button with loading state.
  - Sub-step 5.3.4: Add `Semantics` label: "App under maintenance".
- [ ] (`@Sentinel`) Verify animation loops. Verify retry button works.

### 5.4 UpdateRequiredScreen — Store Link CTA
**Primary Agent(s):** `@Pixel`
**Goal:** Add animated update icon and direct store link.
**Why:** Users need to know exactly what to do and how to update.
**How:** Animated download/update icon. "Update Now" button linking to app store.
**Result:** Clear update path.

- [ ] (`@Pixel` | Skill: `clarify`) In `lib/features/auth/view/update_required_screen.dart` (44 lines):
  - Sub-step 5.4.1: Add animated download icon (48px) — `SlideTransition` with subtle bounce-down.
  - Sub-step 5.4.2: "Update Required" title + version info body.
  - Sub-step 5.4.3: "Update Now" filled button (teal, full-width).
  - Sub-step 5.4.4: Add `Semantics` label: "App update required".
- [ ] (`@Sentinel`) Verify layout and icon animation.

### 5.5 AccountRestrictedScreen — Support CTA
**Primary Agent(s):** `@Pixel`
**Goal:** Add empathetic messaging and a "Contact Support" button.
**Why:** Account restriction is stressful. Empathetic design and a clear support path reduce frustration.
**How:** Styled card with reason display and support button.
**Result:** Clear reason, clear next step.

- [ ] (`@Pixel` | Skill: `clarify`) In `lib/features/auth/view/account_restricted_screen.dart` (78 lines):
  - Sub-step 5.5.1: Add shield/lock icon (48px, `colorScheme.danger`) with `FadeTransition` entrance.
  - Sub-step 5.5.2: "Account Restricted" title (h4) + reason text from API (bodyMedium).
  - Sub-step 5.5.3: "Contact Support" filled button (teal, full-width).
  - Sub-step 5.5.4: "Log Out" text button below (muted styling, less prominent).
  - Sub-step 5.5.5: Add `Semantics` label: "Account restricted. Reason: [reason]".
- [ ] (`@Sentinel`) Verify layout, icon, and button actions.
- **GATE CHECK:** All 5 supporting auth screens have animated icons, clear messaging, and actionable CTAs. No SnackBars. `flutter analyze` clean.

---

## Phase 6: Task Cards

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Redesign TaskCard, TenderTaskCard, and BookingTaskCard with ScaleButton, semantic tokens, elevation scale, and consistent layout.
**Why:** These 3 cards appear on nearly every task-related screen. They still use hardcoded shadows, InkWell, and random colors.
**How:** Wrap in ScaleButton, replace hardcoded shadows with `AppDecorations.elevation()`, replace hardcoded colors with semantic tokens, fix layout issues.
**Result:** Consistent, animated, accessible task cards.

### 6.1 TaskCard — Remove Header, Semantic Tokens
**Primary Agent(s):** `@Pixel`
**Goal:** Remove the 120px colored header, replace with compact layout. Use semantic tokens.
**Why:** 120px header wastes space and looks like a template. Semantic tokens ensure consistency with design system.
**How:** Remove header, restructure to compact card. Replace all hardcoded values.
**Result:** Modern, compact task card.

- [ ] (`@Pixel` | Skill: `distill`) In `lib/features/tasks/view/widgets/task_card.dart` (334 lines):
  - Sub-step 6.1.1: Remove the 120px colored header section entirely.
  - Sub-step 6.1.2: New layout: compact card with optional 60x60 thumbnail left (if image exists), content middle, price right.
  - Sub-step 6.1.3: Title: `AppTypography.bodyLarge`, bold, maxLines 2, `TextOverflow.ellipsis`.
  - Sub-step 6.1.4: Meta row: category pill + deadline + bid count in `AppTypography.caption`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace hardcoded values:
  - Sub-step 6.1.5: Replace all `BoxShadow(...)` with `AppDecorations.elevation(1)`.
  - Sub-step 6.1.6: Replace `InkWell` wrapper with `ScaleButton`.
  - Sub-step 6.1.7: Replace hardcoded status colors with `colorScheme.success/warning/danger/info` via `StatusBadge`.
  - Sub-step 6.1.8: Replace hardcoded border radius with `AppDimens.r16`.
- [ ] (`@Pixel` | Skill: `harden`) Accessibility:
  - Sub-step 6.1.9: Wrap card in `Semantics(button: true, label: '[task title], [status], [price]')`.
- [ ] (`@Sentinel`) Verify card renders in list view. Verify ScaleButton press feedback. Verify no hardcoded `BoxShadow` or `Color(0x` remain.

### 6.2 TaskCard — Caller Audit
**Primary Agent(s):** `@Sentinel`
**Goal:** Verify all screens displaying TaskCard handle the new layout dimensions.
**Why:** Removing the 120px header changes card height, which affects list item extent and scroll position.
**How:** Grep for `TaskCard` usage. Check each parent's layout.
**Result:** No layout regressions.

- [ ] (`@Sentinel`) Grep for `TaskCard(` across all files in `lib/`. List every usage location.
- [ ] (`@Sentinel`) For each caller: verify the parent layout (ListView, Column, Grid) can handle variable-height cards without overflow.
- [ ] (`@Sentinel`) Document findings in session log.

### 6.3 TenderTaskCard — Typography Cleanup + Semantic Tokens
**Primary Agent(s):** `@Pixel`
**Goal:** Replace all hardcoded fontSize values with AppTypography. Use semantic tokens.
**Why:** TenderTaskCard has hardcoded fontSize=10, 11, 13, 16 scattered throughout. This violates the design system.
**How:** Replace every hardcoded fontSize with `AppTypography.*`. Replace shadows and colors with tokens.
**Result:** Typography-consistent, token-based tender card.

- [ ] (`@Pixel` | Skill: `normalize`) In `lib/features/tasks/view/widgets/tender_task_card.dart` (305 lines):
  - Sub-step 6.3.1: Replace all hardcoded `fontSize: 10` with `AppTypography.micro`.
  - Sub-step 6.3.2: Replace all hardcoded `fontSize: 11` with `AppTypography.caption`.
  - Sub-step 6.3.3: Replace all hardcoded `fontSize: 13` with `AppTypography.bodySmall`.
  - Sub-step 6.3.4: Replace all hardcoded `fontSize: 16` with `AppTypography.bodyLarge`.
  - Sub-step 6.3.5: Replace `InkWell` with `ScaleButton`.
  - Sub-step 6.3.6: Replace hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 6.3.7: Replace hardcoded status colors with semantic tokens.
  - Sub-step 6.3.8: Price in `colorScheme.warning` (gold) to differentiate from booking's teal.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics` wrapper.
- [ ] (`@Sentinel`) Verify zero hardcoded `fontSize` values remain. Verify semantic tokens used for all colors.

### 6.4 BookingTaskCard — Remove Transform.translate Hack
**Primary Agent(s):** `@Pixel`
**Goal:** Replace `Transform.translate(offset: Offset(0, -24))` with proper layout. Semantic tokens.
**Why:** Transform.translate doesn't affect layout — the card's actual bounds don't match visual bounds. This causes tap-target misalignment and parent layout confusion.
**How:** Remove Transform.translate. Use `Stack` with `Positioned` if overlap is desired, or move avatar into content area.
**Result:** Correct layout bounds matching visual bounds.

- [ ] (`@Pixel` | Skill: `distill`) In `lib/features/tasks/view/widgets/booking_task_card.dart` (477 lines):
  - Sub-step 6.4.1: Remove `Transform.translate(offset: Offset(0, -24))` on avatar.
  - Sub-step 6.4.2: Option A: Move avatar into content area (inline with name + rating). This is simpler and more modern.
  - Sub-step 6.4.3: Reduce gradient header from 90px to 60px (subtle, not dominant).
  - Sub-step 6.4.4: Replace hardcoded "4.9" rating with actual data parameter or remove if not available.
- [ ] (`@Pixel` | Skill: `normalize`) Token replacement:
  - Sub-step 6.4.5: Replace `InkWell` with `ScaleButton`.
  - Sub-step 6.4.6: Replace all hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 6.4.7: Replace hardcoded colors with semantic tokens.
  - Sub-step 6.4.8: Replace hardcoded border radius with `AppDimens` values.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics` wrapper.

### 6.5 BookingTaskCard — Caller Audit
**Primary Agent(s):** `@Sentinel`
**Goal:** Verify all callers handle new card height after Transform.translate removal.
**Why:** Removing Transform.translate changes the card's actual height (it was 24px shorter than visual). Parents may have compensated for this.
**How:** Grep for `BookingTaskCard(` usage. Check each parent.
**Result:** No layout regressions.

- [ ] (`@Sentinel`) Grep for `BookingTaskCard(` across all files. List every usage.
- [ ] (`@Sentinel`) For each caller: verify layout handles new height. Check for any hardcoded `SizedBox` or padding that compensated for the Transform offset.
- [ ] (`@Sentinel`) Document findings in session log.
- **GATE CHECK:** All 3 task cards use ScaleButton, AppDecorations.elevation(), semantic tokens, AppTypography. Zero hardcoded shadows, colors, or font sizes. Caller audits complete. `flutter analyze` clean.

---

## Phase 7: Booking Cards

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Redesign BookingCard and DashboardBookingCard with semantic tokens, modern layout, and implemented Message button.
**Why:** Booking cards use hardcoded "$" formatting, micro-text status badges, and a TODO Message button. These are visible on multiple screens.
**How:** Use PriceFormatter, semantic StatusBadge, and callback-based Message button.
**Result:** Consistent, functional booking cards.

### 7.1 BookingCard — Modern List Tile
**Primary Agent(s):** `@Pixel`
**Goal:** Upgrade to modern list tile with proper hierarchy and animated press feedback.
**Why:** Current card has micro-text status badge (too small), hardcoded "$", and no press animation.
**How:** Enlarge status badge, use PriceFormatter, wrap in ScaleButton.
**Result:** Clear hierarchy: status → title → meta → price.

- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/booking/view/widgets/booking_card.dart` (222 lines):
  - Sub-step 7.1.1: Status badge first in content area (prominent, using redesigned `StatusBadge`).
  - Sub-step 7.1.2: Title below status: `AppTypography.bodyLarge`, bold, maxLines 2.
  - Sub-step 7.1.3: Meta line: date + provider name in `AppTypography.caption`, `colorScheme.textSecondary`.
  - Sub-step 7.1.4: Price right-aligned: `AppTypography.bodyLarge`, `colorScheme.primary` (teal).
- [ ] (`@Pixel` | Skill: `normalize`) Token replacement:
  - Sub-step 7.1.5: Replace `InkWell` with `ScaleButton`.
  - Sub-step 7.1.6: Replace hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 7.1.7: Replace hardcoded `$` formatting with `PriceFormatter` (or existing price utility).
  - Sub-step 7.1.8: Replace hardcoded status colors with `StatusBadge` widget.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics(button: true, label: '[booking title], [status], [price]')`.
- [ ] (`@Sentinel`) Verify hierarchy is clear. Verify no hardcoded values remain.

### 7.2 DashboardBookingCard — Implement Message Button
**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Replace TODO `onPressed` with callback pattern. Upgrade visual consistency.
**Why:** The Message button currently does nothing (TODO in source). The card should match BookingCard visual language.
**How:** Add `onMessagePressed` callback parameter. Parent wires it to navigation.
**Result:** Functional Message button with MVVM-compliant callback.

- [ ] (`@Architect`) In `lib/features/booking/view/widgets/dashboard_booking_card.dart` (223 lines):
  - Sub-step 7.2.1: Add `final VoidCallback? onMessagePressed` parameter to widget constructor.
  - Sub-step 7.2.2: Wire the Message `TextButton.onPressed` to `widget.onMessagePressed`.
  - Sub-step 7.2.3: If `onMessagePressed` is null, disable the button (grey out, no tap).
- [ ] (`@Pixel` | Skill: `normalize`) Token replacement:
  - Sub-step 7.2.4: Replace `InkWell` with `ScaleButton`.
  - Sub-step 7.2.5: Replace hardcoded values with tokens (same pattern as booking card).
  - Sub-step 7.2.6: Match BookingCard visual language (consistent card styling).
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics` wrapper.
- [ ] (`@Sentinel`) Verify Message button is wired to callback. Verify disabled state when callback is null.
- **GATE CHECK:** Both booking cards use ScaleButton, semantic tokens, proper price formatting. Message button is functional. `flutter analyze` clean.

---

## Phase 8: Dashboard Cards

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Redesign WorkItemCard, DashboardOfferCard, and DashboardCountersGrid with semantic tokens, extracted components, and animations.
**Why:** Dashboard is the command center. DashboardOfferCard is the most complex widget (528 lines, 10+ conditionals). CountersGrid is the first thing users see on the dashboard but has no animation.
**How:** Break DashboardOfferCard into sub-components. Add animated count-up to counters. Use semantic tokens throughout.
**Result:** Clean, animated, maintainable dashboard cards.

### 8.1 WorkItemCard — Avatar Size Fix + Semantic Tokens
**Primary Agent(s):** `@Pixel`
**Goal:** Fix tiny avatar (12px radius = 24px diameter) and use semantic tokens.
**Why:** 24px avatar is too small to recognize faces. Hardcoded colors don't match design system.
**How:** Increase avatar to 36px. Replace all hardcoded values with tokens.
**Result:** Readable avatar, consistent styling.

- [ ] (`@Pixel` | Skill: `normalize`) In `lib/features/dashboard/view/widgets/work_item_card.dart` (298 lines):
  - Sub-step 8.1.1: Change avatar `radius: 12` to `radius: 18` (36px diameter).
  - Sub-step 8.1.2: Replace type indicator full-width header with compact icon + colored dot.
  - Sub-step 8.1.3: Replace `InkWell` with `ScaleButton`.
  - Sub-step 8.1.4: Replace hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 8.1.5: Replace `lightRed` / hardcoded colors with semantic tokens (`colorScheme.danger`, `colorScheme.dangerMuted`).
  - Sub-step 8.1.6: Replace hardcoded border radius with `AppDimens` values.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics` wrapper with work item type + status + assignee.
- [ ] (`@Sentinel`) Verify avatar is 36px. Verify no hardcoded color values remain.

### 8.2 DashboardOfferCard — Extract OfferActionRow
**Primary Agent(s):** `@Architect`, `@Pixel`
**Goal:** Extract the complex action button section into a separate `_OfferActionRow` widget.
**Why:** 528 lines with 10+ conditionals is too complex. Extracting the action row reduces cognitive load for each sub-phase.
**How:** Identify the action button section (conditionals for different offer states). Extract into private widget.
**Result:** Main card body is simpler. Action row is isolated and testable.

- [ ] (`@Architect`) In `lib/features/tasks/view/widgets/dashboard_offer_card.dart` (528 lines):
  - Sub-step 8.2.1: Identify the section that renders conditional action buttons (likely the bottom section with 10+ `if/else` branches).
  - Sub-step 8.2.2: Extract into `class _OfferActionRow extends StatelessWidget`.
  - Sub-step 8.2.3: Pass required state as parameters: offer status, callbacks for each action.
  - Sub-step 8.2.4: Ensure each button has loading state (spinner replaces text when action in progress).
- [ ] (`@Sentinel`) Verify extracted widget renders identically to before. Verify `flutter analyze` clean.

### 8.3 DashboardOfferCard — Semantic Tokens
**Primary Agent(s):** `@Pixel`
**Goal:** Replace all hardcoded colors and shadows with design system tokens.
**Why:** Consistent with the rest of the redesign.
**How:** Same token replacement pattern as other cards.
**Result:** Token-based styling throughout.

- [ ] (`@Pixel` | Skill: `normalize`) In `lib/features/tasks/view/widgets/dashboard_offer_card.dart`:
  - Sub-step 8.3.1: Replace hardcoded status header colors with semantic tokens.
  - Sub-step 8.3.2: Replace hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 8.3.3: Replace hardcoded border radius with `AppDimens` values.
  - Sub-step 8.3.4: Replace `InkWell` with `ScaleButton` on the main card.
  - Sub-step 8.3.5: Deadline countdown: use `Color.lerp` from `colorScheme.success` → `colorScheme.warning` → `colorScheme.danger` based on time remaining.
- [ ] (`@Sentinel`) Verify all status states render correctly with semantic colors.

### 8.4 DashboardOfferCard — Deadline Animation
**Primary Agent(s):** `@Pixel`
**Goal:** Smooth pulse animation on critical deadline (< 2h remaining).
**Why:** Current pulse starts/stops abruptly. Smooth animation draws attention without jarring.
**How:** `AnimationController` with proper ease-in-out curve for opacity pulse.
**Result:** Smooth attention-drawing pulse on urgent offers.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/features/tasks/view/widgets/dashboard_offer_card.dart`:
  - Sub-step 8.4.1: Add pulse `AnimationController` (2 second cycle, repeat, `AppMotion.curveSymmetric` if available or `Curves.easeInOut`).
  - Sub-step 8.4.2: Pulse only when deadline < 2 hours. Stop pulse when deadline is not critical.
  - Sub-step 8.4.3: Pulse affects opacity of deadline text/icon (0.6 → 1.0 → 0.6).
  - Sub-step 8.4.4: Add `dispose()` for controller cleanup.
- [ ] (`@Sentinel`) Verify pulse starts at < 2h. Verify it stops when not critical. Verify dispose.

### 8.5 DashboardCountersGrid — Animated Count-Up
**Primary Agent(s):** `@Pixel`
**Goal:** Numbers animate from 0 to actual value on first load. Skeleton loading state.
**Why:** Static numbers feel dead. Animated count-up rewards the user's attention and makes the dashboard feel alive.
**How:** Custom `_AnimatedCount` widget with `Tween<int>` animation.
**Result:** Delightful count-up on dashboard load.

- [ ] (`@Pixel` | Skill: `animate`) In `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` (152 lines):
  - Sub-step 8.5.1: Create private `_AnimatedCount` widget: takes `int endValue`, uses `IntTween` with `AnimationController` (duration: `AppMotion.emphasis` 500ms, curve: `AppMotion.curveDecel`).
  - Sub-step 8.5.2: Replace static `Text('$count')` with `_AnimatedCount(endValue: count)`.
  - Sub-step 8.5.3: Trigger animation when widget first builds (via `addPostFrameCallback`).
  - Sub-step 8.5.4: If count is 0: show with `colorScheme.textSecondary` (muted).
- [ ] (`@Pixel` | Skill: `delight`) Loading state:
  - Sub-step 8.5.5: When data is null/loading: show `SkeletonCard` for each counter tile.
  - Sub-step 8.5.6: Add loading parameter to widget.
- [ ] (`@Pixel` | Skill: `normalize`) Token replacement:
  - Sub-step 8.5.7: Replace hardcoded `BoxShadow` with `AppDecorations.elevation(1)`.
  - Sub-step 8.5.8: Replace hardcoded icon sizes with `AppDimens` values.
  - Sub-step 8.5.9: Add `ScaleButton` wrapping each counter tile (tap to navigate).
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics` labels: "Active tasks: [count]", "Pending bookings: [count]", etc.
- [ ] (`@Sentinel`) Verify count-up animates on first load. Verify skeleton loading. Verify tap navigates.
- **GATE CHECK:** All 3 dashboard cards use semantic tokens, ScaleButton, elevation scale. DashboardOfferCard has extracted action row and smooth deadline pulse. CountersGrid has animated count-up and skeleton loading. `flutter analyze` clean.

---

## Phase 9: Widget Tests

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Write widget tests for auth screens and card widgets following Phase 1 test patterns.
**Why:** Only 1 widget test exists for auth (`login_screen_test.dart`). Card widgets have zero tests. Layout changes (header removal, Transform removal) need regression coverage.
**How:** Create ~8 test files following existing test patterns in `test/widget/`.
**Result:** Regression safety for all Phase 2 changes.

### 9.1 Auth Widget Tests
**Primary Agent(s):** `@Sentinel`
**Goal:** Test auth screen rendering, validation, and animation triggers.
**Why:** Auth screens are the first user touchpoint. Regressions here are immediately visible.
**How:** Widget tests with `pumpWidget` + `pumpAndSettle`.
**Result:** Test files for auth screens.

- [ ] (`@Sentinel`) Update `test/widget/auth/login_screen_test.dart`:
  - Sub-step 9.1.1: Add test: stagger animation completes (pump 600ms, verify all fields visible).
  - Sub-step 9.1.2: Add test: inline error appears on invalid submit (enter invalid email, tap submit, verify error text visible).
  - Sub-step 9.1.3: Add test: form shake triggers on invalid submit.
  - Sub-step 9.1.4: Add test: validation icon appears on valid email input.
- [ ] (`@Sentinel`) Create `test/widget/auth/signup_screen_test.dart`:
  - Sub-step 9.1.5: Test: password strength bar appears and updates.
  - Sub-step 9.1.6: Test: confirm password mismatch shows indicator.
  - Sub-step 9.1.7: Test: stagger animation completes.

### 9.2 Card Widget Tests
**Primary Agent(s):** `@Sentinel`
**Goal:** Test card rendering with various data states.
**Why:** Card layout changes (header removal, Transform removal) need regression coverage.
**How:** Widget tests verifying card renders with expected structure.
**Result:** Test files for card widgets.

- [ ] (`@Sentinel`) Create `test/widget/cards/task_card_test.dart`:
  - Sub-step 9.2.1: Test: renders without 120px header (verify no Container with height 120).
  - Sub-step 9.2.2: Test: uses ScaleButton (find ScaleButton in widget tree).
  - Sub-step 9.2.3: Test: displays title, price, status badge.
- [ ] (`@Sentinel`) Create `test/widget/cards/booking_task_card_test.dart`:
  - Sub-step 9.2.4: Test: no Transform.translate in widget tree.
  - Sub-step 9.2.5: Test: renders avatar at 36px+ size.
  - Sub-step 9.2.6: Test: uses ScaleButton.
- [ ] (`@Sentinel`) Create `test/widget/cards/dashboard_counters_grid_test.dart`:
  - Sub-step 9.2.7: Test: shows skeleton when loading.
  - Sub-step 9.2.8: Test: displays correct count values after animation settles.
- [ ] (`@Sentinel`) Run `flutter test`. Confirm all new tests pass.
- **GATE CHECK:** ~8 test files created. All tests pass. `flutter test` green.

---

## Phase 10: Visual QA & Polish

**Primary Agent(s):** `@Sentinel`, `@Pixel`
**Goal:** Visual audit of all changed screens in both light and dark mode.
**Why:** Token replacements and layout changes may have subtle visual regressions. Dark mode shadows and colors need verification.
**How:** Manual inspection on device/emulator. Check each screen in both themes.
**Result:** All screens polished in both modes.

### 10.1 Light Mode Audit
**Primary Agent(s):** `@Sentinel`
**Goal:** Verify all changes look correct in light mode.
**Why:** Light mode is the secondary theme but still needs to look good.
**How:** Navigate through every changed screen.
**Result:** Light mode audit complete.

- [ ] (`@Sentinel` | Skill: `audit`) Check each screen in light mode:
  - Sub-step 10.1.1: Login — stagger animation, inline errors, validation icons.
  - Sub-step 10.1.2: Signup — password strength bar, stagger, inline errors.
  - Sub-step 10.1.3: All auth supporting screens — icons, messaging, CTAs.
  - Sub-step 10.1.4: Main navigation — tab transitions, FAB entrance, FAB scroll behavior.
  - Sub-step 10.1.5: Task cards — ScaleButton feedback, layout (no 120px header), semantic colors.
  - Sub-step 10.1.6: Booking cards — hierarchy, price formatting, Message button.
  - Sub-step 10.1.7: Dashboard cards — counter animation, offer card states, work item avatar.

### 10.2 Dark Mode Audit
**Primary Agent(s):** `@Sentinel`
**Goal:** Verify all changes look correct in dark mode (primary theme).
**Why:** Dark mode is the default. Shadows may need lighter alpha. Text contrast must be 4.5:1+.
**How:** Same screens as light mode, in dark theme.
**Result:** Dark mode audit complete.

- [ ] (`@Sentinel` | Skill: `audit`) Check each screen in dark mode:
  - Sub-step 10.2.1: All screens from 10.1 in dark mode.
  - Sub-step 10.2.2: Verify card shadows are visible (not invisible on dark backgrounds).
  - Sub-step 10.2.3: Verify semantic colors have sufficient contrast on dark surfaces.
  - Sub-step 10.2.4: Verify text contrast >= 4.5:1 for body, >= 3:1 for headings.
  - Sub-step 10.2.5: Verify password strength bar colors are distinguishable in dark mode.

### 10.3 Fix Issues
**Primary Agent(s):** `@Pixel`
**Goal:** Fix any issues found in audit.
**Why:** Visual polish is the whole point of this phase.
**How:** Address each issue individually.
**Result:** All issues resolved.

- [ ] (`@Pixel` | Skill: `polish`) Fix any contrast, alignment, or animation timing issues found.
- [ ] (`@Sentinel`) Re-verify fixes.
- **GATE CHECK:** All screens pass visual audit in both themes. No contrast violations. No overflow. `flutter analyze` clean.

---

## Phase 11: Documentation Sync

**Primary Agent(s):** `@SlineDocs`
**Goal:** Update documentation to reflect Phase 2 changes.
**Why:** Documentation must stay aligned with implementation.
**How:** Update relevant docs.
**Result:** Docs current.

### 11.1 Update Documentation
- [ ] (`@SlineDocs`) Update session log with all execution events.
- [ ] (`@SlineDocs`) Update `theme_dashboard.dart` if new tokens or patterns were introduced.
- [ ] (`@SlineDocs`) Note any drift from Master Plan in session log (e.g., no `package:animations`, `SlinePageRoute` instead of `OpenContainer`).
- [ ] (`@SlineDocs`) Write `.TODO/DOCS_SYNC_2026-04-08_Phase2_AppShellAuthCards.md`.
- **GATE CHECK:** Session log complete. Documentation aligned. Docs sync file written.

---

## 7) Acceptance Criteria (MANDATORY)

- [ ] `SlinePageRoute` factory exists with 3 transition types (`forwardPush`, `modalSheet`, `fade`).
- [ ] `main.dart` uses `onGenerateRoute` (not `routes:` map).
- [ ] Main navigation has directional tab transitions, FAB spring entrance, FAB scroll-aware hide/show.
- [ ] Login and Signup have stagger entrance animations (total time ≤ 600ms).
- [ ] Login and Signup have inline form errors (no SnackBars for validation).
- [ ] Login has per-field validation icons.
- [ ] Signup has password strength indicator with color transitions.
- [ ] All 5 supporting auth screens have animated icons and clear CTAs.
- [ ] TaskCard has no 120px header. Uses ScaleButton + semantic tokens + elevation scale.
- [ ] TenderTaskCard has zero hardcoded `fontSize` values. Uses AppTypography throughout.
- [ ] BookingTaskCard has no `Transform.translate`. Uses proper layout.
- [ ] BookingCard uses PriceFormatter (no hardcoded `$`). Uses semantic StatusBadge.
- [ ] DashboardBookingCard Message button fires callback (not TODO).
- [ ] WorkItemCard avatar is 36px (not 24px).
- [ ] DashboardOfferCard has extracted `_OfferActionRow`. Deadline pulse is smooth.
- [ ] DashboardCountersGrid has animated count-up and skeleton loading.
- [ ] All 18 changed files have zero hardcoded `BoxShadow`, zero hardcoded status `Color(0x`, zero `print()`.
- [ ] All interactive elements have `Semantics` wrappers.
- [ ] ~8 widget test files exist and pass.
- [ ] `flutter analyze` returns 0 errors.
- [ ] `flutter test` passes.
- [ ] Visual audit passes in both light and dark mode.

## 8) Rollback Plan

- **Route migration:** If `onGenerateRoute` causes issues, revert `main.dart` to `routes:` map. Apply transitions per-push-site as interim.
- **Auth stagger animations:** If animation causes perceived slowness, reduce total stagger time or remove stagger entirely (single fade-in).
- **Card layout changes (header removal, Transform removal):** If callers break, revert individual card files independently. Each card change is isolated.
- **DashboardOfferCard extraction:** If `_OfferActionRow` extraction introduces state bugs, inline the widget back temporarily.
- **All Phase 2 changes are additive/UI-only:** No database or backend changes. Full git revert is safe for any file.

## 9) References (From Scan)

### Docs Scanned
- `.cursor/Agents/Plan_Critic.md`
- `.cursor/Agents/Sline_Planner.md`
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md`
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md`
- `.impeccable.md`

### Code Paths Scanned
- `lib/app/main_navigation_screen.dart` (186 lines)
- `lib/core/utils/custom_route_transitions.dart` (117 lines)
- `lib/core/theme/app_motion.dart` (117 lines)
- `lib/core/theme/app_states.dart` (114 lines)
- `lib/core/widgets/scale_button.dart` (129 lines)
- `lib/features/auth/view/` — 7 files, 1,204 lines total
- `lib/features/tasks/view/widgets/task_card.dart` (334 lines)
- `lib/features/tasks/view/widgets/tender_task_card.dart` (305 lines)
- `lib/features/tasks/view/widgets/booking_task_card.dart` (477 lines)
- `lib/features/tasks/view/widgets/dashboard_offer_card.dart` (528 lines)
- `lib/features/booking/view/widgets/booking_card.dart` (222 lines)
- `lib/features/booking/view/widgets/dashboard_booking_card.dart` (223 lines)
- `lib/features/dashboard/view/widgets/work_item_card.dart` (298 lines)
- `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` (152 lines)
- `lib/main.dart` (598 lines)

### Existing Tests
- `test/widget/auth/login_screen_test.dart`
- `test/unit/auth/auth_session_view_model_test.dart`
- `test/unit/auth/auth_form_view_model_test.dart`
- `test/unit/auth/auth_repository_test.dart`

### Related .TODO/ Artifacts
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md`
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md`
- `.TODO/DOCS_SYNC_2026-04-07_CoreWidgetRedesign.md`

## 10) Scan Evidence (Appendix)

### Line Counts
| File | Lines |
|------|-------|
| `main_navigation_screen.dart` | 186 |
| `custom_route_transitions.dart` | 117 |
| `login_screen.dart` | 321 |
| `signup_screen.dart` | 371 |
| `forgot_password_screen.dart` | 179 |
| `reset_password_update_screen.dart` | 165 |
| `maintenance_screen.dart` | 46 |
| `update_required_screen.dart` | 44 |
| `account_restricted_screen.dart` | 78 |
| `task_card.dart` | 334 |
| `tender_task_card.dart` | 305 |
| `booking_task_card.dart` | 477 |
| `booking_card.dart` | 222 |
| `dashboard_booking_card.dart` | 223 |
| `work_item_card.dart` | 298 |
| `dashboard_offer_card.dart` | 528 |
| `dashboard_counters_grid.dart` | 152 |
| `main.dart` | 598 |
| **Total** | **4,644** |

### Phase 0/1 Deliverables Confirmed
| Token/Component | File | Status |
|----------------|------|--------|
| `AppMotion` (durations, curves, scales) | `app_motion.dart` (117 lines) | ✅ Exists |
| `AppInteractionStates` (8-state model) | `app_states.dart` (114 lines) | ✅ Exists |
| `AppDecorations.elevation()` | `app_decorations.dart` | ✅ Exists |
| Semantic colors (success/warning/info/danger) | `app_colors.dart` | ✅ Exists |
| Component themes (Card, Dialog, etc.) | `app_theme.dart` | ✅ Exists |
| `ScaleButton` (spring + haptics) | `scale_button.dart` (129 lines) | ✅ Exists |
| `.impeccable.md` | Project root | ✅ Exists |
| `package:animations` | `pubspec.yaml` | ❌ NOT available |

### Route Infrastructure
- Current: `routes:` named map in `main.dart` (line ~527)
- No `onGenerateRoute` currently
- `custom_route_transitions.dart`: only `SlideUpRoute` and `FadeRoute`
- No `SlinePageRoute` factory

### Auth Screen Patterns
- Login and Signup: likely use SnackBar for errors (grep needed during execution)
- No stagger animation infrastructure on any auth screen
- No password strength widget exists in codebase

END.
