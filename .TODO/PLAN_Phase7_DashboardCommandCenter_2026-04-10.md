# Plan: Phase 7 — Dashboard Command Center Redesign

## 1) Goal
- **Goal:** Transform the Dashboard from a functional but basic tabbed view into a premium command center with polished tab styling, animated settings sheet, enhanced overview tab, priority-driven next actions, timeline activity feed, and consistent token normalization across all 5 tabs.
- **Why:** The Dashboard is the user's primary workspace after login. Phases 0-6 established the design system, core widgets, auth screens, home/discovery, and chat. The Dashboard still uses default Material TabBar, AlertDialog for settings, `CircularProgressIndicator` in Inbox, hardcoded icon sizes in empty states, and lacks visual cohesion with the redesigned screens. This is the highest-impact screen remaining.
- **Result:** All 11 dashboard view files redesigned with design system tokens, pill-style tab indicator, bottom sheet settings with animated role switcher, enhanced overview greeting/layout, priority-colored next actions with stagger entrance, timeline activity feed with time grouping, skeleton loading in Inbox tab, and consistent empty states across all tabs. View-layer only — no ViewModel/Service/Repository changes.
- **Session Log:** `docs/LOG/SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md`

## 2) Scope

### In-Scope
- Dashboard screen TabBar redesign (pill-style indicator, custom styling)
- Settings modal migration from AlertDialog → bottom sheet with animated role switcher
- Overview tab layout polish (greeting, section headers, spacing rhythm)
- Next actions list: priority left-bar, stagger entrance, enhanced empty state, skeleton loading
- Activity feed: time grouping headers, expand/collapse animation, refined empty state
- Dashboard counters grid: token normalization, spacing refinement
- Work item card: minor token normalization (remaining hardcoded values)
- Work tab: token normalization for sub-tab bar, empty states, spacing
- Bookings tab: token normalization (already well-done in Phase 5, minor polish)
- Inbox tab: skeleton loading (currently `CircularProgressIndicator`), empty state polish, token normalization
- Wallet tab: minimal (delegates to WalletSharedBody, already token-normalized)
- Wallet snapshot card: token normalization for spacing and typography
- Cross-feature cards (DashboardBookingCard, DashboardOfferCard): token normalization pass

### Out-of-Scope
- ViewModel, Service, Repository, or Model changes (View-layer only)
- Supabase/backend changes
- Adding new dependencies to pubspec.yaml
- Wallet redesign (Phase 12 in master plan)
- Full booking card redesign (Phase 8 in master plan)
- New ViewModel state or data fields
- Tab content scroll-to-top on re-tap (requires ViewModel coordination — separate task)
- FAB hide-on-scroll behavior (requires ScrollController wiring through tabs — separate task)

## 3) Files To Read & Modify (Explicit list for Executor)

### Primary Files (Modify)
| File | Lines | Action |
|------|-------|--------|
| `lib/features/dashboard/view/dashboard_screen.dart` | 357 | TabBar redesign, settings → bottom sheet |
| `lib/features/dashboard/view/tabs/overview_tab.dart` | 104 | Layout polish, greeting, section headers |
| `lib/features/dashboard/view/widgets/next_actions_list.dart` | 192 | Priority bar, stagger entrance, skeleton, empty state |
| `lib/features/dashboard/view/widgets/activity_feed_preview.dart` | 383 | Time grouping, expand animation, polish |
| `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` | 279 | Token normalization |
| `lib/features/dashboard/view/widgets/work_item_card.dart` | 310 | Token normalization |
| `lib/features/dashboard/view/tabs/work_tab.dart` | 493 | Sub-tab bar styling, empty state polish |
| `lib/features/dashboard/view/tabs/bookings_tab.dart` | 236 | Minor token normalization |
| `lib/features/dashboard/view/tabs/inbox_tab.dart` | 182 | Skeleton loading, empty state polish |
| `lib/features/dashboard/view/tabs/wallet_tab.dart` | 15 | Minor if needed |

### Cross-Feature Files (Token Normalization Pass)
| File | Lines | Action |
|------|-------|--------|
| `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | 101 | AppLayout token normalization |
| `lib/features/booking/view/widgets/dashboard_booking_card.dart` | 250 | Token normalization pass |
| `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | 626 | Token normalization pass |

