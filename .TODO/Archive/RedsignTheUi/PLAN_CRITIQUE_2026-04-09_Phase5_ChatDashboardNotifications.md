# @PlanCritic Audit: Phase 5 — Chat, Dashboard & Notifications UI Redesign

**Plan File:** `.TODO/PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
**Audit Date:** 2026-04-09
**Auditor:** @PlanCritic

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred Safe Defaults)
1. **View-layer-only scope is correct** — all data needed by UI is already exposed by ViewModels. Verified: ChatViewModel exposes isLoadingConversations, isLoadingMessages, isSending, otherUserTyping. NotificationViewModel exposes isLoading, error, unreadCount.
2. **Design system tokens are complete** — AppMotion, AppStates, AppDecorations, AppColors semantic, AppLayout, AppTypography all verified present and usable.
3. **No new pubspec.yaml dependencies** — all animations are Flutter-native (AnimationController, AnimatedContainer, TweenAnimationBuilder).
4. **Stagger animation pattern established in auth screens** — Phase 5 MUST reuse the same Interval-based single-controller pattern from login_screen.dart / signup_screen.dart.
5. **ChatScreen ListView.builder does NOT use reverse:true** — messages are pre-sorted by ViewModel. Date separator and scroll-to-bottom logic must account for this.
6. **Work Tab dimming (0.7 opacity)** is intentional design for historical items, NOT the Material disabled state (0.38). Plan should preserve 0.7, not replace with `AppInteractionStates.disabledOpacity`.

### Decision Needed (Blocking)

#### DN-1: Unread Message Count — ViewModel Change Required
- **What:** Plan Phase 2.3 proposes pill badge showing unread message count (e.g., "3"). Current `Conversation` model has NO `unreadCount` field — only a boolean derived from `lastMessageSeenAt == null`.
- **Options:**
  - **A) Keep boolean dot** — cosmetically enhance (bigger, teal dot) without ViewModel/model changes. Stays within View-layer-only scope.
  - **B) Add unreadCount to scope** — requires Conversation model change + ChatViewModel computation. Breaks View-layer-only scope.
  - **C) Compute count locally in View** — count messages where `seenAt == null` from `currentMessages`. Fragile (requires active conversation context, not available in inbox).
- **Recommended:** Option A. The pill badge should show a BOOLEAN indicator (styled as a prominent dot or "New" label), not a numeric count. Adding `unreadCount` requires model + ViewModel changes that violate the plan's View-layer-only constraint. Log numeric count as a future enhancement.
- **Plan impact:** Phase 2.3 must be rewritten to remove numeric count assumption. Use styled boolean indicator instead.

#### DN-2: NotificationBadgeButton StatefulWidget Conversion
- **What:** Plan Phase 7.3 requires pulse animation, which needs AnimationController + TickerProviderStateMixin. Widget is currently StatelessWidget.
- **Options:**
  - **A) Convert to StatefulWidget** — clean, standard Flutter pattern.
  - **B) Use TweenAnimationBuilder** — stays stateless but limited animation control.
- **Recommended:** Option A. Pulse animation requires repeating/stopping on count change, which TweenAnimationBuilder can't cleanly handle. StatefulWidget conversion is minimal risk.
- **Plan impact:** Phase 7.3 must explicitly include the StatelessWidget→StatefulWidget conversion step.

---

## B) Gate Status

### Gate 1: Data / Contracts Gate — ✅ PASS
- No data model changes required (with DN-1 resolved as Option A)
- All UI state already exposed by ViewModels
- No new API contracts

### Gate 2: Security / RLS Gate — ✅ PASS
- View-layer-only changes, no security surface
- No new Supabase calls, no data access changes

### Gate 3: Backend / Supabase Gate — ✅ PASS
- No backend changes
- Session log initialized at `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
- No diagram artifact needed (no schema/flow changes)

### Gate 4: UI / Integration Gate — ❌ FAIL
**Reasons:**
1. **Ordering violation (Phase 3 ↔ Phase 4):** Phase 3 (ChatScreen) adds date separators and message grouping logic in the ListView.builder. Phase 4 (MessageBubble) adds `isFirstInGroup`/`isLastInGroup` params. But ChatScreen CALLS MessageBubble — you cannot add grouping logic to ChatScreen before the MessageBubble API is updated. **MessageBubble must be updated BEFORE ChatScreen.**
2. **Missing intermediate step:** ChatScreen grouping computation (determining which messages are first/last in group based on sender + 2-minute window) is non-trivial View logic. The plan bundles it as one line in Phase 4.2 step 5: "ChatScreen (Phase 3) passes grouping flags based on sender + 2-minute window." This is backwards — ChatScreen changes are in Phase 3, but this step references Phase 3 from within Phase 4.
3. **Stagger animation pattern not specified:** Plan says "stagger entrance" in 4 places (Phases 1, 7, 8) but never defines the implementation pattern. The established pattern (Interval-based single AnimationController from auth screens) must be explicitly mandated. Different implementations across screens would be inconsistent.
4. **Work Tab dimming fix is wrong:** Plan Phase 9.1 says "Replace `Opacity(opacity: isDimmed ? 0.7 : 1.0)` with `AppInteractionStates.disabledOpacity`." This would change 0.7 to 0.38 — making completed items nearly invisible. 0.7 is intentional design, not a hardcoded defect.

