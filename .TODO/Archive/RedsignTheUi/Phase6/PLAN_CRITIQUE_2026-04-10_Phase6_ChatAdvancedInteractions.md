# Plan Critique: Phase 6 — Chat & Messaging Advanced Interactions

**Plan File:** `.TODO/PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md`
**Critic:** @PlanCritic
**Date:** 2026-04-10

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

1. `url_launcher: ^6.3.2` is already in `pubspec.yaml` — **CONFIRMED** (line 53).
2. OfferMessageBubble is currently a `StatelessWidget` — **CONFIRMED** (line 22 of file). Plan §5.2 says "convert to StatefulWidget if still StatelessWidget" — this WILL be needed.
3. Message model has `deliveredAt` and `seenAt` fields — **CONFIRMED**. Status rendering is already in ChatScreen (line 347-354).
4. `Conversation.presenceUpdatedAt` exists — **CONFIRMED** (line 29 of model).
5. MessagesScreen already uses `Dismissible` for swipe-to-delete (endToStart direction) — **CONFIRMED** (line 280-282). Phase 4's swipe-to-reply is on ChatScreen messages (different screen), so no gesture conflict.
6. ChatScreen's input bar is a `Positioned(bottom: 0)` widget returning `_buildInputArea` — **CONFIRMED** (line 451-455). Reply bar will need to be inserted inside `_buildInputArea` above the Row.
7. No `SafetyViewModel` Provider needed — it's already available from `main.dart` Provider tree (ChatScreen uses `context.read<SafetyViewModel>()`).
8. Existing tests: 3 tests in `test/widget/chat/chat_screen_test.dart` (T59-T61). These use `enableLifecycleEffects: false` to bypass subscriptions. New test must do the same.

### Decision Needed (Blocking)

**DECISION-1: Emoji regex strategy**
- **What:** Dart's `RegExp` supports `\p{Emoji}` only with `unicode: true`. But `\p{Emoji}` matches digits and `#`/`*` (Emoji_Component). The plan says "1-3 Unicode emoji" but doesn't define the regex.
- **Options:**
  1. Use `\p{Extended_Pictographic}` (excludes digits/symbols, matches visual emoji) — **Recommended**
  2. Use a hardcoded emoji range pattern (fragile, breaks with new Unicode versions)
  3. Use `characters` package to count grapheme clusters and check each against emoji properties
- **Recommended:** Option 1 — `RegExp(r'^(\p{Extended_Pictographic}[\p{Emoji_Modifier}\p{Emoji_Modifier_Base}\u{FE0F}\u{200D}]*){1,3}$', unicode: true)` with whitespace trim.
- **Plan impact:** Phase 3.2 Sub-step 3.2.1 must specify this exact regex and include test expectations.

**DECISION-2: Reply bar insertion point in the layout**
- **What:** The plan says "reply preview bar above input" but `_buildInputArea` is a `Positioned(bottom: 0)` widget. The reply bar must be INSIDE this Positioned (above the Row) or it will float separately.
- **Options:**
  1. Wrap the entire `_buildInputArea` in a Column: reply bar + existing input Row — **Recommended**
  2. Add a separate Positioned above the input area — fragile, needs manual bottom offset calculation
- **Recommended:** Option 1 — Column inside `_buildInputArea`.
- **Plan impact:** Phase 4.4 must specify that `_buildInputArea` returns a Column, not just the Row.

---

## B) Gate Status

| Gate | Status | Reason |
|------|--------|--------|
| 1. Data / Contracts Gate | ✅ PASS | No schema changes. All data already exposed by ChatViewModel. MVVM gaps documented. |
| 2. Security / RLS Gate | ✅ PASS | No backend changes. Link tapping uses `url_launcher.launchUrl()` which handles URL safety. |
| 3. Backend / Supabase Gate | ✅ PASS (N/A) | No Supabase work. No migration. |
| 4. UI / Integration Gate | ❌ FAIL | See GAP-1 through GAP-7 below. |
| 5. Release / QA Gate | ❌ FAIL | See GAP-5 and GAP-6. |