### Read-Only References
| File | Purpose |
|------|---------|
| `lib/core/theme/app_motion.dart` (122 lines) | Animation tokens |
| `lib/core/theme/app_layout.dart` (202 lines) | Layout tokens |
| `lib/core/theme/app_states.dart` (114 lines) | Interaction states |
| `lib/core/theme/app_decorations.dart` (113 lines) | Elevation helper |
| `lib/core/theme/app_dimens.dart` (65 lines) | Spacing tokens |
| `lib/core/theme/app_colors.dart` (440 lines) | Semantic colors |
| `lib/core/theme/app_typography.dart` (143 lines) | Typography tokens |
| `lib/core/theme/app_theme.dart` (305 lines) | Theme extension |
| `lib/core/widgets/app_card.dart` | Card widget |
| `lib/core/widgets/skeleton_loader.dart` | Skeleton loading |
| `lib/core/widgets/signed_avatar.dart` | Avatar widget |
| `lib/core/widgets/status_badge.dart` | Status badge |
| `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (530 lines) | VM contract reference |

## 4) System Impact Map
- **UI:** 13 view/widget files modified. Visual changes: new tab indicator style, bottom sheet settings, priority bars on next actions, time-grouped activity, stagger entrances, skeleton loading in inbox. All changes are visual refinements with no behavioral impact.
- **MVVM / App Logic:** None. View-layer only. All ViewModel contracts remain unchanged.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** None. Existing AppLogger calls preserved.
- **Compatibility & Migration:** None. No breaking changes.
- **Contracts:** None. ViewModel → View contract unchanged.

## 5) Agent Map
- **Phase 0:** `@SlinePlanner`, `@Sentinel` — Preconditions & gates
- **Phase 1:** `@Pixel`, `@Sentinel` — Dashboard screen TabBar + settings redesign
- **Phase 2:** `@Pixel`, `@Sentinel` — Overview tab layout polish
- **Phase 3:** `@Pixel`, `@Sentinel` — Next actions list redesign
- **Phase 4:** `@Pixel`, `@Sentinel` — Activity feed enhancement
- **Phase 5:** `@Pixel`, `@Sentinel` — Dashboard counters + work item card normalization
- **Phase 6:** `@Pixel`, `@Sentinel` — Work tab styling
- **Phase 7:** `@Pixel`, `@Sentinel` — Bookings tab + Inbox tab polish
- **Phase 8:** `@Pixel`, `@Sentinel` — Cross-feature card normalization (wallet snapshot, booking card, offer card)
- **Phase 9:** `@Sentinel`, `@CodeGuard` — QA + verification
- **Phase 10:** `@SlineDocs` — Documentation sync

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

### 0.1 Spec Lock

- [x] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [x] (`@Architect`) Confirm touched modules: `lib/features/dashboard/view/` (10 files), 3 cross-feature widget files.
- [x] (`@SlineDocs`) Confirm session log path: `docs/LOG/SESSION_PLAN_Phase7_DashboardCommandCenter_2026-04-10.md`.
- **GATE CHECK:** Scope is limited to View-layer files. No ViewModel, Service, Repository, or backend changes.

### 0.2 Codebase Discovery Scan (MANDATORY)

- [ ] (`@Pixel`) Before implementation, perform codebase discovery scan:
  - Step 1: `grep -r "dashboard" lib/ --include="*.dart" -l` — find ALL dashboard-related files.
  - Step 2: `grep -r "DashboardScreen\|DashboardContent\|OverviewTab\|WorkTab\|BookingsTab\|InboxTab\|WalletTab" lib/ --include="*.dart" -l` — find all importers/callers.
  - Step 3: `grep -r "DashboardCountersGrid\|NextActionsList\|ActivityFeedPreview\|WorkItemCard" lib/ --include="*.dart" -l` — find all widget usage sites.
  - Step 4: Compare results against the plan's file list. Report any DISCOVERED FILES.
  - Step 5: Report scope to user before writing code.
- [ ] (`@Sentinel`) Confirm discovery scan completed and findings documented in session log.
- **GATE CHECK:** Discovery scan complete. No missing files.

### 0.3 Screenshot Workflow

- [ ] (`@Pixel`) Request screenshots from user:
  - Screenshot 1: Dashboard Overview tab (default state, light + dark mode)
  - Screenshot 2: Dashboard Work tab (Active sub-tab with items)
  - Screenshot 3: Dashboard Bookings tab (with upcoming + past)
  - Screenshot 4: Dashboard Inbox tab (with offers)
  - Screenshot 5: Dashboard Settings dialog (current AlertDialog)
  - Screenshot 6: Dashboard Overview tab empty state
- [x] (`@Sentinel`) Screenshots received: 23 screenshots in `.TODO/phase7/jpg/` covering all 5 tabs, settings dialog, light + dark mode, web view, detail screens, and empty states.
- **GATE CHECK:** ✅ Visual context established for all 5 tabs.

---

## Phase 0.4: Screenshot Observations & REDESIGN Direction

> **23 screenshots reviewed.** These are not polish notes — they are **REDESIGN observations**.
> Every UI must use: **Layer 1** (AppColors/colorScheme, AppTypography, AppMotion, AppDecorations, AppStates) + **Layer 2** (AppLayout, AppDimens) tokens. Zero hardcoded values. Every skill tag below maps to `.cursor/skills/`.

### What Every UI Must Use (Answer to User's Question)

Every view/widget in SLine must consume these design system layers:

| Layer | What It Provides | Token Files | Rule |
|-------|-----------------|-------------|------|
| **Layer 1 — Theme** | Colors, typography, motion, elevation, interaction states | `app_colors.dart`, `app_typography.dart`, `app_motion.dart`, `app_decorations.dart`, `app_states.dart`, `app_theme.dart` | NEVER hardcode a color, font size, duration, or shadow |
| **Layer 2 — Layout** | Spacing, sizes, proportions, card dimensions | `app_layout.dart`, `app_dimens.dart` | NEVER hardcode padding, margin, icon size, avatar size, or component height |
| **Layer 3 — Components** | Shared widgets that consume Layer 1+2 | `app_card.dart`, `skeleton_loader.dart`, `signed_avatar.dart`, `status_badge.dart`, `app_button.dart` | Prefer shared widgets over custom implementations |

**Additional mandatory patterns:**
- `AppInteractionStates.hapticTap()` on all primary tap targets (Skill: `delight`)
- `Semantics()` labels on all interactive/informational elements (Skill: `harden`)
- `AppMotion.*` curves + durations for all animations (Skill: `animate`)
- `AppDecorations.elevation()` for all shadow depth (Skill: `arrange`)
- Solid surfaces only — NO glass, NO `BackdropFilter`, NO semi-transparent gradients (`.impeccable.md` NO GLASS POLICY)
- `SkeletonLoader` for all loading states — NO `CircularProgressIndicator` (Skill: `extract`)

### Screenshot-by-Screenshot Observations

#### SS-1: Overview Tab — Dark Mode (04.17.05)
- **TabBar**: Default Material underline indicator — looks stock/generic. **REDESIGN**: Pill-style segmented control (Skill: `normalize`, `arrange`)
- **Greeting**: "Hello, there!" is generic and dead. **REDESIGN**: Time-aware greeting with user's name, warmer subtitle (Skill: `typeset`, `delight`)
- **Wallet Snapshot**: Decent card, gradient feels ok but borders are thin. Token pass needed on `AppColors.teal/gold` → semantic (Skill: `colorize`)
- **Counters Grid**: 2x2 grid looks functional but static. Icons are fine. Colors use `AppColors.*` — **REDESIGN**: Semantic color migration + subtle count-up entrance (Skill: `colorize`, `animate`)
- **Next Actions**: "No actions pending." — bare text, no icon, no visual weight. **REDESIGN**: Illustrated empty state with "All caught up!" messaging (Skill: `delight`)
- **"Recent Activity"**: Section header with "See All" action. Good pattern — refine spacing rhythm (Skill: `arrange`)

#### SS-2: Settings AlertDialog (04.17.21)
- **Critical REDESIGN**: AlertDialog looks like an error popup, not a settings surface. Dark card inside dark overlay with thin border. Freelancer/Client pills work but the container feels unfinished.
- **REDESIGN**: Bottom sheet with drag handle, proper section headers, more spacious layout (Skill: `arrange`, `normalize`)

#### SS-3: TabBar Close-Up (04.17.29)
- Default Material icon+label tabs with teal underline. Functional but generic — looks like a Material sample app.
- **REDESIGN**: Pill indicator, `captionBold` for selected labels, `caption` for unselected. Semantic coloring (Skill: `normalize`, `typeset`)

#### SS-4: Activity Feed Scrolled (04.18.07)
- Timeline dots with connecting lines — good Phase 5 foundation. "4h ago" timestamps.
- **Missing**: No time grouping. All items in flat list with no visual breaks.
- **REDESIGN**: Add "Today" / "Yesterday" / "Earlier" group headers. AnimatedSize for expand/collapse. (Skill: `arrange`, `animate`)

#### SS-5: Bookings Tab (04.18.25)
- Well-done from Phase 5. Status badges (DELIVERED, REQUEST PENDING, ACTIVE, COMPLETED) have correct colors.
- "Upcoming" header with proper hierarchy. Cards have good structure.
- **Minor**: Token audit pass — verify all colors are semantic, no `AppColors.*` remnants (Skill: `audit`)

#### SS-6: Work Tab — Active (04.18.36)
- "My Work" header, "Track all your jobs and bookings." subtitle. Good hierarchy.
- Active(4)/Done(16)/Cancelled sub-tab bar with pill indicator. Already styled well.
- Work item cards: colored headers (teal for BOOKING, pinkish for CUSTOM OFFER). "Awaiting Client Review" badge. Avatar + name.
- **Issues**: Header colors use `AppColors.*` — **REDESIGN**: Semantic migration (Skill: `colorize`)
- **FAB**: Teal + icon overlaps "See All" button — separate concern (out of scope)

#### SS-7: Work Tab — Active Detail (04.18.40)
- Same as SS-6 but shows the full card with "DELIVERED" status. Cards have good density.
- Work item card avatar is small, hardcoded `radius: 18`. **REDESIGN**: Use `AppLayout.avatarSmall / 2` (Skill: `normalize`)

#### SS-8: Work Tab — Done (04.18.57)
- Done(16) sub-tab. Cards showing COMPLETED status. CUSTOM OFFER / BOOKING / TASK type badges with due dates.
- Same color issues as Active tab — `AppColors.*` throughout.
- **REDESIGN**: Full semantic color migration (Skill: `colorize`)

#### SS-9: Work Tab — Cancelled Empty (04.19.02)
- Empty state with crossed-out briefcase icon, "No cancelled work." text.
- Icon and text are properly sized and centered. Good pattern.
- **Minor**: Verify token usage — `AppLayout.iconFeature`, `AppTypography.h5` (Skill: `audit`)

#### SS-10: Wallet Tab — Top (04.19.14)
- "WALLET" pill badge. "Total funds: 3536K IQD". Balance composition bar (gradient). Available/Pending/Held breakdown.
- Delegates to `WalletSharedBody` — minimal changes needed.
- **Token pass**: `AppColors.teal/gold` in wallet snapshot card (Skill: `normalize`)

#### SS-11: Wallet Tab — Middle (04.19.18)
- "Spent: 754K IQD", "Fees: 130K IQD" cards with icons. Withdrawal section with "Coming Soon" badge.
- Ready/Pending/Held breakdown repeated. "Request withdrawal" button.
- **Out of scope**: Wallet redesign is Phase 12. Only token-normalize the snapshot card.

#### SS-12: Wallet Tab — Activity Timeline (04.19.25)
- "Recent activity" section with timeline. "Payment from direct offer +225K IQD", "Payment from booking +135K IQD", "Tender payment -49K IQD".
- Has "Earlier" group header — wallet already has time grouping! Good reference pattern.
- Timestamp format "2026-04-05 16:39" — looks ok.

#### SS-13: Inbox Tab — Offers (04.19.30)
- OFFER cards with "UNAVAILABLE" status badges. "My Offer" title, date, price, duration.
- Cards are dark with teal left accent. Good density.
- **Missing**: No skeleton loading — uses `CircularProgressIndicator`. **REDESIGN**: Skeleton loading (Skill: `extract`)
- **Colors**: Status badges have `Colors.red` for error SnackBars. **REDESIGN**: `colorScheme.danger` (Skill: `colorize`)

#### SS-14: Direct Offer Detail — Pending Payment (04.19.51)
- Detail screen (not dashboard tab). Title, description, price, delivery, status. "Open chat" button.
- **Out of scope** — this is a feature detail screen, not a dashboard widget.

#### SS-15: Direct Offer Detail — Active (04.19.56)
- Active offer with "Submit work" button, "Report Issue" link.
- **Out of scope** — feature detail screen.

#### SS-16: Booking Detail — Active (04.20.03)
- "Booking" screen with Overview/Extensions/Contract tabs. Booking Details card with avatar, due date, delivery days, payment status.
- Bottom bar with Extend/Message/Report actions + "Submit Work" button.
- **Out of scope** — feature detail screen, not dashboard widget.

#### SS-17: Booking Detail — Delivered (04.20.09)
- Same as SS-16 but with DELIVERED status and "Waiting for Client Review" bottom bar.
- **Out of scope** — feature detail screen.

#### SS-18: Task Detail — Completed (04.20.18)
- "Task" screen with COMPLETED status. Contract Info card with price and deadline.
- Raw timestamp "2026-04-12 16:33:55.067799Z" displayed — **BUG** (not Phase 7 scope, but note for future: format this timestamp)
- **Out of scope** — feature detail screen.

#### SS-19: Work Tab — Web/Client View (04.20.41)
- **WEB VERSION** (localhost:62460). Work tab as CLIENT role. Different layout:
  - "Book Home Cleaning Service - Session" with "Needs Review" orange badge
  - "In Progress (3)" section header
  - CUSTOM OFFER card with "PENDING PAYMENT" gold status + "Pay & Confirm" teal button
- Shows client-specific content. Cards render differently with `AppColors.*` colors.
- **Important**: Work item cards must work for BOTH roles. Semantic colors must handle both.

#### SS-20: Direct Offer Detail — Web (04.20.46)
- Web version of offer detail. "Cancel offer" + "Pay (QiCard)" buttons.
- **Out of scope** — feature detail screen.

#### SS-21: Work Tab — Light Mode (04.21.00)
- **LIGHT MODE** view of Work tab. Shows the same cards with inverted color scheme.
- CUSTOM OFFER "PENDING PAYMENT" in gold/amber. "ACTIVE" in teal. BOOKING with "ACTIVE" status.
- Sub-tab bar: pill indicator (light olive/gold on "Active"), grey text on "Done(16)" and "Cancelled".
- **Critical observation**: Light mode sub-tab pill color appears to be gold/olive, not primary teal. This may be intentional or a bug. **REDESIGN**: Ensure consistent `colorScheme.primary` for both modes (Skill: `colorize`, `audit`)
- Cards in light mode: white cards with subtle borders. Headers have lighter tint versions of status colors. Looks cleaner than dark mode.

#### SS-22: Bookings Tab — Light Mode (04.21.15)
- Light mode bookings. White cards with status badges (DELIVERED green, REQUEST PENDING gold, ACTIVE teal, COMPLETED green).
- Accept/Decline buttons on REQUEST PENDING card. Good styling.
- Bottom nav has solid white background — clean.
- **Minor**: Verify all badge colors use semantic tokens (Skill: `audit`)

#### SS-23: Overview Tab — Light Mode (04.21.18)
- Light mode overview. "Hello, there!" greeting. Wallet card with light gradient.
- Counter cards: white with subtle shadows. Icons properly colored (teal, gold, etc.).
- "Next Actions: No actions pending." — same bare text issue as dark mode.
- "Recent Activity" section header visible at bottom.
- **Same REDESIGN needs as dark mode** — pill TabBar, time-aware greeting, enhanced empty states, semantic colors.

### Summary of REDESIGN Priorities (Not Polish)

| Priority | Component | Current State | REDESIGN To | Skills |
|----------|-----------|--------------|-------------|--------|
| 🔴 P0 | TabBar | Default Material underline | Pill-style segmented control | `normalize`, `arrange` |
| 🔴 P0 | Settings Modal | AlertDialog popup | Bottom sheet with drag handle | `arrange`, `delight` |
| 🔴 P0 | Next Actions Empty | Bare text "No actions pending." | Illustrated "All caught up!" | `delight`, `typeset` |
| 🔴 P0 | Inbox Loading | CircularProgressIndicator | Skeleton shimmer loading | `extract` |
| 🟡 P1 | Greeting | Static "Hello, there!" | Time-aware + name | `typeset`, `delight` |
| 🟡 P1 | Activity Feed | Flat list | Time-grouped with headers | `arrange`, `animate` |
| 🟡 P1 | Counter Colors | AppColors.gold/teal/etc | colorScheme.warning/primary/etc | `colorize` |
| 🟡 P1 | Work Item Card Colors | AppColors.* hardcoded | colorScheme.* semantic | `colorize` |
| 🟡 P1 | SnackBar Colors | Colors.red/green | colorScheme.danger/success | `colorize` |
| 🟢 P2 | Stagger Entrance | No animation on NextActions | Stagger slide+fade | `animate` |
| 🟢 P2 | Expand/Collapse | Instant toggle | AnimatedSize smooth | `animate` |
| 🟢 P2 | Cross-Feature Cards | AppColors.* remnants | Semantic tokens | `normalize` |
| 🟢 P2 | Light Mode Consistency | Gold sub-tab pill | Primary-consistent | `colorize`, `audit` |

### Light vs Dark Mode Observations

- **Dark mode** (SS-1 through SS-13): Deep backgrounds work well. Cards have subtle teal/dark borders. Main issues are generic TabBar, bare empty states, hardcoded colors.
- **Light mode** (SS-21 through SS-23): Clean white surfaces with proper shadows. Cards look better in light mode. Sub-tab pill color appears gold/olive instead of primary teal — potential inconsistency. Counter grid shadows are softer. Overall more polished than dark.
- **Both modes**: All semantic color migrations must be verified in BOTH modes after implementation. `colorScheme.*` handles this automatically, but visual verification is mandatory.

### Detail Screens Noted (Out of Scope but Flagged)

- SS-14/15: Direct offer detail — has unstyled "Open chat" button and basic layout. Future phase.
- SS-16/17: Booking detail — raw layout with minimal design. Future phase.
- SS-18: Task detail — raw UTC timestamp displayed (BUG: `2026-04-12 16:33:55.067799Z`). Should use `formatUtcToLocal()`.
- SS-19/20: Web views — render acceptably but cards are wider. Cross-platform token usage looks correct.

---

## Phase 1: Dashboard Screen — TabBar & Settings Redesign

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Replace default Material TabBar with pill-style indicator. Migrate settings from AlertDialog to bottom sheet with animated role switcher.
**Why:** The TabBar is the most prominent UI element on the Dashboard. Default underline indicator is inconsistent with the app's premium design language. AlertDialog for settings is jarring — bottom sheets feel more natural on mobile.
**How:** Modify `dashboard_screen.dart` only.
**Result:** Custom pill-style TabBar indicator, bottom sheet settings with animated role switcher segmented control.

> **📸 REDESIGN NOTE (from screenshots SS-2, SS-3, SS-21, SS-23):**
> - TabBar currently looks like a stock Flutter sample app — thin teal underline on dark bg. In light mode (SS-23) it looks slightly better but still generic. This is the single most visible element — pill redesign is non-negotiable.
> - Settings AlertDialog (SS-2) looks like an error confirmation popup, not a settings surface. The thin-bordered dark card floating in a dark overlay feels unfinished and jarring. Bottom sheet will feel native and intentional.
> - Light mode (SS-21) sub-tab pill appears gold/olive colored instead of primary teal. Verify `colorScheme.primary` resolves to same hue in both modes.
> - Skills: `normalize` (token migration), `arrange` (layout structure), `animate` (bottom sheet entrance)

### 1.1 TabBar Pill-Style Indicator (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Replace the current `TabBar` with a custom-styled variant:
  - Sub-step 1.1.1: Replace `indicatorColor: colorScheme.primary` with a `BoxDecoration` indicator using pill shape (`StadiumBorder` or high `borderRadius`).
  - Sub-step 1.1.2: Set indicator background to `colorScheme.primary` with rounded corners (`AppDimens.r20` or similar pill radius).
  - Sub-step 1.1.3: Set `labelColor` to `Theme.of(context).colorScheme.onPrimary` (contrast against pill background).
  - Sub-step 1.1.4: Set `unselectedLabelColor` to `colorScheme.textSecondary`.
  - Sub-step 1.1.5: Add `labelStyle: AppTypography.captionBold` and `unselectedLabelStyle: AppTypography.caption`.
  - Sub-step 1.1.6: Wrap TabBar in a styled container with `colorScheme.inputBackground` background and rounded corners to create a segmented-control feel.
  - Sub-step 1.1.7: Use `indicatorSize: TabBarIndicatorSize.tab` for full-width pill within each tab.
  - Sub-step 1.1.8: Use `dividerColor: Colors.transparent` to remove bottom divider.
  - Sub-step 1.1.9: Keep `isScrollable: true` and `tabAlignment: TabAlignment.center`.
- [ ] (`@Sentinel`) Verify: pill indicator renders correctly on light and dark mode.
- **GATE CHECK:** TabBar has pill-style indicator. `flutter analyze` clean.

### 1.2 Settings Bottom Sheet (`@Pixel` | Skill: `arrange`)

- [ ] (`@Pixel` | Skill: `arrange`) Replace `_showSettings` method:
  - Sub-step 1.2.1: Replace `showDialog` + `AlertDialog` with `showModalBottomSheet`.
  - Sub-step 1.2.2: Set bottom sheet shape to `RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r24)))`.
  - Sub-step 1.2.3: Set `backgroundColor: colorScheme.cardBackground`.
  - Sub-step 1.2.4: Add a drag handle at the top (centered container: 40px wide, 4px tall, rounded, `colorScheme.textTertiary` color).
  - Sub-step 1.2.5: Add title "Dashboard Settings" with `AppTypography.h5` below drag handle.
  - Sub-step 1.2.6: Add "User Role" label with `AppTypography.captionBold` above role switcher.
  - Sub-step 1.2.7: Include the existing `_RoleSwitch` widget.
  - Sub-step 1.2.8: Add `AppLayout.spacingSection` padding between elements.
  - Sub-step 1.2.9: Add bottom padding for safe area: `MediaQuery.of(context).padding.bottom + AppDimens.p16`.
- [ ] (`@Sentinel`) Verify: bottom sheet opens smoothly, role switching works, no overflow.
- **GATE CHECK:** Settings modal is a bottom sheet. Role switching functional.

### 1.2b Test T58 Migration (`@Pixel` | Skill: —)

- [ ] (`@Pixel`) Read `test/widget/dashboard/dashboard_screen_test.dart`. Test T58 currently opens an `AlertDialog` via settings button, then taps role buttons. This WILL BREAK after 1.2.
  - Sub-step 1.2b.1: Update test T58 to handle `showModalBottomSheet` instead of `showDialog`.
  - Sub-step 1.2b.2: After `tester.tap(find.byKey(DashboardScreen.settingsButtonKey))`, use `tester.pumpAndSettle()` to wait for the bottom sheet animation.
  - Sub-step 1.2b.3: Verify `find.byKey(DashboardScreen.clientRoleButtonKey)` still finds the button inside the bottom sheet. If not, adjust the finder.
  - Sub-step 1.2b.4: Run `flutter test test/widget/dashboard/dashboard_screen_test.dart` — all 3 tests (T56, T57, T58) must pass.
- [ ] (`@Sentinel`) Verify: all 3 dashboard_screen_test tests pass.
- **GATE CHECK:** Test T58 migrated. All dashboard screen tests pass.

### 1.3 Role Switcher Polish (`@Pixel` | Skill: `animate`)

- [ ] (`@Pixel` | Skill: `animate`) Polish the existing `_RoleSwitch` and `_RoleButton` widgets:
  - Sub-step 1.3.1: Verify `AnimatedContainer` duration uses `AppMotion.fast` (already does — confirm).
  - Sub-step 1.3.2: Add `curve: AppMotion.curveStandard` to the `AnimatedContainer` if not present.
  - Sub-step 1.3.3: Ensure `AppInteractionStates.hapticTap()` fires on role switch (already present — confirm).
  - Sub-step 1.3.4: Ensure Semantics `selected` state is announced correctly.
- [ ] (`@Sentinel`) Verify: role switcher animation is smooth, haptic feedback fires.
- **GATE CHECK:** Role switcher is polished and accessible.

### 1.4 AppBar Token Normalization (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Normalize remaining AppBar tokens:
  - Sub-step 1.4.1: Verify `PreferredSize` height uses `AppLayout.buttonHeightCompact` (already does — confirm).
  - Sub-step 1.4.2: Verify settings icon uses `colorScheme.textSecondary` (already does — confirm).
  - Sub-step 1.4.3: Add `Semantics(label: 'Dashboard tabs')` wrapping the TabBar.
- [ ] (`@Sentinel`) Verify: `flutter analyze` clean after all Phase 1 changes.
- [ ] (`@Sentinel`) Run `flutter test test/widget/dashboard/dashboard_screen_test.dart` — all 3 tests pass.
- **GATE CHECK:** Phase 1 complete. Dashboard screen TabBar and settings redesigned. All existing tests pass.

---

## Phase 2: Overview Tab — Layout Polish

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish the overview tab layout with improved greeting, consistent section headers, and proper spacing rhythm.
**Why:** The overview tab is the default landing view. It needs to feel polished and well-organized with clear visual hierarchy.
**How:** Modify `overview_tab.dart` only.
**Result:** Enhanced greeting section, consistent section headers, proper spacing rhythm using design tokens.

> **📸 REDESIGN NOTE (from screenshots SS-1, SS-23):**
> - "Hello, there!" greeting (SS-1, SS-23) is impersonal and static — doesn't use the user's name. "Ready to pick up some work?" subtitle is role-specific (freelancer) which is good.
> - Layout vertical rhythm: Wallet card → Counters → Next Actions → Activity — the spacing between these sections is inconsistent. Some gaps are `p16`, others `p20`, others `p24`. Standardize to `AppLayout.spacingScreen` (24px) between major sections.
> - "Recent Activity" section header (SS-1) with "See All" action button — good pattern, just needs token refinement.
> - In light mode (SS-23) the overall hierarchy reads better due to card shadows. Dark mode needs equivalent depth from `AppDecorations.elevation()`.
> - Skills: `typeset` (greeting text hierarchy), `arrange` (spacing rhythm), `delight` (warm time-aware greeting)

### 2.1 Greeting Enhancement (`@Pixel` | Skill: `typeset`)

- [ ] (`@Pixel` | Skill: `typeset`) Enhance the greeting section:
  - Sub-step 2.1.1: Add time-aware greeting logic (local function or inline): "Good morning", "Good afternoon", "Good evening" based on `DateTime.now().hour`.
  - Sub-step 2.1.2: Replace static "Hello, {name}!" with time-aware greeting + name.
  - Sub-step 2.1.3: Keep role-specific subtitle unchanged.
  - Sub-step 2.1.4: Add `Semantics(label: 'Greeting: Good morning, {name}')` wrapping.
  - Sub-step 2.1.5: Add `const SizedBox(height: AppLayout.spacingTight)` between greeting and subtitle (currently none — subtitle is directly below).
- [ ] (`@Sentinel`) Verify: time-aware greeting renders correctly.
- **GATE CHECK:** Greeting is time-aware and accessible.

### 2.2 Section Headers Consistency (`@Pixel` | Skill: `arrange`)

- [ ] (`@Pixel` | Skill: `arrange`) Refine `_SectionHeader` widget:
  - Sub-step 2.2.1: Add `Semantics(header: true, label: '$title section')` wrapping.
  - Sub-step 2.2.2: Add `const EdgeInsets.only(bottom: AppLayout.spacingStandard)` padding below header.
  - Sub-step 2.2.3: Ensure action button (TextButton) uses `AppTypography.captionBold` for consistency.
- [ ] (`@Sentinel`) Verify: headers have Semantics, consistent styling.
- **GATE CHECK:** Section headers are polished and accessible.

### 2.3 Spacing Rhythm (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Normalize spacing in overview tab ListView:
  - Sub-step 2.3.1: Replace `AppDimens.p16` padding with `AppLayout.screenHorizontalMargin` for horizontal and `AppLayout.spacingSection` for top.
  - Sub-step 2.3.2: Standardize vertical gaps between sections: use `AppLayout.spacingScreen` (24) between major sections (wallet → counters → next actions → activity).
  - Sub-step 2.3.3: Replace bottom `SizedBox(height: AppDimens.p100)` with `SizedBox(height: AppLayout.fabBottomOffset)` for semantic clarity.
  - Sub-step 2.3.4: Replace `AppDimens.p20` gaps with appropriate `AppLayout.spacing*` tokens.
  - Sub-step 2.3.5: Verify that content horizontal padding aligns with TabBar label positioning. If `AppLayout.screenHorizontalMargin` (24px) creates a visible step relative to the AppBar TabBar padding (16px default), use `AppDimens.p16` instead and document the reason.
- [ ] (`@Sentinel`) Verify: spacing is consistent, no overflow, bottom padding clears nav bar. Content aligns with tab labels.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Overview tab spacing uses design tokens consistently. No alignment mismatch with tab bar.

---

## Phase 3: Next Actions List — Priority-Driven Redesign

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add priority left-bar color indicators, stagger entrance animation, skeleton loading, and enhanced empty state to the next actions list.
**Why:** Next actions are the primary call-to-action on the dashboard. Currently they render as plain `WorkItemCard` instances with no visual priority indication, no loading state, and a bare "No actions pending." text for empty state.
**How:** Modify `next_actions_list.dart` only.
**Result:** Priority-colored left bar on each action, stagger entrance animation, shimmer skeleton loading, illustrated empty state.

> **📸 REDESIGN NOTE (from screenshots SS-1, SS-19, SS-23):**
> - "Next Actions: No actions pending." (SS-1, SS-23) is the weakest visual element on the entire Overview tab. Bare text with no icon, no card container, no visual weight. It looks like a placeholder that was forgotten. This is a **complete redesign** — not a tweak.
> - In the client web view (SS-19), next actions show "Pay & Confirm" and "Needs Review" cards — these need priority color bars (danger for payment, warning for review) to create visual urgency hierarchy.
> - The `Colors.green` / `Colors.red` SnackBar colors visible in the code are invisible in screenshots but need migration.
> - Skills: `delight` (empty state illustration), `colorize` (priority bars), `animate` (stagger entrance), `extract` (skeleton loading)

### 3.1 Skeleton Loading State (`@Pixel` | Skill: `extract`)

- [ ] (`@Pixel` | Skill: `extract`) Replace `CircularProgressIndicator` with skeleton loading:
  - Sub-step 3.1.1: When `vm.isLoading`, render 3 skeleton placeholder cards.
  - Sub-step 3.1.2: Each skeleton: a `SkeletonLoader` row matching the approximate shape of a `WorkItemCard` (header bar + body area with lines + button area).
  - Sub-step 3.1.3: Use `AppDimens.r16` border radius for consistency with `AppCard`.
  - Sub-step 3.1.4: Use `AppDimens.p12` vertical spacing between skeleton cards.
- [ ] (`@Sentinel`) Verify: skeleton loading renders during data fetch.
- **GATE CHECK:** Skeleton loading replaces spinner.

### 3.2 Priority Left Bar (`@Pixel` | Skill: `colorize`)

- [ ] (`@Pixel` | Skill: `colorize`) Add a colored left border to each action item card based on priority:
  - Sub-step 3.2.1: Wrap each `WorkItemCard` in a `Container` with `BoxDecoration` that includes a left `Border`:
    - `border: Border(left: BorderSide(width: 4, color: priorityColor))`
    - `borderRadius: BorderRadius.circular(AppDimens.r16)` (match AppCard radius)
    - **Do NOT use `IntrinsicHeight`** — the border inherits the container's height naturally, avoiding O(2n) layout cost in scrollable lists.
    - Color mapping based on `item.primaryActionType`:
      - `payEscrow` → `colorScheme.danger` (urgent — money action)
      - `reviewDelivery` → `colorScheme.warning` (needs attention)
      - `submitEvidence` → `colorScheme.info` (action needed)
      - `startWork`, `markCompleted`, `approveClose`, `viewDetails` → `colorScheme.primary` (standard)
  - Sub-step 3.2.2: Add `Semantics(label: 'Priority: ${priorityLabel}')` to the container.
- [ ] (`@Sentinel`) Verify: priority bars render with correct semantic colors.
- **GATE CHECK:** Priority left bar renders correctly.

### 3.3 Stagger Entrance Animation (`@Pixel` | Skill: `animate`)

- [ ] (`@Pixel` | Skill: `animate`) Add stagger entrance to displayed action items:
  - Sub-step 3.3.1: Convert `NextActionsList` from `StatelessWidget` to `StatefulWidget` with `SingleTickerProviderStateMixin`.
  - Sub-step 3.3.2: Create `AnimationController` with `duration: AppMotion.emphasis`.
  - Sub-step 3.3.3: Create cached per-item `SlideTransition` + `FadeTransition` animations (same pattern as `ActivityFeedPreview`).
  - Sub-step 3.3.4: Trigger stagger via `addPostFrameCallback` (same guard pattern as activity feed — prevent mutation during build).
  - Sub-step 3.3.5: Use `AppMotion.staggerMedium` (50ms) delay between items.
  - Sub-step 3.3.6: Dispose `AnimationController` in `dispose()`.
  - Sub-step 3.3.7: Use `AppMotion.curveDecel` for entrance curve.
- [ ] (`@Sentinel`) Verify: items stagger in on first load, no re-trigger on rebuild.
- **GATE CHECK:** Stagger animation works correctly.

### 3.4 Enhanced Empty State (`@Pixel` | Skill: `delight`)

- [ ] (`@Pixel` | Skill: `delight`) Replace bare "No actions pending." text:
  - Sub-step 3.4.1: Add centered column with icon (`Icons.check_circle_outline`, `AppLayout.iconFeature` size, `colorScheme.success` color).
  - Sub-step 3.4.2: Add "All caught up!" text (`AppTypography.h5`, `colorScheme.textSecondary`).
  - Sub-step 3.4.3: Add subtitle "No actions need your attention right now." (`AppTypography.bodySmall`, `colorScheme.textTertiary`).
  - Sub-step 3.4.4: Add `AppLayout.spacingStandard` between icon and text.
  - Sub-step 3.4.5: Wrap in `Semantics(label: 'All caught up. No actions pending.')`.
  - Sub-step 3.4.6: Pad with `AppDimens.p16` all sides.
- [ ] (`@Sentinel`) Verify: empty state renders when `items.isEmpty`.
- **GATE CHECK:** Empty state is polished and accessible.

### 3.5 SnackBar Color Normalization (`@Pixel` | Skill: `colorize`)

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded SnackBar colors in `next_actions_list.dart`:
  - Sub-step 3.5.1: Replace `backgroundColor: Colors.green` (line 171) → `backgroundColor: context.colorScheme.success`.
  - Sub-step 3.5.2: Replace `backgroundColor: Colors.red` (line 180) → `backgroundColor: context.colorScheme.danger`.
  - Sub-step 3.5.3: Note: `colorScheme` must be captured from the outer `context` (not from SnackBar builder context). Use the `context` available in the callback closure.
- [ ] (`@Sentinel`) Verify: No `Colors.red` or `Colors.green` in `next_actions_list.dart`.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Phase 3 complete. Priority bars render. SnackBar colors normalized. Stagger animation plays once. `flutter analyze` clean.

---

## Phase 4: Activity Feed — Enhancement

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add time grouping headers, animated expand/collapse, and refined visual hierarchy to the activity feed.
**Why:** The activity feed already has good foundations from Phase 5 (stagger entrance, skeleton, timeline dots). Adding time groups and expand animation will complete the timeline experience.
**How:** Modify `activity_feed_preview.dart` AND `overview_tab.dart`.
**Result:** Time-grouped headers ("Today", "Yesterday", "Earlier"), animated expand/collapse, refined spacing.

> **📸 REDESIGN NOTE (from screenshots SS-4, SS-12):**
> - Activity feed (SS-4) shows timeline dots with connecting lines — solid Phase 5 foundation. Booking events show "4h ago" relative timestamps. But all items are in a flat list with no visual grouping breaks.
> - The Wallet tab (SS-12) already has an "Earlier" group header in its own activity timeline — use this as the reference pattern. Activity feed should mirror the same grouping approach for consistency.
> - Connecting line height is hardcoded `32px` — extract to token or named constant.
> - The "See All" toggle (SS-1) currently does instant show/hide — wrapping in `AnimatedSize` will make this feel intentional rather than jarring.
> - Skills: `arrange` (time grouping structure), `animate` (expand/collapse), `normalize` (token extraction)

### 4.1 Time Grouping Headers (`@Pixel` | Skill: `arrange`)

- [ ] (`@Pixel` | Skill: `arrange`) Add time grouping logic and section headers:
  - Sub-step 4.1.1: Create a helper function `_getTimeGroupLabel(DateTime createdAt)` that returns "Today", "Yesterday", or "Earlier" based on comparison with `DateTime.now()`.
  - Sub-step 4.1.2: In the `ListView.builder`, track the current group label. When it changes between items, insert a group header widget.
  - Sub-step 4.1.3: Group header: `Text(label, style: AppTypography.captionBold.copyWith(color: colorScheme.textTertiary))` with `AppLayout.spacingSection` top padding and `AppLayout.spacingStandard` bottom padding.
  - Sub-step 4.1.4: Add `Semantics(header: true, label: '$label activities')` to group headers.
  - Sub-step 4.1.5: Adjust `itemCount` and `itemBuilder` to account for inserted group headers (use a pre-computed list of items + headers, or compute inline).
  - Sub-step 4.1.6: Ensure stagger animations are keyed to ACTIVITY ITEMS only (not group header widgets). When building the flat display list:
    - Track a separate `activityItemIndex` that increments only for activity rows (not headers).
    - Use `activityItemIndex` to index into `_slideAnimations` / `_fadeAnimations`.
    - Group headers render without stagger animation (instant, no transition).
    - Test edge cases: 0 items (empty state), 1 item (single group), 3 items all today (one group), 10 items across all groups.
- [ ] (`@Sentinel`) Verify: time groups render correctly with proper labels. No index errors with varying item counts.
- **GATE CHECK:** Time grouping headers display correctly. Stagger animations don't crash with grouped items.

### 4.2 Expand/Collapse Animation (`@Pixel` | Skill: `animate`)

- [ ] (`@Pixel` | Skill: `animate`) Replace instant show/hide with animated expand/collapse:
  - Sub-step 4.2.1: The expand/collapse is driven by `_showAllActivity` toggle in `OverviewTab`. The `ActivityFeedPreview` receives `limit` parameter which already handles this.
  - Sub-step 4.2.2: Wrap the `ActivityFeedPreview` in `overview_tab.dart` with `AnimatedSize(duration: AppMotion.standard, curve: AppMotion.curveStandard)` so the height change is animated.
  - Sub-step 4.2.3: Verify that `AnimatedSize` correctly handles the ListView.builder inside (shrinkWrap: true is already set).
  - Sub-step 4.2.4: Set `clipBehavior: Clip.none` on the `AnimatedSize` widget to prevent content clipping during the height transition. Default `Clip.hardEdge` will clip the last item during expand animation.
  - Sub-step 4.2.5: Manually test: tap "See All" while data is refreshing (pull-to-refresh + toggle simultaneously). Verify no visual artifacts or content cut-off.
- [ ] (`@Sentinel`) Verify: expand/collapse is animated, no layout jumps, no clipping artifacts.
- **GATE CHECK:** Expand/collapse is smooth with no clipping.

### 4.3 Token Refinement (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Normalize any remaining hardcoded values in activity feed:
  - Sub-step 4.3.1: Verify all spacing uses `AppDimens.*` or `AppLayout.*` tokens (scan for raw numeric literals).
  - Sub-step 4.3.2: Verify all icon sizes use `AppDimens.iconSize*` tokens.
  - Sub-step 4.3.3: Verify connecting line height (currently `32`) — consider extracting to a local constant with a comment explaining the value.
  - Sub-step 4.3.4: Verify skeleton loader dimensions use tokens.
- [ ] (`@Sentinel`) Verify: no raw numeric literals remain in activity feed.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Activity feed fully token-normalized. `flutter analyze` clean.

---

## Phase 5: Dashboard Counters Grid + Work Item Card — Token Normalization

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Normalize remaining hardcoded values in the counters grid and work item card.
**Why:** Both widgets already use many tokens but have remaining hardcoded colors (`AppColors.teal`, `AppColors.gold`, `AppColors.mediumGrey`, `AppColors.lightTeal`) instead of semantic colors, and some raw numeric literals.
**How:** Modify `dashboard_counters_grid.dart` and `work_item_card.dart`.
**Result:** Both widgets fully use semantic tokens.

> **📸 REDESIGN NOTE (from screenshots SS-1, SS-6, SS-7, SS-8, SS-19, SS-21, SS-23):**
> - **Counters Grid** (SS-1, SS-23): 2x2 grid with Pending Requests (gold 0), Active Work (teal 3), Messages (light teal 0), New Offers (grey 0). The colors are hardcoded `AppColors.*` — must migrate to `colorScheme.warning/primary/info/textSecondary`. In light mode (SS-23) the counters have nice shadows; in dark mode (SS-1) they rely on borders. Both should use `AppDecorations.elevation()`.
> - **Work Item Cards** (SS-6, SS-7, SS-8, SS-19, SS-21): Colored header bars (teal for BOOKING, pinkish for CUSTOM OFFER/TASK) use `AppColors.*`. Status text (DELIVERED, ACTIVE, PENDING PAYMENT, COMPLETED) also uses hardcoded colors. Avatar `radius: 18` is hardcoded. Light mode (SS-21) shows cards rendering well with white backgrounds — semantic colors will work in both modes.
> - Client view (SS-19) shows same work item cards with "Needs Review" orange badge and "Pay & Confirm" button — confirms cards must handle both roles with same semantic colors.
> - Skills: `colorize` (semantic color migration — 12+ replacements), `normalize` (avatar/icon size tokens)

### 5.1 Dashboard Counters Grid Normalization (`@Pixel` | Skill: `colorize`)

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded status colors with semantic tokens:
  - Sub-step 5.1.1: In freelancer counters:
    - "Pending Requests" → `colorScheme.warning` (replaces `AppColors.gold`)
    - "Active Work" → `colorScheme.primary` (replaces `AppColors.teal`)
    - "Messages" → `colorScheme.info` (replaces `AppColors.lightTeal`)
    - "New Offers" → `colorScheme.textSecondary` (replaces `AppColors.mediumGrey`)
  - Sub-step 5.1.2: In client counters:
    - "Active Work" → `colorScheme.primary` (replaces `AppColors.teal`)
    - "Needs Review" → already uses `colorScheme.danger` — confirm.
    - "Pending Payment" → `colorScheme.warning` (replaces `AppColors.gold`)
    - "Completed" → `colorScheme.success` (replaces `AppColors.lightTeal`)
  - Sub-step 5.1.3: Remove `import 'package:sline_app/core/theme/app_colors.dart'` if no longer needed.
- [ ] (`@Sentinel`) Verify: counter colors adapt correctly in light and dark mode.
- **GATE CHECK:** Counters use semantic colors.

### 5.2 Work Item Card Status Color Normalization (`@Pixel` | Skill: `colorize`)

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded status colors in `work_item_card.dart`:
  - Sub-step 5.2.1: Replace `AppColors.gold` → `colorScheme.warning` for pending/open statuses.
  - Sub-step 5.2.2: Replace `AppColors.teal` → `colorScheme.primary` for active/confirmed statuses.
  - Sub-step 5.2.3: Replace `AppColors.lightTeal` → `colorScheme.success` for completed/closed statuses.
  - Sub-step 5.2.4: Replace `AppColors.mediumGrey` → `colorScheme.textTertiary` for default/unknown statuses.
  - Sub-step 5.2.5: Verify `colorScheme.danger` is already used for delivered/canceled — confirm.
  - Sub-step 5.2.6: Replace `AppColors.teal` in `FilledButton.styleFrom(backgroundColor: ...)` → `colorScheme.primary`.
  - Sub-step 5.2.7: Replace `AppColors.white` in avatar placeholder → `Theme.of(context).colorScheme.onPrimary` or `colorScheme.textOnPrimary`.
  - Sub-step 5.2.8: Replace hardcoded `radius: 18` for avatar. Use a local variable in the `build` method: `final avatarRadius = AppLayout.avatarSmall / 2;` (18px radius = 36px diameter = `AppLayout.avatarSmall`). Then use `avatarRadius` for the `CircleAvatar` radius. Do NOT use in a `const` context — `const CircleAvatar(radius: AppLayout.avatarSmall / 2)` is valid Dart const but clearer as a local variable.
  - Sub-step 5.2.9: Replace hardcoded `size: 18` for avatar icon → use the same `avatarRadius` local variable for icon size.
  - Sub-step 5.2.10: Replace hardcoded `size: 14` for review icon → `AppDimens.iconSizeSmall` or `AppLayout.iconTiny`.
  - Sub-step 5.2.11: Remove `import 'package:sline_app/core/theme/app_colors.dart'` if no longer needed after semantic migration.
- [ ] (`@Sentinel`) Verify: all status colors render correctly in light and dark mode.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Work item card fully uses semantic tokens. Counter colors correct in both modes. `flutter analyze` clean.

---

## Phase 6: Work Tab — Sub-Tab Styling

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish the Work tab sub-tab bar styling and empty states for consistency with the main dashboard tab redesign.
**Why:** The Work tab already has a styled sub-tab bar (pill indicator using `BoxDecoration`) from earlier phases. Minor normalization pass to ensure consistency with the redesigned main tab bar.
**How:** Modify `work_tab.dart` only.
**Result:** Consistent sub-tab styling, empty states with proper icons and messaging.

> **📸 REDESIGN NOTE (from screenshots SS-6, SS-8, SS-9, SS-19, SS-21):**
> - Sub-tab bar (SS-6, SS-21) already has pill indicator — good. But in light mode (SS-21) the Active pill appears gold/olive instead of primary teal. Verify `colorScheme.primary` is consistent.
> - "Cancelled" empty state (SS-9) is clean — icon + text, centered. Good reference pattern for all empty states.
> - "My Work" header with "Track all your jobs and bookings." subtitle — uses proper hierarchy.
> - Active(4)/Done(16)/Cancelled count badges — good UX showing item counts in tab labels.
> - Skills: `normalize` (token consistency), `audit` (verify empty state patterns match), `harden` (Semantics on all 3 sub-tab empty states)

### 6.1 Sub-Tab Bar Consistency (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Verify and refine work tab sub-tabs:
  - Sub-step 6.1.1: Verify the existing sub-tab `BoxDecoration` indicator uses `colorScheme.primary` (already does — confirm).
  - Sub-step 6.1.2: Verify `labelColor` uses `Theme.of(context).colorScheme.onPrimary` (already does — confirm).
  - Sub-step 6.1.3: Verify `labelStyle: AppTypography.captionBold` (already present — confirm).
  - Sub-step 6.1.4: Replace `AppLayout.statusIndicatorHeight` with `AppLayout.buttonHeightSmall` if more semantically appropriate for a tab bar height (check actual value match).
  - Sub-step 6.1.5: Verify `dividerColor: Colors.transparent` is set.
- [ ] (`@Sentinel`) Verify: sub-tab styling is consistent with main tab bar.
- **GATE CHECK:** Work tab sub-tabs are consistent.

### 6.2 Empty State Polish (`@Pixel` | Skill: `harden`)

- [ ] (`@Pixel` | Skill: `harden`) Verify empty states in Work tab:
  - Sub-step 6.2.1: Active tab empty state already has icon + title + subtitle — confirm all use semantic tokens (`AppLayout.iconFeature`, `AppTypography.h5`, `AppTypography.bodySmall`).
  - Sub-step 6.2.2: Completed tab empty state — verify same pattern.
  - Sub-step 6.2.3: Cancelled tab empty state — verify same pattern.
  - Sub-step 6.2.4: Ensure all empty states have `Semantics` labels (already present on active — verify others).
- [ ] (`@Sentinel`) Verify: all 3 sub-tab empty states are consistent and accessible.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Work tab empty states are polished. `flutter analyze` clean.

---

## Phase 7: Bookings Tab + Inbox Tab — Polish

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish bookings tab (minor) and inbox tab (skeleton loading + empty state).
**Why:** Bookings tab was well-handled in Phase 5 — needs only minor token check. Inbox tab still uses `CircularProgressIndicator` for loading and has hardcoded icon size (64) in empty state.
**How:** Modify `bookings_tab.dart` and `inbox_tab.dart`.
**Result:** Bookings tab verified. Inbox tab has skeleton loading and polished empty state.

> **📸 REDESIGN NOTE (from screenshots SS-5, SS-13, SS-22):**
> - **Bookings Tab** (SS-5, SS-22): Already well-done from Phase 5. Status badges (DELIVERED green, REQUEST PENDING gold, ACTIVE teal, COMPLETED green) look correct in both dark and light mode. Accept/Decline buttons are properly styled. Minor audit pass only.
> - **Inbox Tab** (SS-13): OFFER cards with "UNAVAILABLE" badges. Cards have decent structure but the loading state still uses `CircularProgressIndicator` — this is a visible gap vs. the skeleton loading used everywhere else. **REDESIGN**: Full skeleton loading matching offer card shape. Empty state needs icon + descriptive text matching the pattern from Work tab (SS-9).
> - Inbox `Colors.red` SnackBars — invisible in screenshots but confirmed in code. Must migrate.
> - Inbox empty state uses `AppTypography.h3` and `size: 64` icon — inconsistent with other tabs that use `h5` and `AppLayout.iconFeature` (48). **REDESIGN**: Downsize for consistency.
> - Skills: `extract` (skeleton loading), `harden` (empty state + Semantics), `colorize` (SnackBar colors), `audit` (bookings verification)

### 7.1 Bookings Tab Verification (`@Pixel` | Skill: `audit`)

- [ ] (`@Pixel` | Skill: `audit`) Audit bookings tab for remaining issues:
  - Sub-step 7.1.1: Verify skeleton loading uses `SkeletonLoader` with tokens (already does — confirm).
  - Sub-step 7.1.2: Verify empty state uses `AppLayout.iconFeature` for icon size (already does — confirm).
  - Sub-step 7.1.3: Verify `Semantics` on section headers (already present — confirm).
  - Sub-step 7.1.4: Report any remaining hardcoded values.
- [ ] (`@Sentinel`) Verify: bookings tab passes audit.
- **GATE CHECK:** Bookings tab is clean.

### 7.2 Inbox Tab Skeleton Loading (`@Pixel` | Skill: `extract`)

- [ ] (`@Pixel` | Skill: `extract`) Replace `CircularProgressIndicator` with skeleton loading:
  - Sub-step 7.2.1: When `vm.isLoading && vm.inboxOffers.isEmpty`, render 3-4 skeleton placeholder cards.
  - Sub-step 7.2.2: Each skeleton: approximate shape of `DashboardOfferCard` — avatar circle + lines + price line + action buttons area.
  - Sub-step 7.2.3: Use `SkeletonLoader` with `AppDimens.r16` border radius.
  - Sub-step 7.2.4: Use `AppDimens.p12` vertical spacing between skeleton cards.
  - Sub-step 7.2.5: Wrap skeleton list in `ListView` with `padding: EdgeInsets.all(AppDimens.p16)`.
- [ ] (`@Sentinel`) Verify: skeleton loading renders during inbox data fetch.
- **GATE CHECK:** Inbox skeleton loading works.

### 7.3 Inbox Tab Empty State Polish (`@Pixel` | Skill: `harden`)

- [ ] (`@Pixel` | Skill: `harden`) Polish `_EmptyInboxState`:
  - Sub-step 7.3.1: Replace hardcoded `size: 64` on icon → `AppLayout.iconFeature` (48). NOTE: This is a visual change — 64→48. Verify it still looks balanced. If 48 feels too small, use a custom value with a comment.
  - Sub-step 7.3.2: Replace `AppDimens.p16` gap → `AppLayout.spacingSection`.
  - Sub-step 7.3.3: Replace `AppDimens.p8` gap → `AppLayout.spacingStandard`.
  - Sub-step 7.3.4: Add `Semantics(label: 'No $label yet. $label you receive or send will appear here.')` wrapping with `excludeSemantics: true`.
  - Sub-step 7.3.5: Verify text styles use `AppTypography.h5` and `AppTypography.bodyMedium` (currently `h3` — consider downgrading to `h5` for consistency with other empty states).
- [ ] (`@Sentinel`) Verify: inbox empty state matches other empty state patterns.
- **GATE CHECK:** Inbox tab empty state polished.

### 7.4 Inbox Tab SnackBar Color Normalization (`@Pixel` | Skill: `colorize`)

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded SnackBar colors in `inbox_tab.dart`:
  - Sub-step 7.4.1: Replace `backgroundColor: Colors.red` (line 51) → `backgroundColor: context.colorScheme.danger`.
  - Sub-step 7.4.2: Replace `backgroundColor: Colors.red` (line 59) → `backgroundColor: context.colorScheme.danger`.
- [ ] (`@Sentinel`) Verify: No `Colors.red` in `inbox_tab.dart`.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Phase 7 complete. Bookings verified. Inbox skeleton loading, empty state, and SnackBar colors all normalized. `flutter analyze` clean.

---

## Phase 8: Cross-Feature Card Normalization

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Token normalization pass on cross-feature widgets displayed within the dashboard.
**Why:** These cards are authored in other feature modules but rendered on the dashboard. They should use consistent tokens for a unified experience.
**How:** Modify `wallet_snapshot_card.dart`, `dashboard_booking_card.dart`, `dashboard_offer_card.dart`.
**Result:** All three cards use semantic tokens consistently.

> **📸 REDESIGN NOTE (from screenshots SS-1, SS-5, SS-10, SS-13, SS-22, SS-23):**
> - **Wallet Snapshot Card** (SS-1, SS-10, SS-23): Uses `AppColors.teal/gold` for balance display. The card has a gradient teal background in both modes — this should use `colorScheme.primary` with appropriate opacity. Light mode (SS-23) version looks clean.
> - **Dashboard Booking Card** (SS-5, SS-22): Uses `AppColors.teal` for primary actions and `.withValues(alpha: 0.5)` for muted elements. Status badge colors look correct but need semantic migration.
> - **Dashboard Offer Card** (SS-13): Uses `AppColors.teal` for primary actions, `AppDecorations.elevation(1)` (good), but has hardcoded `Duration(milliseconds: 1000)` — must use `AppMotion.*`. UNAVAILABLE badge styling needs semantic color.
> - **Cross-site risk**: These cards render OUTSIDE dashboard too. Verify standalone rendering after changes.
> - Skills: `normalize` (token migration), `colorize` (semantic colors), `audit` (cross-site render check)

### 8.1 Wallet Snapshot Card (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Token normalization pass:
  - Sub-step 8.1.1: Replace `AppColors.teal` references → `colorScheme.primary`.
  - Sub-step 8.1.2: Replace `AppColors.gold` references → `colorScheme.warning` or `colorScheme.accent` (whichever maps to gold).
  - Sub-step 8.1.3: Replace `AppDimens.p20` → `AppLayout.spacingScreen` or `AppLayout.spacingSection` (choose based on context).
  - Sub-step 8.1.4: Verify spacing between elements uses `AppLayout.*` or `AppDimens.*` tokens.
  - Sub-step 8.1.5: Verify typography uses `AppTypography.*` (already does — confirm).
- [ ] (`@Sentinel`) Verify: wallet snapshot card renders correctly in light and dark mode.
- **GATE CHECK:** Wallet snapshot card normalized.

### 8.2 Dashboard Booking Card (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Token normalization pass:
  - Sub-step 8.2.1: Replace `AppColors.teal` → `colorScheme.primary`.
  - Sub-step 8.2.2: Replace `.withValues(alpha: 0.5)` on colors → use `colorScheme.textSecondary` or appropriate semantic token.
  - Sub-step 8.2.3: Verify all spacing uses `AppDimens.*` tokens.
  - Sub-step 8.2.4: Verify typography uses `AppTypography.*` tokens.
  - Sub-step 8.2.5: Verify card uses `AppCard` or `AppDecorations.elevation()` for shadows.
- [ ] (`@Sentinel`) Verify: booking card consistent with design system.
- **GATE CHECK:** Dashboard booking card normalized.

### 8.3 Dashboard Offer Card (`@Pixel` | Skill: `normalize`)

- [ ] (`@Pixel` | Skill: `normalize`) Token normalization pass:
  - Sub-step 8.3.1: Replace `AppColors.teal` → `colorScheme.primary`.
  - Sub-step 8.3.2: Scan for any remaining hardcoded `Duration(milliseconds: ...)` → replace with `AppMotion.*` tokens.
  - Sub-step 8.3.3: Verify `AppDecorations.elevation(1, isDark: isDark)` usage (already present — confirm).
  - Sub-step 8.3.4: Verify all spacing uses `AppDimens.*` tokens.
  - Sub-step 8.3.5: Verify all typography uses `AppTypography.*` tokens.
  - Sub-step 8.3.6: Verify all icon sizes use `AppDimens.iconSize*` tokens.
- [ ] (`@Sentinel`) Verify: offer card consistent with design system.
- **GATE CHECK:** Dashboard offer card normalized.

### 8.4 Cross-Site Render Verification (`@Sentinel` | Skill: `audit`)

- [ ] (`@Sentinel`) Verify cross-feature cards render correctly OUTSIDE the dashboard:
  - Sub-step 8.4.1: Wallet snapshot card — verify it still renders correctly on the standalone WalletScreen (if used there).
  - Sub-step 8.4.2: Dashboard booking card — verify on any non-dashboard screen that uses it.
  - Sub-step 8.4.3: Dashboard offer card — verify on any non-dashboard screen that uses it (e.g., task detail views).
  - Sub-step 8.4.4: If a cross-feature card is only used on the dashboard, note that in the session log and skip standalone verification.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Phase 8 complete. All cross-feature cards normalized. No regressions in standalone contexts. `flutter analyze` clean.

---

## Phase 9: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 9.1 Static Analysis

- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean with zero issues.
- [ ] (`@Sentinel`) Run `dart format . --set-exit-if-changed` — must pass clean.
- [ ] (`@CodeGuard`) Verify no new imports of Supabase in View files.
- [ ] (`@CodeGuard`) Verify no business logic added to View files.
- **GATE CHECK:** Static analysis clean.

### 9.2 Architecture Guard

- [ ] (`@Sentinel`) Verify MVVM boundaries:
  - No `Supabase.instance` in view files.
  - No `Navigator` in ViewModel files.
  - No `import 'package:sline_app/features/dashboard/viewmodels/'` in widgets that should only consume via Provider.
- [ ] (`@Sentinel`) Verify all new widgets have `Semantics` labels.
- [ ] (`@Sentinel`) Verify all animations use `AppMotion.*` tokens (no hardcoded `Duration`).
- [ ] (`@Sentinel`) Verify all colors use `colorScheme.*` semantic tokens (no `AppColors.*` except where truly theme-independent like brand logo).
- [ ] (`@Sentinel`) Run grep invariant checks (machine-verifiable):
  - `grep -r "AppColors\." lib/features/dashboard/view/` → must return zero matches.
  - `grep -r "Colors\.\(red\|green\|blue\|orange\)" lib/features/dashboard/view/` → must return zero matches.
  - `grep -r "Duration(milliseconds:" lib/features/dashboard/view/` → must return zero matches.
  - `grep -r "print\(\|debugPrint\(" lib/features/dashboard/view/` → must return zero matches.
- **GATE CHECK:** Architecture and design system compliance verified with machine-verifiable checks.

### 9.3 Test Execution

- [ ] (`@Sentinel`) Run `flutter test` — all existing tests must pass.
- [ ] (`@Sentinel`) Run dashboard-specific tests if any: `flutter test test/ --name dashboard`.
- [ ] (`@Sentinel`) Verify no new test failures introduced.
- [ ] (`@Sentinel`) Document test results in session log.
- **GATE CHECK:** All tests pass.

### 9.4 Visual Verification Checklist

- [ ] (`@Pixel`) Verify on device/emulator:
  - Dashboard Overview tab: greeting, wallet snapshot, counters, next actions, activity feed.
  - Dashboard Work tab: all 3 sub-tabs with items + empty states.
  - Dashboard Bookings tab: upcoming + past sections.
  - Dashboard Inbox tab: skeleton loading, offer cards, empty state.
  - Dashboard Settings: bottom sheet opens, role switching works.
  - Light mode AND dark mode for all above.
- [ ] (`@Sentinel`) Document visual verification results in session log.
- **GATE CHECK:** Visual verification complete.

---

## Phase 10: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@SlineDocs`