**Fixes required:**
1. Reorder: MessageBubble (Phase 4) → ChatScreen (Phase 3). Or merge into one phase with MessageBubble API changes first.
2. Add explicit grouping computation sub-phase with algorithm specification.
3. Add mandatory "Stagger Pattern" sub-phase in Phase 0 specifying the Interval pattern from auth screens.
4. Remove the `AppInteractionStates.disabledOpacity` replacement for Work Tab dimming. Keep 0.7 as-is or define a new token `AppInteractionStates.dimmedOpacity = 0.7`.

### Gate 5: Release / QA Gate — ❌ FAIL
**Reasons:**
1. **No new widget tests planned:** Plan modifies 17 files including MessageBubble (adding new params), ConversationListTile (animated typing dots, badge), NotificationBadgeButton (converting to StatefulWidget). No test creation is planned. Existing tests cover only chat_screen and messages_screen with 5 total tests.
2. **No intermediate flutter analyze checkpoints:** The plan runs `flutter analyze` only at Phase 11 (QA). With 10 implementation phases, a broken import or type error in Phase 3 won't be caught until Phase 11. Prior plans (Phase 2, Phase 4) ran `flutter analyze` at the end of EACH phase.
3. **No flutter test intermediate checkpoints:** Same issue — test suite should run after each major phase, not just at the end.

**Fixes required:**
1. Add widget test sub-phase after chat implementation (test MessageBubble grouping, ConversationListTile badge, date separators).
2. Add `flutter analyze` verification step to EVERY phase gate check (not just Phase 11).
3. Add `flutter test` checkpoint after Phase 6 (all chat done) and Phase 9 (all dashboard done).

---

## C) Critical Gaps (Must-Fix)

### GAP-1: Phase Ordering — MessageBubble Before ChatScreen
- **Gap:** ChatScreen (Phase 3) needs MessageBubble to accept `isFirstInGroup`/`isLastInGroup`, but MessageBubble API changes are in Phase 4.
- **Why it will break:** ChatScreen cannot pass grouping params until MessageBubble accepts them. Executing Phase 3 before Phase 4 requires temporarily omitting grouping, then backfilling — wasteful and error-prone.
- **Fix:** Move MessageBubble token normalization + API changes (Phase 4.1, 4.2) before ChatScreen implementation. New order: Phase 3 = MessageBubble, Phase 4 = ChatScreen.
- **Owner:** @Pixel
- **Acceptance check:** MessageBubble has `isFirstInGroup`/`isLastInGroup` params before ChatScreen grouping logic is written.

### GAP-2: Unread Count Assumes Non-Existent Data
- **Gap:** Phase 2.3 says "pill badge showing unread message count (min-width 18, height 18, '99+' max)." Conversation model has no `unreadCount` field.
- **Why it will break:** Executor will try to read `conversation.unreadCount` which doesn't exist. Either causes compile error or requires ViewModel changes that violate scope.
- **Fix:** Replace numeric count badge with boolean "New" indicator or styled dot. Document numeric badge as future enhancement requiring ViewModel + model changes.
- **Owner:** @Pixel
- **Acceptance check:** ConversationListTile unread badge compiles using only `_isUnread(myUserId)` boolean.

### GAP-3: Work Tab Dimming Would Break Visual Design
- **Gap:** Phase 9.1 says "Replace `Opacity(opacity: isDimmed ? 0.7 : 1.0)` with `AppInteractionStates.disabledOpacity`." That constant is 0.38.
- **Why it will break:** Completed work items would become nearly invisible (38% opacity vs current 70%). This is not a hardcoded defect — 0.7 is intentional dimming for historical items.
- **Fix:** Keep 0.7 as-is. Remove this step from Phase 9.1. Optionally add `static const dimmedOpacity = 0.7` to AppInteractionStates if token purity is desired.
- **Owner:** @Pixel
- **Acceptance check:** Completed work items remain at 70% opacity after redesign.