### UI / Integration Gate — FAIL Reasons:
1. Phase 3 (MessageBubble) bundles THREE independent concerns (links, emoji, reply quote) with no sub-phase separation — each needs its own flutter analyze gate.
2. Phase 4 (ChatScreen) is massive — swipe gesture, context menu, reply state, and reply bar are four independent features crammed into one phase. Swipe-to-reply depends on reply state which depends on reply bar — ordering is implicit.
3. Phase 5 (OfferMessageBubble) says "convert to StatefulWidget if still StatelessWidget" — it IS StatelessWidget (confirmed). This is not a "maybe" — it's a required step. Plan must include it explicitly with all constructor parameters carried forward.
4. Plan Phase 1 says "Add search bar, online dot" on MessagesScreen — but online dot is on ConversationListTile (Phase 2), not MessagesScreen. Files-to-Modify table incorrectly lists online dot in MessagesScreen.
5. No widget tests planned for ANY new feature (search, swipe, link, emoji, fullscreen). Phase 5 set a 17-test baseline. Adding 0 tests for 7 files of new interaction logic is a regression in quality discipline.
6. Phase 3.1 says "URL spans wrapped in TapGestureRecognizer" — `TapGestureRecognizer` must be disposed. Plan doesn't mention disposal.
7. Emoji regex not specified (see DECISION-1).
8. Reply bar insertion point not specified (see DECISION-2).

### Release / QA Gate — FAIL Reasons:
1. No widget tests for new features.
2. Phase 8.4 functional QA is a checklist of "verify X" but no evidence artifacts (screenshots, test IDs).

---

## C) Critical Gaps (Must-Fix)

### GAP-1: Phase 3 bundles three independent features into one phase
**Why it will break:** An executor implementing link detection, emoji-only, and reply quote in one pass will produce a massive diff with interleaved changes. A bug in emoji regex could block link detection work. They are independent features on the same widget.
**Fix:** Split Phase 3 into three sub-phases: 3A (Link Detection), 3B (Emoji-Only), 3C (Reply Quote Visual). Each has its own GATE CHECK with `flutter analyze`.
**Owner:** Frontend
**Acceptance check:** Each sub-phase can be committed independently.

### GAP-2: Phase 4 bundles four features — dependency order is implicit
**Why it will break:** Reply preview bar and swipe-to-reply both need `_replyTarget` state. If the executor builds swipe first but forgets the state, swipe has no effect. Context menu needs the same state. Order matters.
**Fix:** Split Phase 4 into: 4A (Reply State + Reply Preview Bar — the foundation), 4B (Swipe-to-Reply gesture — depends on 4A), 4C (Long-Press Context Menu — depends on 4A). State must be built first.
**Owner:** Frontend
**Acceptance check:** 4A builds and shows the reply bar when `_replyTarget` is manually set. 4B triggers it via swipe. 4C triggers it via menu.

### GAP-3: OfferMessageBubble StatelessWidget → StatefulWidget conversion is conditional in plan but required in reality
**Why it will break:** The plan says "Convert to StatefulWidget if still StatelessWidget" — this is the wrong framing. It IS a StatelessWidget (confirmed by scan). The plan must include explicit steps for the conversion, carrying all 13 constructor parameters, preserving the build method, adding the AnimationController for border transitions, and updating the test file.
**Fix:** Phase 5 must have an explicit sub-phase 5.0: StatelessWidget → StatefulWidget conversion with checklist of all parameters and test update.
**Owner:** Frontend
**Acceptance check:** `OfferMessageBubble` is a `StatefulWidget`, existing tests still pass.

### GAP-4: TapGestureRecognizer disposal missing for link detection
**Why it will break:** `RichText` with `TapGestureRecognizer` leaks memory if recognizers are not disposed. Every time the widget rebuilds, new recognizers are created. In a `StatelessWidget` (MessageBubble), there's no `dispose()` method.
**Fix:** Two options: (a) Convert MessageBubble to StatefulWidget to manage recognizer lifecycle, or (b) use `GestureDetector` wrapping individual text spans instead of `TapGestureRecognizer`. Option (b) is simpler — use `InkWell` or `GestureDetector` on a `WidgetSpan` instead. Or (a) convert to StatefulWidget. Plan must specify which approach and include disposal.
**Owner:** Frontend
**Acceptance check:** No memory leak from link tapping. Recognizers disposed or avoided.

### GAP-5: Zero widget tests for new features
**Why it will break:** Phase 5 established a 17-test baseline for chat widgets. This phase adds 7 features (search, online dot, relative time, links, emoji, swipe, fullscreen) with 0 tests. The next phase will inherit untested interaction code.
**Fix:** Add a dedicated test phase after implementation. Minimum tests: (1) search filters conversations, (2) emoji-only renders without bubble, (3) link detection produces RichText, (4) reply bar shows when replyTarget set, (5) relative time formats correctly. 5 tests minimum.
**Owner:** Frontend
**Acceptance check:** `flutter test` passes with 5+ new tests.

### GAP-6: Files-to-Modify table lists "online dot" under MessagesScreen
**Why it will break:** The executor will look for online dot code in `messages_screen.dart` but it belongs in `conversation_list_tile.dart`. Wasted time and confusion.
**Fix:** Remove "online dot" from MessagesScreen action column. MessagesScreen only gets the search bar.
**Owner:** Plan
**Acceptance check:** Each file's action column matches only changes to that file.