- [ ] (`@SlineDocs`) Update session log with completion status, timeline, and agent notes.
- [ ] (`@SlineDocs`) Write `.TODO/DOCS_SYNC_2026-04-10_Phase7_Dashboard.md` documenting:
  - Files changed.
  - Tokens introduced/used.
  - Visual changes made.
  - Known gaps or deferred items.
- [ ] (`@SlineDocs`) Verify session log cross-references plan file.
- **GATE CHECK:** Documentation is aligned with implementation.

---

## 7) Acceptance Criteria (MANDATORY)

1. Dashboard TabBar uses pill-style indicator (not default Material underline).
2. Settings modal is a bottom sheet (not AlertDialog).
3. Role switcher uses animated segmented control with haptic feedback.
4. Overview greeting is time-aware ("Good morning/afternoon/evening, {name}").
5. Next actions list has priority left-bar color indicators.
6. Next actions list has stagger entrance animation.
7. Next actions list has skeleton loading (not CircularProgressIndicator).
8. Next actions list has "All caught up!" empty state with icon.
9. Activity feed has time grouping headers ("Today", "Yesterday", "Earlier").
10. Activity feed expand/collapse uses AnimatedSize.
11. Inbox tab has skeleton loading (not CircularProgressIndicator).
12. All dashboard widgets use `colorScheme.*` semantic tokens (not `AppColors.*`).
13. All dashboard widgets use `AppLayout.*`/`AppDimens.*` spacing tokens (no raw numeric literals for spacing).
14. All animations use `AppMotion.*` tokens (no hardcoded `Duration`).
15. All interactive elements have `Semantics` labels.
16. `flutter analyze` passes clean.
17. All existing tests pass.
18. View-layer only — no ViewModel/Service/Repository changes.