### GAP-4: Stagger Animation Pattern Not Specified
- **Gap:** Plan says "stagger entrance" in 4 places but never defines which Flutter pattern to use.
- **Why it will break:** Executor might use AnimatedList, or multiple AnimationControllers, or custom Tween chains. Auth screens use Interval-based single-controller pattern. Inconsistency creates maintenance burden and visual inconsistency.
- **Fix:** Add Phase 0 sub-phase "0.4 Stagger Pattern Lock" that specifies: single AnimationController per screen, Interval curves with begin/end percentages, SlideTransition + FadeTransition pairs, trigger via postFrameCallback. Reference auth screens as canonical example.
- **Owner:** @Pixel
- **Acceptance check:** All stagger animations use the Interval-based pattern from auth screens.

### GAP-5: NotificationBadgeButton Conversion Not Explicit
- **Gap:** Plan adds pulse animation but doesn't mention StatelessWidget→StatefulWidget conversion.
- **Why it will break:** AnimationController requires TickerProviderStateMixin. Executor will hit compilation error or waste time discovering this.
- **Fix:** Add explicit step in Phase 7.3: "Convert StatelessWidget to StatefulWidget with SingleTickerProviderStateMixin."
- **Owner:** @Pixel
- **Acceptance check:** NotificationBadgeButton is StatefulWidget with AnimationController for pulse.

### GAP-6: No Widget Tests for New Behavior
- **Gap:** Plan adds message grouping (new params), animated typing dots, date separators, badge animations — but creates zero new tests.
- **Why it will break:** Regressions in grouping logic (edge cases: single message, boundary between groups, timezone-sensitive date comparisons) won't be caught. Existing tests only cover basic rendering.
- **Fix:** Add test sub-phase after chat implementation: test MessageBubble with grouped/ungrouped variants, test date separator positioning, test ConversationListTile unread states.
- **Owner:** @Sentinel
- **Acceptance check:** At least 5 new widget tests covering grouping, separators, and badge states.