### GAP-7: Fullscreen image viewer creates a new route inside AttachmentMessageTile — no reusable pattern
**Why it will break:** If other screens need fullscreen image viewing later (portfolio, task images), they'll re-implement. Also, the `Navigator.push` from inside a widget buried in the chat tree could have context issues.
**Fix:** Extract fullscreen viewer into a shared utility: `lib/core/widgets/fullscreen_image_viewer.dart` (a static `show()` method that takes `imageUrl`, `heroTag`, `caption`). AttachmentMessageTile calls this utility. Phase 6 must create the shared widget FIRST, then wire it.
**Owner:** Frontend
**Acceptance check:** `FullscreenImageViewer.show()` exists as reusable. AttachmentMessageTile calls it.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to Enforce | How to Verify |
|-----------|---------------|---------------|
| No View imports or calls Supabase directly | Code review. Grep for `supabase_flutter` in modified view files. | `grep -r "import.*supabase_flutter" lib/features/chat/view/` returns only `attachment_message_tile.dart` (pre-existing). |
| No ViewModel modifications | `git diff` on `chat_view_model.dart` must be empty. | Byte-identical check. |
| AppLogger used, no `print()` | Grep for `print(` in modified files. | 0 matches. |
| Design tokens only — no hardcoded colors/durations/sizes | Grep for `Color(0x`, `Duration(milliseconds:`, raw `fontSize:`, raw `BoxShadow(`. | 0 new matches in modified files. |
| All new parameters backward-compatible | MessageBubble's `replyToText`/`replyToSender` are optional with null defaults. | Existing call sites compile unchanged. |
| TapGestureRecognizer disposal | If used, must be in StatefulWidget with `dispose()` override. | Code review or avoidance via WidgetSpan approach. |
| Existing Phase 5 features work | Stagger entrance, grouping, FAB, typing dots, date separators. | `flutter test` baseline unchanged. Visual regression check. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Emoji regex false positives (digits, symbols) | MessageBubble | HIGH | MEDIUM | Single widget | Test with "123", "#", "*" | Use `\p{Extended_Pictographic}` not `\p{Emoji}` | Revert to plain bubble for all messages |
| Swipe gesture conflicts with ListView scroll | ChatScreen | MEDIUM | HIGH | Chat unusable | Horizontal swipe locks vertical scroll | Set drag threshold (>40px horizontal before activating) | Remove swipe, keep long-press menu as only reply trigger |
| TapGestureRecognizer memory leak | MessageBubble | HIGH if StatelessWidget | MEDIUM | Chat performance degrades over session | Growing memory in profiler | Convert to StatefulWidget OR use WidgetSpan approach | Remove link tapping, keep visual styling only |
| Fullscreen viewer Hero tag collision | AttachmentMessageTile | LOW | LOW | Animation glitch | Two images with same path | Use `storagePath + timestamp` as unique hero tag | Disable Hero, use simple push |
| OfferMessageBubble conversion breaks tests | OfferMessageBubble | MEDIUM | MEDIUM | 9 tests fail | Test run after conversion | Carry all parameters, keep build() logic intact | Skip animation, keep StatelessWidget with AnimatedContainer |
| Search bar keyboard covers conversation list | MessagesScreen | MEDIUM | LOW | UX annoyance | Test on small device | `resizeToAvoidBottomInset: true` on Scaffold | Add `ScrollController.animateTo` when search focuses |
| Relative time shows "Just now" for old messages on first render | ConversationListTile | LOW | LOW | Stale display | Visual check | Use `lastMessageTime` not `presenceUpdatedAt` for time display | Fall back to absolute time |

---

## F) Pre-Mortem (How This Fails In Real Life)

1. **This fails when** the executor builds link detection using `TapGestureRecognizer` in the StatelessWidget `MessageBubble`, doesn't dispose them, and the chat screen leaks memory after scrolling through 100+ messages with URLs.

2. **This fails when** the emoji regex uses `\p{Emoji}` and renders numbers "1", "2", "3" as 2x-sized emoji-only messages because digits are in the Emoji_Component Unicode category.

3. **This fails when** the executor builds swipe-to-reply before building the reply state and preview bar, resulting in a swipe gesture that triggers `_setReplyTarget` on a non-existent field and crashes.

4. **This fails when** the OfferMessageBubble StatelessWidget → StatefulWidget conversion drops one of the 13 constructor parameters (e.g., `onComplete`) and the test for completed-offer state silently breaks.