## 8) Rollback Plan

- **Immediate revert:** All changes are View-layer only. `git revert` on the commit(s) safely rolls back the entire phase with zero impact on business logic, data, or backend.
- **No migrations:** No schema, RLS, RPC, or backend changes.
- **No behavioral changes:** No ViewModel state changes, no new data fields, no navigation changes.
- **Feature-flag option:** Not needed — visual refinements only. If any specific change causes issues, individual file reverts are safe.
- **Forward-fix preferred:** If a specific widget looks wrong after deployment, modify the token values in the widget rather than reverting the entire phase.
- **Evidence check:** Before rollback, verify the issue is from Phase 7 changes by checking `git diff` against the Phase 6 commit.

## 9) References (From Scan)

### Docs Scanned
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — Phase 7 specification (lines 982-1036)
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Design system token definitions
- `CLAUDE.md` — Architecture rules, MVVM discipline, coding conventions

### Code Paths Scanned
- `lib/features/dashboard/view/dashboard_screen.dart` (357 lines)
- `lib/features/dashboard/view/tabs/overview_tab.dart` (104 lines)
- `lib/features/dashboard/view/tabs/work_tab.dart` (493 lines)
- `lib/features/dashboard/view/tabs/bookings_tab.dart` (236 lines)
- `lib/features/dashboard/view/tabs/inbox_tab.dart` (182 lines)
- `lib/features/dashboard/view/tabs/wallet_tab.dart` (15 lines)
- `lib/features/dashboard/view/widgets/activity_feed_preview.dart` (383 lines)
- `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart` (279 lines)
- `lib/features/dashboard/view/widgets/next_actions_list.dart` (192 lines)
- `lib/features/dashboard/view/widgets/work_item_card.dart` (310 lines)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (530 lines)
- `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` (101 lines)
- `lib/features/booking/view/widgets/dashboard_booking_card.dart` (250 lines)
- `lib/features/tasks/view/widgets/dashboard_offer_card.dart` (626 lines)
- `lib/core/theme/app_motion.dart` (122 lines)
- `lib/core/theme/app_layout.dart` (202 lines)
- `lib/core/theme/app_states.dart` (114 lines)
- `lib/core/theme/app_decorations.dart` (113 lines)
- `lib/core/theme/app_dimens.dart` (65 lines)
- `lib/core/theme/app_colors.dart` (440 lines)
- `lib/core/theme/app_typography.dart` (143 lines)
- `lib/core/theme/app_theme.dart` (305 lines)