### GAP-7: Missing flutter analyze at Each Phase Gate
- **Gap:** `flutter analyze` only runs at Phase 11 (QA). 10 implementation phases could accumulate errors.
- **Why it will break:** Type errors from MessageBubble param changes in Phase 3 won't surface until Phase 11. Prior plans ran analyze at each phase boundary.
- **Fix:** Every phase GATE CHECK must include "`flutter analyze` — must pass clean."
- **Owner:** @Sentinel
- **Acceptance check:** Every GATE CHECK in the corrected plan includes `flutter analyze`.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to Enforce | How to Verify |
|-----------|---------------|---------------|
| No View imports Supabase directly | Architecture guard grep: `import.*supabase` in `lib/features/*/view/` | CI architecture check + Phase 11.3 |
| No ViewModel logic in Views | Code review: no business decisions, data fetching, or state mutations in View files | Manual review + CI guard |
| AppLogger used, never print() | Grep for `print(` and `debugPrint(` in modified files | Phase 11.4 extended audit |
| Stagger animations use established Interval pattern | Phase 0.4 pattern lock | Code review of all stagger implementations |
| Semantics on every interactive element | Manual audit in Phase 11.4 | Grep for `Semantics(` in modified files, verify count matches interactive element count |
| No raw Duration/BoxShadow/fontSize/Color(0x in View files | Token compliance grep in Phase 11.4 | Automated grep with zero tolerance |
| MessageBubble grouping is pure display logic | No ViewModel calls in grouping computation | Grouping computed from message list properties only (senderId, createdAt) |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Date separator item count breaks ListView.builder index math | ChatScreen Phase 4 | Medium | High | Chat screen crashes | Off-by-one errors in message rendering | Separate `_buildListItems()` that pre-computes items + separators into a flat list before builder | Remove separators; render without them |
| Stagger animation replays on navigation back | Messages/Notifications | Medium | Medium | Annoying re-animation | Test back-navigation after first load | `_hasAnimatedEntrance` bool flag, checked in postFrameCallback | Set stagger duration to Duration.zero on re-entry |
| Message grouping 2-minute window edge case | MessageBubble | Medium | Low | Visual glitch (wrong grouping) | Messages at exactly 2-minute boundary | Use `>=` comparison, add unit test for boundary | Disable grouping (all isFirstInGroup = true) |
| Typography height changes affect bubble sizing | MessageBubble | Low | Medium | Bubbles too tall/cramped | Visual spot check in Phase 11.5 | Compare before/after screenshots | Revert to inline height override |
| Scroll-to-bottom FAB conflicts with keyboard | ChatScreen | Medium | Medium | FAB overlaps input | Test with keyboard open | Position FAB above input bar using `MediaQuery.viewInsets` | Hide FAB when keyboard is open |
| SkeletonConversationTile avatar size mismatch | Phase 10 | Low | Low | Skeleton doesn't match real tile | Visual comparison | Update skeleton in same phase as tile changes | Acceptable visual difference |
| 17 files modified in one PR | All phases | Low | Medium | Large review surface | PR size > 2000 lines | Consider 2-3 commits (chat, notifications, dashboard) | Individual file reverts possible |

---

## F) Pre-Mortem (How This Fails In Real Life)

1. **This fails when** the executor adds `isFirstInGroup` to MessageBubble in Phase 4, but ChatScreen (Phase 3) was already implemented without grouping — requiring a full re-visit of ChatScreen's ListView.builder to add grouping computation. Fix: reorder phases.

2. **This fails when** the executor tries to show "3 unread" in the conversation tile badge, discovers `Conversation.unreadCount` doesn't exist, and starts modifying the model/ViewModel to add it — violating the View-layer-only scope and creating untested data layer changes. Fix: use boolean indicator only.

3. **This fails when** the stagger animation in messages_screen uses `AnimatedList` while login_screen uses the Interval pattern — resulting in two different stagger implementations that animate differently. The user notices chat feels "different" from auth. Fix: lock the pattern in Phase 0.

4. **This fails when** the Work Tab dimming is changed from 0.7 to 0.38 and completed jobs become nearly invisible in dark mode. User reports "I can't see my completed work." Fix: don't replace intentional design values with wrong constants.

5. **This fails when** the scroll-to-bottom FAB appears on top of the keyboard in ChatScreen, blocking the last message. The FAB positioning doesn't account for `MediaQuery.viewInsets.bottom`. Fix: add keyboard-aware positioning in Phase 4.4.

6. **This fails when** date separators are added by incrementing `itemCount` in ListView.builder, but the index mapping between the flat list and the message list is wrong — causing the wrong message to render at each position. Fix: pre-compute a flat list of `_ChatListItem` (either message or separator) before passing to builder.

7. **This fails when** `flutter analyze` is only run at Phase 11 and a type error from Phase 3's MessageBubble param changes silently breaks 5 other files. The executor discovers the cascade at Phase 11 and must debug across 10 phases of changes. Fix: run analyze at each phase gate.

8. **This fails when** the NotificationBadgeButton pulse animation is added to a StatelessWidget, causing a compilation error ("AnimationController requires TickerProviderStateMixin"). The executor converts to StatefulWidget but forgets to move the Consumer pattern into the new State class, breaking notification count reactivity. Fix: explicit conversion step.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### FIX-1: Add Phase 0.4 — Stagger Pattern Lock
- **Goal:** Establish a single canonical stagger animation pattern for all screens.
- **Why:** 4 screens need stagger (messages, chat, notifications, activity feed). Without locking the pattern, each will be implemented differently.
- **How:** Document the Interval-based single-controller pattern from auth screens. Mandate all Phase 5 staggers use this exact pattern.
- **Output artifact:** Pattern documented in Phase 0.4 checklist.
- **Stop condition:** Pattern is documented with reference to auth screen implementation.

### FIX-2: Reorder — MessageBubble Before ChatScreen
- **Goal:** Ensure MessageBubble API is stable before ChatScreen consumes it.
- **Why:** ChatScreen cannot pass `isFirstInGroup`/`isLastInGroup` until MessageBubble accepts them.
- **How:** Move current Phase 4 (MessageBubble) to execute before current Phase 3 (ChatScreen). New order: MessageBubble → ChatScreen.
- **Output artifact:** Corrected phase numbering.
- **Stop condition:** MessageBubble compiles with new params before ChatScreen work begins.

### FIX-3: Add ChatScreen Grouping Computation Sub-Phase
- **Goal:** Explicitly define how message grouping is computed in the ListView.builder.
- **Why:** Plan bundles this as one line. It's actually non-trivial: build a flat list of `_ChatListItem` (message or date separator), compute `isFirstInGroup`/`isLastInGroup` for each message based on adjacent items.
- **How:** Add dedicated sub-phase in ChatScreen phase with algorithm: iterate messages, compare senderId and createdAt to previous message, emit separator items at day boundaries.
- **Output artifact:** `_buildChatItems()` method in ChatScreen.
- **Stop condition:** All messages render with correct grouping and date separators.

### FIX-4: Fix Unread Badge to Boolean (Not Count)
- **Goal:** Make ConversationListTile unread badge feasible within View-layer-only scope.
- **Why:** Conversation model has no `unreadCount` field.
- **How:** Replace pill-with-count with prominent boolean indicator: 10px teal dot or "New" label. Log numeric count as future ViewModel enhancement.
- **Output artifact:** Updated Phase 2.3 steps.
- **Stop condition:** Badge compiles using only `_isUnread()` boolean.

### FIX-5: Fix Work Tab Dimming — Keep 0.7
- **Goal:** Preserve intentional 70% opacity for completed items.
- **Why:** `AppInteractionStates.disabledOpacity` (0.38) is for truly disabled controls, not dimmed historical content.
- **How:** Remove the replacement step. Keep `0.7` or add `AppInteractionStates.dimmedOpacity = 0.7` if token purity matters.
- **Output artifact:** Updated Phase 9.1 steps.
- **Stop condition:** Completed work items render at 70% opacity.

### FIX-6: Add NotificationBadgeButton Conversion Step
- **Goal:** Explicit StatelessWidget→StatefulWidget conversion.
- **Why:** Pulse animation requires AnimationController + TickerProviderStateMixin.
- **How:** Add step: "Convert to StatefulWidget with SingleTickerProviderStateMixin. Move Consumer logic to build(). Add AnimationController for pulse."
- **Output artifact:** Updated Phase 7.3 steps.
- **Stop condition:** NotificationBadgeButton compiles as StatefulWidget with pulse animation.

### FIX-7: Add Widget Test Sub-Phase
- **Goal:** Test new behavior (grouping, separators, badges) to prevent regressions.
- **Why:** 17 files modified with new params, new animation, new rendering logic. Zero new tests planned.
- **How:** Add Phase 10A (after all implementation, before QA) with at least 5 widget tests: MessageBubble grouping, date separator rendering, ConversationListTile unread state, notification skeleton→content, scroll-to-bottom FAB visibility.
- **Output artifact:** New test files in `test/widget/chat/` and `test/widget/notifications/`.
- **Stop condition:** 5+ new tests pass.

### FIX-8: Add flutter analyze to Every Gate Check
- **Goal:** Catch errors early, not at Phase 11.
- **Why:** 10 implementation phases could accumulate type errors. Prior plans ran analyze per phase.
- **How:** Add `(@Sentinel) Run flutter analyze — must pass clean.` to every GATE CHECK that doesn't already have it.
- **Output artifact:** Updated GATE CHECKs.
- **Stop condition:** Every phase gate includes analyze step.

### FIX-9: Add Keyboard-Aware FAB Positioning
- **Goal:** Prevent scroll-to-bottom FAB from overlapping keyboard/input bar.
- **Why:** FAB is positioned in a Stack. When keyboard opens, it would overlap the input area.
- **How:** Add step in ChatScreen phase: "Position FAB using `MediaQuery.viewInsets.bottom` to stay above keyboard. Hide FAB when keyboard is open OR position above input bar."
- **Output artifact:** Updated Phase 4 (ChatScreen) sub-phase.
- **Stop condition:** FAB is not visible when keyboard is open, or positions correctly above input.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

**Key changes from original:**
1. Phases 3 and 4 swapped (MessageBubble before ChatScreen)
2. Phase 0.4 added (Stagger Pattern Lock)
3. Unread badge changed from numeric to boolean
4. Work Tab dimming preserved at 0.7
5. NotificationBadgeButton conversion made explicit
6. Widget test phase added as Phase 10A
7. `flutter analyze` added to every GATE CHECK
8. Keyboard-aware FAB positioning added
9. ChatScreen grouping computation made explicit sub-phase

### Corrected Phase Order:

| Phase | Content | Primary Agent |
|-------|---------|---------------|
| 0 | Preconditions (Spec Lock, Discovery, Screenshots, **Stagger Pattern Lock**) | @SlinePlanner, @Sentinel |
| 1 | Messages Screen — Inbox (stagger, empty state, **boolean** unread badge) | @Pixel, @Sentinel |
| 2 | ConversationListTile (typing dots, **boolean** unread indicator, tokens) | @Pixel, @Sentinel |
| 3 | **MessageBubble** (tokens, grouping API, status icons, Semantics) — **MOVED UP** | @Pixel, @Sentinel |
| 4 | **ChatScreen** (tokens, **grouping computation**, date separators, send button, scroll FAB, **keyboard-aware** FAB, empty state, input bar) — **MOVED DOWN** | @Pixel, @Architect, @Sentinel |
| 5 | OfferMessageBubble & CreateOfferSheet (tokens, haptics, Semantics) | @Pixel, @Sentinel |
| 6 | AttachmentMessageTile & ChatContextWidget (tokens, shimmer, Semantics) | @Pixel, @Sentinel |
| 7 | Notifications (skeleton, stagger, tiles, **StatefulWidget conversion** for badge) | @Pixel, @Sentinel |
| 8 | Dashboard Screen & ActivityFeed (tokens, timeline, stagger) | @Pixel, @Sentinel |
| 9 | Work Tab & Bookings Tab (tokens, empty states, **dimming preserved at 0.7**, skeleton) | @Pixel, @Sentinel |
| 10 | Skeleton Updates (dimension alignment) | @Pixel, @Sentinel |
| 10A | **Widget Tests** (NEW — grouping, separators, badge states, notification skeleton) | @Sentinel, @Pixel |
| 11 | QA & Verification (analyze, test, architecture guard, token audit, visual) | @Sentinel, @CodeGuard |
| 12 | Documentation Sync | @SlineDocs |

### Corrected Phase 0 (added 0.4):

#### 0.4 Stagger Pattern Lock (NEW)
**Primary Agent(s):** `@Pixel`, `@Architect`
- [ ] (`@Architect`) Document the canonical stagger pattern from auth screens:
  - Single `AnimationController` per screen (duration: `AppMotion.emphasis` or `AppMotion.standard`)
  - Per-element `Animation<Offset>` + `Animation<double>` pairs using `Interval` curves
  - `CurvedAnimation` with `AppMotion.curveDecel`
  - Trigger via `WidgetsBinding.instance.addPostFrameCallback`
  - Guard: `_hasAnimatedEntrance` bool to prevent replay on back-navigation
  - Reference: `lib/features/auth/view/login_screen.dart` lines 47-152
- [ ] (`@Architect`) Confirm all 4 stagger targets (messages_screen, notifications_modal, activity_feed_preview, chat conversation list) will use this pattern.
- [ ] (`@Sentinel`) Verify pattern reference file exists and is unchanged from Phase 2.
- **GATE CHECK:** Stagger pattern documented and locked. All 4 targets will use same implementation.

### Corrected Phase 2.3 (unread badge):

#### 2.3 Unread Indicator Enhancement (`@Pixel` | Skill: `delight`)
- [ ] (`@Pixel` | Skill: `delight`) Replace 12x12 dot with enhanced boolean indicator: 10px filled circle using `colorScheme.primary` with subtle glow/border, OR a "New" text label in `AppTypography.micro`.
- [ ] (`@Pixel` | Skill: `animate`) Indicator entrance: scale from 0→1 with `AppMotion.curveSpring` and `AppMotion.fast` duration.
- [ ] (`@Pixel` | Skill: `normalize`) Use `_isUnread()` boolean — do NOT assume numeric `unreadCount` exists.
- [ ] (`@Sentinel`) Verify indicator renders correctly for read/unread states.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Unread indicator is boolean, prominent, and animated.
- **FUTURE:** Numeric unread count badge logged as enhancement requiring Conversation model + ChatViewModel changes.

### Corrected Phase 3 (was Phase 4 — MessageBubble):

#### Phase 3: MessageBubble — Grouping API & Polish (MOVED UP)

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Update MessageBubble API with grouping params and polish visuals BEFORE ChatScreen consumes it.
**Why:** ChatScreen needs MessageBubble to accept `isFirstInGroup`/`isLastInGroup` for grouping computation. Bubble API must be stable first.
**How:** Add new optional params with defaults (backward compatible). Normalize tokens. Add Semantics.
**Result:** MessageBubble has stable API. All 3 instantiation sites in ChatScreen still compile (params are optional with defaults).

Sub-phases unchanged from original Phase 4 (4.1, 4.2, 4.3) but with added flutter analyze gate.

### Corrected Phase 4 (was Phase 3 — ChatScreen):

#### Phase 4: ChatScreen — Message List & Input Bar (MOVED DOWN)

Added sub-phases:

#### 4.2 Message Grouping & Date Separator Computation (`@Pixel` | Skill: `arrange`)
- [ ] (`@Pixel` | Skill: `arrange`) Create `_ChatListItem` sealed class or enum: either `message(Message, {isFirstInGroup, isLastInGroup})` or `dateSeparator(DateTime)`.
- [ ] (`@Pixel` | Skill: `arrange`) Create `List<_ChatListItem> _buildChatItems(List<Message> messages)` method that:
  - Sub-step 4.2.1: Iterates messages in chronological order.
  - Sub-step 4.2.2: Inserts `dateSeparator` at day boundaries (comparing `message.createdAt.toLocal().day`).
  - Sub-step 4.2.3: Computes `isFirstInGroup`: true if previous item is a separator, or previous message has different `senderId`, or time gap > 2 minutes.
  - Sub-step 4.2.4: Computes `isLastInGroup`: true if next item is a separator, or next message has different `senderId`, or time gap > 2 minutes, or is last message.
- [ ] (`@Pixel` | Skill: `arrange`) Update ListView.builder `itemCount` to use `_chatItems.length` and `itemBuilder` to switch on item type.
- [ ] (`@Sentinel`) Verify: single message renders as both first AND last in group. Two consecutive same-sender messages within 2 min group correctly. Messages across day boundary get separator.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Grouping computation correct. Date separators appear at day boundaries. MessageBubble receives correct grouping flags.

#### 4.5 Scroll-to-Bottom FAB (updated with keyboard awareness)
- [ ] (`@Pixel` | Skill: `delight`) Add a small FAB (36px) that appears when user scrolls up more than 2 screen heights from bottom.
- [ ] (`@Pixel` | Skill: `animate`) FAB entrance: slide up + fade in with `AppMotion.standard`, `AppMotion.curveDecel`.
- [ ] (`@Pixel` | Skill: `animate`) FAB exit: slide down + fade out with `AppMotion.fast`, `AppMotion.curveAccel`.
- [ ] (`@Pixel` | Skill: `harden`) **Keyboard awareness:** Hide FAB when `MediaQuery.viewInsets.bottom > 0` (keyboard open). OR position FAB above input bar using bottom inset calculation.
- [ ] (`@Pixel` | Skill: `delight`) Tap FAB scrolls to bottom with `AppMotion.emphasis` duration.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics(button: true, label: 'Scroll to latest messages')`.
- [ ] (`@Sentinel`) Verify FAB does not overlap keyboard or input bar.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** FAB works correctly and is keyboard-aware.

### Corrected Phase 7.3 (NotificationBadgeButton):

#### 7.3 NotificationBadgeButton (`@Pixel` | Skill: `animate`)
- [ ] (`@Pixel` | Skill: `normalize`) **Convert StatelessWidget to StatefulWidget** with `SingleTickerProviderStateMixin`. Move `Consumer<NotificationViewModel>` logic into `build()` of new State class.
- [ ] (`@Pixel` | Skill: `normalize`) Replace hardcoded `Positioned(-4, -4)` with calculated offset.
- [ ] (`@Pixel` | Skill: `normalize`) Replace 16x16 badge with consistent min-size token.
- [ ] (`@Pixel` | Skill: `animate`) Add `AnimationController` for pulse. Trigger pulse on `unreadCount` change (use `didUpdateWidget` or watch previous count in build).
- [ ] (`@Pixel` | Skill: `animate`) Badge entrance: scale from 0→1 with `AppMotion.curveSpring`, `AppMotion.fast`.
- [ ] (`@Pixel` | Skill: `animate`) Pulse: scale 1.0→1.1→1.0, `AppMotion.fast`, repeat 2 times on count change.
- [ ] (`@Pixel` | Skill: `harden`) Add `Semantics(label: 'Notifications${unreadCount > 0 ? ", $unreadCount unread" : ""}')`.
- [ ] (`@Pixel` | Skill: `harden`) Dispose AnimationController in `dispose()`.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** NotificationBadgeButton is StatefulWidget with pulse animation. Consumer pattern preserved.

### Corrected Phase 9.1 (Work Tab — dimming preserved):

#### 9.1 Work Tab Token Replacement (`@Pixel` | Skill: `normalize`)
- [ ] (`@Pixel` | Skill: `normalize`) Replace `Container(height: 40)` with `AppLayout.statusIndicatorHeight`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `BorderRadius.circular(AppDimens.r10)` with direct usage.
- [ ] (`@Pixel` | Skill: `normalize`) **KEEP** `Opacity(opacity: isDimmed ? 0.7 : 1.0)` — this is intentional design dimming for historical items, NOT the disabled state (0.38). Do NOT replace with `AppInteractionStates.disabledOpacity`.
- [ ] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(height: 0.5 * screenHeight)` empty state with responsive approach.
- [ ] (`@Pixel` | Skill: `normalize`) Verify all spacing uses AppDimens tokens correctly.
- [ ] (`@Sentinel`) Verify no raw hardcoded values remain (except intentional 0.7 dimming).
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Work Tab tokens normalized. Dimming preserved at 0.7.

### New Phase 10A: Widget Tests

#### Phase 10A: Widget Tests (NEW)

**Primary Agent(s):** `@Sentinel`, `@Pixel`
**Goal:** Add widget tests for new behavior introduced in this phase.
**Why:** 17 files modified with new params (MessageBubble grouping), new rendering (date separators, typing dots, badge animations). Zero existing tests for these behaviors. Edge cases in grouping logic and date computation need automated coverage.
**How:** Create 5-8 widget tests covering critical new behavior.
**Result:** New test files in `test/widget/chat/` and `test/widget/notifications/`.

#### 10A.1 MessageBubble Grouping Tests (`@Sentinel`)
- [ ] (`@Sentinel`) Test: Single message renders with `isFirstInGroup: true, isLastInGroup: true`.
- [ ] (`@Sentinel`) Test: Two same-sender messages within 2 min → first has `isLastInGroup: false`, second has `isFirstInGroup: false`.
- [ ] (`@Sentinel`) Test: Two same-sender messages > 2 min apart → both are standalone groups.
- [ ] (`@Sentinel`) Test: Different sender breaks grouping regardless of time.
- **GATE CHECK:** 4 grouping tests pass.

#### 10A.2 Date Separator Tests (`@Sentinel`)
- [ ] (`@Sentinel`) Test: Messages on same day have no separator between them.
- [ ] (`@Sentinel`) Test: Messages on different days have a separator with correct label ("Today", "Yesterday", or date).
- **GATE CHECK:** 2 separator tests pass.

#### 10A.3 Notification Skeleton Test (`@Sentinel`)
- [ ] (`@Sentinel`) Test: NotificationsModal shows skeleton loaders when `isLoading: true`.
- [ ] (`@Sentinel`) Test: NotificationsModal shows content when `isLoading: false`.
- **GATE CHECK:** 2 notification tests pass.

#### 10A.4 Test Suite Verification (`@Sentinel`)
- [ ] (`@Sentinel`) Run `flutter test` — all existing + new tests pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** 8+ new tests pass. Zero regressions.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- Phase ordering puts ChatScreen before MessageBubble (dependency inversion)
- Unread badge assumes `unreadCount` field that doesn't exist in model
- Work Tab dimming replacement would break visual design (0.7→0.38)
- Stagger animation pattern not specified (4 implementations could diverge)
- NotificationBadgeButton conversion from StatelessWidget not mentioned
- Zero widget tests for new behavior
- `flutter analyze` only at final QA phase
- Scroll-to-bottom FAB not keyboard-aware

### 2. Added Steps
- **Phase 0.4:** Stagger Pattern Lock (5 steps)
- **Phase 4.2:** Message Grouping & Date Separator Computation (5 steps with 4 sub-steps)
- **Phase 4.5:** Keyboard-aware FAB positioning (1 new step)
- **Phase 7.3:** StatelessWidget→StatefulWidget conversion (2 new steps)
- **Phase 10A:** Widget Tests (entire new phase, 10 steps)
- **All phases:** `flutter analyze` added to every GATE CHECK

### 3. Removed Steps
- **Phase 9.1:** Removed "Replace 0.7 with AppInteractionStates.disabledOpacity" — wrong constant

### 4. Reordered Steps
- **Phase 3 (MessageBubble) ↔ Phase 4 (ChatScreen)** — swapped to resolve dependency
- Original Phase 3 → now Phase 4 (ChatScreen depends on MessageBubble)
- Original Phase 4 → now Phase 3 (MessageBubble API must be stable first)

### 5. Expanded Steps
- **Phase 2.3 (Unread Badge):** Changed from numeric pill to boolean indicator with explicit scope note
- **Phase 4 (ChatScreen):** Split into explicit grouping computation sub-phase with sealed class pattern
- **Phase 7.3 (NotificationBadgeButton):** Expanded with conversion steps and dispose

### 6. Why
- **Ordering:** Prevents compile errors from consuming APIs that don't exist yet
- **Unread badge:** Prevents scope violation (model changes in a View-layer plan)
- **Dimming:** Prevents visual regression (completed items becoming invisible)
- **Stagger pattern:** Prevents inconsistency across 4 screens
- **Widget tests:** Prevents regressions in non-trivial grouping/separator logic
- **Analyze per phase:** Catches errors early, consistent with prior phase plans

### 7. Residual Risks
- **Date separator timezone sensitivity:** `createdAt.toLocal().day` may produce wrong boundaries if device timezone changes mid-conversation. Low probability, acceptable.
- **PR size:** 17 files + tests in one PR is large. Consider splitting into 2-3 commits (chat, notifications+dashboard) for reviewability.
- **Unread count enhancement deferred:** Boolean indicator is less informative than numeric count. Future phase needed for full unread count feature.
- **AnimationController lifecycle:** 4 new StatefulWidgets with AnimationControllers (messages_screen stagger, ChatScreen scroll FAB, NotificationBadgeButton pulse, notifications_modal stagger). Each must dispose correctly. Risk of memory leak if missed.

END.