5. **This fails when** the search bar `TextField` steals focus on screen entry because `autofocus: true` was accidentally set, and every time the user navigates to Messages they see the keyboard.

6. **This fails when** the online status green dot uses `presenceUpdatedAt` which is only non-null when presence/receipts feature flag is enabled — if the flag is off, the dot NEVER shows, even for truly online users.

7. **This fails when** the fullscreen image viewer pushes a new route but the Hero animation fails because `CachedNetworkImage` rebuilds with a different key on the destination route, causing a flash instead of a smooth transition.

8. **This fails when** the reply preview bar inside `_buildInputArea` pushes the input row below the bottom safe area because the `MediaQuery.of(context).padding.bottom` padding was calculated for the Row alone, not the Column.

9. **This fails when** the long-press context menu appears behind the chat header because the `showMenu`/`showModalBottomSheet` Z-order conflicts with the Positioned header overlay in the Stack.

10. **This fails when** the conversation search debounce timer fires after the user navigates away from MessagesScreen, calling `setState` on an unmounted widget.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### FIX-1: Split Phase 3 into three sub-phases
- **Goal:** Isolate link detection, emoji-only, and reply quote into independent, committable units.
- **Why:** Three unrelated features in one phase means one bug blocks all three. They touch the same file but different code paths.
- **How:** Phase 3A = Link Detection (RichText + url_launcher + disposal), Phase 3B = Emoji-Only (regex + conditional rendering), Phase 3C = Reply Quote (optional params + quote widget). Each has GATE CHECK.
- **Output artifact:** Three independent diffs that can be reviewed/reverted separately.
- **Stop condition:** Each sub-phase passes `flutter analyze` independently.

### FIX-2: Split Phase 4 into dependency-ordered sub-phases
- **Goal:** Enforce correct build order: state first, then gestures that use the state.
- **Why:** Swipe-to-reply and context menu both depend on `_replyTarget` state and reply bar. Building gestures before state = crash.
- **How:** Phase 4A = Reply State + Reply Preview Bar (the foundation), Phase 4B = Swipe-to-Reply (depends on 4A), Phase 4C = Long-Press Context Menu (depends on 4A).
- **Output artifact:** Reply bar works when state is manually set (4A). Swipe triggers state (4B). Menu triggers state (4C).
- **Stop condition:** Each sub-phase builds on the previous. 4A can ship alone.

### FIX-3: Explicit OfferMessageBubble conversion step
- **Goal:** Remove ambiguity about StatelessWidget → StatefulWidget conversion.
- **Why:** Plan says "if" but code says it IS StatelessWidget. Conversion is required, not conditional.
- **How:** Add Phase 5.0: Convert OfferMessageBubble to StatefulWidget. Carry all 13 parameters. Add AnimationController in `initState`. Verify 9 existing tests pass.
- **Output artifact:** `OfferMessageBubble extends StatefulWidget` with identical API.
- **Stop condition:** 9 existing OfferMessageBubble tests pass unchanged.

### FIX-4: Specify TapGestureRecognizer disposal strategy
- **Goal:** Prevent memory leak from link detection.
- **Why:** `TapGestureRecognizer` in a StatelessWidget = leak.
- **How:** Convert MessageBubble to StatefulWidget. Create recognizers in `_initRecognizers()` called from `didUpdateWidget`. Dispose in `dispose()`. OR: avoid TapGestureRecognizer entirely — use `GestureDetector` wrapping `WidgetSpan` in `Text.rich`. Plan must specify which approach.
- **Output artifact:** No memory leak. Recognizers managed or avoided.
- **Stop condition:** Profiler shows stable memory during scroll through 100+ messages with links.

### FIX-5: Add widget test phase
- **Goal:** Maintain test quality discipline from Phase 5.
- **Why:** 7 new features with 0 tests = quality regression.
- **How:** Add Phase 8A (before Phase 8B QA) with 5 minimum tests: (1) search filters conversations, (2) emoji-only renders without Container, (3) link detection produces tappable spans, (4) reply bar shows when replyTarget set, (5) relative time formats correctly.
- **Output artifact:** 5+ new test files/cases in `test/widget/chat/`.
- **Stop condition:** `flutter test test/widget/chat/` passes with 5+ new tests.

### FIX-6: Fix Files-to-Modify table
- **Goal:** Accurate file-action mapping.
- **Why:** "online dot" is not in MessagesScreen.
- **How:** MessagesScreen action = "Add search bar". Online dot is in ConversationListTile (already correct there).
- **Output artifact:** Corrected table.
- **Stop condition:** Each action maps to the correct file.