### Database Objects
- No database objects touched by this plan (View-layer only).
- Dashboard reads from: `vw_unified_work_items` (via ViewModel → Repository), `activity_log`, `bookings`, `task_requests`. No changes planned.

### Related `.TODO/` Artifacts
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md`
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md`

---

## 10) Plan Appendix: Scan Evidence (Mandatory)

### Constructor Signatures

| Class | Constructor | Base Class | Mixins |
|-------|------------|------------|--------|
| `DashboardScreen` | `({super.key, this.tabViews})` | `StatelessWidget` | — |
| `_DashboardContent` | `({this.tabViews})` | `StatefulWidget` | `SingleTickerProviderStateMixin` |
| `OverviewTab` | `({super.key})` | `StatefulWidget` | — |
| `WorkTab` | `({super.key})` | `StatefulWidget` | `SingleTickerProviderStateMixin` |
| `BookingsTab` | `({super.key})` | `StatelessWidget` | — |
| `InboxTab` | `({super.key})` | `StatefulWidget` | — |
| `WalletTab` | `({super.key})` | `StatelessWidget` | — |
| `DashboardCountersGrid` | `({super.key})` | `StatelessWidget` | — |
| `NextActionsList` | `({super.key})` | `StatelessWidget` | — |
| `ActivityFeedPreview` | `({super.key, this.limit})` | `StatefulWidget` | `SingleTickerProviderStateMixin` |
| `WorkItemCard` | `({super.key, required this.item, this.onPrimaryAction, this.onSecondaryAction})` | `StatelessWidget` | — |
| `WalletSnapshotCard` | `({super.key})` | `StatelessWidget` | — |
| `DashboardBookingCard` | `({super.key, required booking, required isProvider, ...callbacks})` | `StatelessWidget` | — |
| `DashboardOfferCard` | `({super.key, required offer, required isClientView, ...callbacks})` | `StatefulWidget` | — |

### Line Counts

| File | Current Lines |
|------|-------------|
| `dashboard_screen.dart` | 357 |
| `overview_tab.dart` | 104 |
| `work_tab.dart` | 493 |
| `bookings_tab.dart` | 236 |
| `inbox_tab.dart` | 182 |
| `wallet_tab.dart` | 15 |
| `activity_feed_preview.dart` | 383 |
| `dashboard_counters_grid.dart` | 279 |
| `next_actions_list.dart` | 192 |
| `work_item_card.dart` | 310 |
| `wallet_snapshot_card.dart` | 101 |
| `dashboard_booking_card.dart` | 250 |
| `dashboard_offer_card.dart` | 626 |
| **Total View-Layer Lines** | **3,528** |

### Token Usage Baseline

| Token System | Files Using It | Files NOT Using It |
|-------------|---------------|-------------------|
| `AppMotion.*` | dashboard_screen, activity_feed_preview, dashboard_counters_grid | next_actions_list, work_item_card, bookings_tab, inbox_tab, overview_tab |
| `AppLayout.*` | dashboard_screen, work_tab, bookings_tab, activity_feed_preview | next_actions_list, dashboard_counters_grid, inbox_tab, overview_tab (uses AppDimens only) |
| `AppStates.*` | dashboard_screen (_RoleButton haptic), activity_feed_preview (haptic tap) | next_actions_list, work_item_card, inbox_tab, overview_tab, dashboard_counters_grid |
| `AppDecorations.elevation()` | dashboard_offer_card | dashboard_counters_grid (uses AppCard), work_item_card (uses AppCard) |
| `colorScheme.*` (semantic) | dashboard_counters_grid (partial), activity_feed_preview, work_item_card (partial) | next_actions_list, wallet_snapshot_card |
| `AppColors.*` (direct) | dashboard_counters_grid (4 uses), work_item_card (4 uses), wallet_snapshot_card (2 uses), dashboard_booking_card (1 use), dashboard_offer_card (1 use) | — |