### FIX-7: Extract FullscreenImageViewer to core/widgets
- **Goal:** Reusable fullscreen image viewer.
- **Why:** Portfolio, task images, and profile photos will need the same viewer. Building it inside AttachmentMessageTile makes it non-reusable.
- **How:** Create `lib/core/widgets/fullscreen_image_viewer.dart` with `static Future<void> show(BuildContext context, {required String imageUrl, String? heroTag, String? caption})`. Then wire AttachmentMessageTile to call it.
- **Output artifact:** Reusable `FullscreenImageViewer` in core/widgets.
- **Stop condition:** Widget exists, is imported by AttachmentMessageTile, `flutter analyze` clean.

### FIX-8: Add mounted guard for search debounce timer
- **Goal:** Prevent `setState` on unmounted widget.
- **Why:** Debounce timer fires after user navigates away = crash.
- **How:** In `_MessagesScreenState.dispose()`, cancel the debounce timer. In the timer callback, check `if (!mounted) return;` before `setState`.
- **Output artifact:** Timer cancelled in dispose, mounted check in callback.
- **Stop condition:** No crash on rapid navigate-away during search typing.

### FIX-9: Add presence feature flag check for online dot
- **Goal:** Online dot only shows when presence/receipts feature flag is enabled.
- **Why:** `presenceUpdatedAt` is only populated when `chat_presence_receipts_enabled` flag is true. If flag is off, the field is always null, and the dot never shows — but the plan doesn't document this dependency.
- **How:** Phase 2.1 must include a step to check `ChatViewModel.isPresenceReceiptsEnabled` and only show the online dot when true. Add a comment explaining the feature flag dependency.
- **Output artifact:** Online dot gated behind feature flag check + comment.
- **Stop condition:** Dot hidden when flag is off, visible when flag is on and presence is recent.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

The corrected plan is written inline into the plan file. See below for the full rewrite.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- Phase 3 bundled 3 independent features (links, emoji, reply quote)
- Phase 4 bundled 4 features with implicit dependency order
- OfferMessageBubble conversion was conditional but is required
- TapGestureRecognizer disposal not addressed
- Zero widget tests planned
- Files-to-Modify table had incorrect action for MessagesScreen
- Fullscreen viewer not reusable
- Search debounce timer not guarded for unmount
- Online dot not gated behind presence feature flag

### 2. Added Steps
- Phase 3 split into 3A, 3B, 3C with independent GATE CHECKs
- Phase 4 split into 4A, 4B, 4C with dependency order enforced
- Phase 5.0: Explicit StatelessWidget → StatefulWidget conversion for OfferMessageBubble
- Phase 3A: TapGestureRecognizer disposal strategy (convert MessageBubble to StatefulWidget)
- Phase 6 split: 6A creates `FullscreenImageViewer` in core/widgets, 6B wires it to AttachmentMessageTile
- Phase 8A: 5+ widget tests for new features
- Phase 1: Debounce timer disposal + mounted guard
- Phase 2: Presence feature flag gate for online dot
- DECISION-1 resolved: Emoji regex specified as `\p{Extended_Pictographic}`
- DECISION-2 resolved: Reply bar inside `_buildInputArea` Column

### 3. Removed Steps
- None removed

### 4. Reordered Steps
- Phase 3: was one phase → split into 3A (links), 3B (emoji), 3C (reply quote)
- Phase 4: was one phase → split into 4A (state+bar), 4B (swipe), 4C (menu)
- Phase 6: was one phase → split into 6A (shared widget), 6B (wire to attachment)

### 5. Expanded Steps
- Phase 3A: Added MessageBubble StatelessWidget → StatefulWidget conversion for recognizer disposal
- Phase 4A: Specified `_buildInputArea` returns Column (reply bar + input Row)
- Phase 5.0: Added explicit constructor parameter list (13 params) for OfferMessageBubble conversion
- Phase 1: Added debounce timer cancel in dispose(), mounted guard

### 6. Why
Every fix addresses a concrete failure mode identified in the Pre-Mortem or a gate failure. The plan was well-structured at the phase level but under-decomposed at the sub-phase level for the three largest phases (3, 4, 6).

### 7. Residual Risks
- Emoji regex may still miss edge cases with ZWJ sequences (family emoji, flags). Mitigation: test with 10+ emoji types.
- Swipe gesture threshold (40px) may feel too sensitive or too sluggish on different device sizes. Mitigation: test on both small and large screens.
- Online dot heuristic (60s) may show false positives for users who closed the app <60s ago. Acceptable for MVP.
- Hero animation with `CachedNetworkImage` may flash on slow networks. Mitigation: pre-cache the image before pushing the route.

END.