### Hardcoded Values to Replace

| File | Hardcoded Value | Replacement Token |
|------|----------------|-------------------|
| `dashboard_counters_grid.dart` | `AppColors.gold` | `colorScheme.warning` |
| `dashboard_counters_grid.dart` | `AppColors.teal` | `colorScheme.primary` |
| `dashboard_counters_grid.dart` | `AppColors.lightTeal` | `colorScheme.info` / `colorScheme.success` |
| `dashboard_counters_grid.dart` | `AppColors.mediumGrey` | `colorScheme.textSecondary` |
| `work_item_card.dart` | `AppColors.gold` | `colorScheme.warning` |
| `work_item_card.dart` | `AppColors.teal` | `colorScheme.primary` |
| `work_item_card.dart` | `AppColors.lightTeal` | `colorScheme.success` |
| `work_item_card.dart` | `AppColors.mediumGrey` | `colorScheme.textTertiary` |
| `work_item_card.dart` | `AppColors.white` | `Theme.of(context).colorScheme.onPrimary` |
| `work_item_card.dart` | `radius: 18` | `AppLayout.avatarSmall / 2` |
| `work_item_card.dart` | `size: 18` | `AppLayout.avatarSmall / 2` |
| `work_item_card.dart` | `size: 14` | `AppLayout.iconTiny` |
| `inbox_tab.dart` | `size: 64` | `AppLayout.iconFeature` |
| `inbox_tab.dart` | `Colors.red` | `colorScheme.danger` |
| `wallet_snapshot_card.dart` | `AppColors.teal` | `colorScheme.primary` |
| `wallet_snapshot_card.dart` | `AppColors.gold` | `colorScheme.warning` |
| `dashboard_booking_card.dart` | `AppColors.teal` | `colorScheme.primary` |
| `dashboard_offer_card.dart` | `AppColors.teal` | `colorScheme.primary` |
| `next_actions_list.dart` | `Colors.green` | `colorScheme.success` |
| `next_actions_list.dart` | `Colors.red` | `colorScheme.danger` |

### Provider Dependencies (View-Layer)

| Screen/Widget | Provider Dependencies |
|--------------|----------------------|
| `_DashboardContent` | `context.watch<DashboardViewModel>()`, `context.read<DirectOffersService>()`, `context.read<PaymentService>()` |
| `OverviewTab` | `context.watch<DashboardViewModel>()`, `context.read<WalletViewModel>()` |
| `WorkTab` | `context.watch<DashboardViewModel>()` |
| `BookingsTab` | `Consumer<DashboardViewModel>` |
| `InboxTab` | `Consumer<DashboardViewModel>` |
| `WalletTab` | (delegates to WalletSharedBody which has its own providers) |
| `DashboardCountersGrid` | `context.watch<DashboardViewModel>()` |
| `NextActionsList` | `context.watch<DashboardViewModel>()`, `context.read<DeepLinkService>()` |
| `ActivityFeedPreview` | `context.watch<DashboardViewModel>()`, `context.read<DeepLinkService>()` |
| `WorkItemCard` | `context.read<DeepLinkService>()`, `context.read<DashboardViewModel>()` |

### Singleton/Static State
- None relevant. Dashboard widgets are stateless or use `SingleTickerProviderStateMixin` for animations only. No singleton cleanup required for View-layer changes.

END.
