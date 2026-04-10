# Plan: Phase 6 — Chat & Messaging Advanced Interactions (Critique-Corrected)

> **Critique applied:** `.TODO/PLAN_CRITIQUE_2026-04-10_Phase6_ChatAdvancedInteractions.md`
> **Fixes applied:** FIX-1 through FIX-9 (Phase 3 split, Phase 4 split, OfferMessageBubble explicit conversion, TapGestureRecognizer disposal, widget tests added, files-to-modify table corrected, FullscreenImageViewer extracted to core, debounce timer guard, presence feature flag gate for online dot).

## 1) Goal
- **Goal:** Deliver the remaining Master Plan Phase 6 features that were NOT completed in Phase 5 (token normalization pass). Phase 5 established design-token compliance, message grouping, date separators, animated send button, scroll-to-bottom FAB, stagger entrance, typing dots, spring badge, and Semantics. This plan covers the **advanced interaction layer**: search, swipe-to-reply, long-press context menu, link detection, emoji-only messages, improved message status UX, and offer bubble visual elevation.
- **Why:** The chat experience is now token-compliant and accessible (Phase 5) but still lacks the premium interaction features described in Master Plan §6.1–6.5. Users cannot search conversations, reply to specific messages, copy message text, detect links, or see emoji-only messages at larger scale. These features elevate chat from "functional" to "messaging excellence."
- **Result:** 7 chat view-layer files enhanced + 1 new shared core widget (`FullscreenImageViewer`). Search, swipe-to-reply, long-press context menu, link detection, emoji-only rendering, fullscreen images, and offer bubble visual polish. All changes are View-layer only — no ViewModel, Service, Repository, or Backend modifications. Missing backend capabilities (reply storage, message delete RPC) are documented as gaps with placeholder UI. 5+ new widget tests.

## 2) Scope

### In-Scope
- **MessagesScreen** (424 lines): Add conversation search/filter bar at top
- **ChatScreen** (989 lines): Swipe-to-reply gesture, long-press context menu (copy/reply), reply preview bar above input
- **MessageBubble** (197 lines): Convert to StatefulWidget for recognizer lifecycle; link detection (tappable URLs), emoji-only rendering (1-3 emoji without bubble), reply quote visual
- **ConversationListTile** (404 lines): Online status green dot on avatar (gated behind presence feature flag), relative time formatting ("Just now", "2m", "1h", "Yesterday")
- **OfferMessageBubble** (488 lines): Convert StatelessWidget → StatefulWidget; elevated card treatment (Level 2 shadow), gold/teal accent border by status, status-change border animation
- **AttachmentMessageTile** (400 lines): Tap-to-fullscreen via shared `FullscreenImageViewer`
- **ChatContextWidget** (157 lines): Minor polish — task pill styling
- **NEW: `lib/core/widgets/fullscreen_image_viewer.dart`**: Reusable fullscreen image viewer with Hero animation, pinch-to-zoom, swipe-to-dismiss

### Out-of-Scope
- Backend changes (no new RPC, no schema changes, no new columns)
- ViewModel changes (ChatViewModel stays unchanged — 767 lines)
- Service/Repository changes (MessageService, ChatRepository untouched)
- Reply storage (requires `reply_to_message_id` column — documented as gap)
- Message deletion from server (requires `delete_message` RPC — documented as gap)
- Read receipts visual (already partially implemented via presence)
- Push notification changes
- Any Phase 7+ work (Dashboard, Booking, Profile)

### MVVM Gap Documentation
These Master Plan §6.3 features require backend/ViewModel support not yet available:
1. **Swipe-to-reply message storage**: Needs `reply_to_message_id` column in `messages` table + MessageService update + ChatViewModel.sendReply(). View can show reply UI but reply-to-id won't persist.
2. **Message delete from server**: Needs `delete_message` RPC with ownership check. View can show delete option but only removes locally.
3. **Optimistic send with status transitions**: `sending → sent → delivered → read` requires delivery receipt tracking beyond current presence feature flag. View can show `sent` status but delivery/read transitions depend on backend.
4. **Online status (green dot)**: Presence data exists (`otherUserTyping`, `presenceUpdatedAt`) but no explicit `isOnline` field. Will use `presenceUpdatedAt` within 60s as heuristic, **gated behind `isPresenceReceiptsEnabled` feature flag** — dot is hidden when flag is off.

### Decisions Resolved (From Critique)

**DECISION-1 (Emoji regex):** Use `\p{Extended_Pictographic}` (not `\p{Emoji}`) with `unicode: true`. `\p{Emoji}` matches digits and `#`/`*` which are Emoji_Component. `\p{Extended_Pictographic}` matches only visual emoji. Regex: `RegExp(r'^\s*(\p{Extended_Pictographic}[\u{FE0F}\u{200D}\p{Extended_Pictographic}]*\s*){1,3}\s*$', unicode: true)`.

**DECISION-2 (Reply bar insertion):** The reply bar goes INSIDE `_buildInputArea`. Convert `_buildInputArea` to return a `Column(children: [replyBar, inputRow])` wrapped in the existing `AppCardContainer`. This keeps the reply bar and input together in the same Positioned(bottom: 0) slot.

## 3) Files To Read & Modify (Explicit list for Executor)

### View Files (Modify)
| File | Lines | Action |
|------|-------|--------|
| `lib/features/chat/view/messages_screen.dart` | 424 | Add search bar with debounced filtering + timer disposal guard |
| `lib/features/chat/view/chat_screen.dart` | 989 | Reply state + reply preview bar (4A), swipe-to-reply (4B), long-press context menu (4C) |
| `lib/features/chat/view/widgets/message_bubble.dart` | 197 | Convert to StatefulWidget; link detection (3A), emoji-only (3B), reply quote (3C) |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | 404 | Online dot (gated by feature flag) + relative time |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | 488 | Explicit StatelessWidget → StatefulWidget conversion; elevated card + status border animation |
| `lib/features/chat/view/widgets/attachment_message_tile.dart` | 400 | Wire to shared FullscreenImageViewer |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | 157 | Task pill polish |

### New Files (Create)
| File | Action |
|------|--------|
| `lib/core/widgets/fullscreen_image_viewer.dart` | Reusable fullscreen viewer: `static Future<void> show(context, {imageUrl, heroTag, caption})` |

### Read-Only (Reference)
| File | Lines | Why |
|------|-------|-----|
| `lib/features/chat/viewmodels/chat_view_model.dart` | 767 | Verify available state for UI; confirm `isPresenceReceiptsEnabled` getter exists |
| `lib/features/chat/models/conversation_model.dart` | 154 | Verify fields: `presenceUpdatedAt`, `otherUserTyping` |
| `lib/features/chat/models/message_model.dart` | 206 | Verify fields: `content`, `senderId`, `createdAt`, `deliveredAt`, `seenAt` |
| `lib/core/theme/app_motion.dart` | 122 | Motion tokens |
| `lib/core/theme/app_states.dart` | 114 | Interaction state tokens + haptic helpers |
| `lib/core/theme/app_layout.dart` | 202 | Layout tokens |
| `lib/core/theme/app_colors.dart` | 440 | Color tokens (semantic success/warning/danger) |
| `lib/core/theme/app_decorations.dart` | 113 | `elevation()` method |
| `lib/core/theme/app_typography.dart` | 143 | Typography tokens |
| `lib/core/theme/app_dimens.dart` | 65 | Spacing/radius tokens |
| `lib/core/widgets/signed_avatar.dart` | ~150 | Avatar widget for Stack wrapping |
| `lib/core/utils/custom_route_transitions.dart` | ~50 | `FadeRoute` for fullscreen transition |
| `test/widget/chat/chat_screen_test.dart` | 150 | Existing test structure + fixture patterns |

## 4) System Impact Map
- **UI:** 7 view-layer files modified + 1 new shared widget. New interaction gestures (swipe, long-press, tap URL). No layout-breaking changes — additive features only.
- **MVVM / App Logic:** NONE. All changes are View-layer. ViewModels, Services, Repositories unchanged.
- **Database:** NONE.
- **RLS / Security:** NONE.
- **RPC / Edge Functions:** NONE.
- **Storage:** NONE.
- **Realtime / Notifications:** NONE (existing presence subscription reused for online dot).
- **Observability:** NONE (existing AppLogger calls sufficient).
- **Compatibility & Migration:** NONE. All new features are additive — existing message rendering unchanged for messages without links/emoji/replies. MessageBubble and OfferMessageBubble converted to StatefulWidget with identical public API (backward compatible).
- **Contracts:** NONE.

## 5) Agent Map
- **Phase 0 (Preconditions):** `@SlinePlanner`, `@Sentinel`
- **Phase 1 (MessagesScreen — Search):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 2 (ConversationListTile — Online Dot + Time):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 3A (MessageBubble — StatefulWidget + Link Detection):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 3B (MessageBubble — Emoji-Only):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 3C (MessageBubble — Reply Quote Visual):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 4A (ChatScreen — Reply State + Preview Bar):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 4B (ChatScreen — Swipe-to-Reply):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 4C (ChatScreen — Long-Press Context Menu):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 5 (OfferMessageBubble — Conversion + Elevation):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6A (FullscreenImageViewer — Shared Widget):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6B (AttachmentMessageTile — Wire Fullscreen):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (ChatContextWidget — Pill Polish):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 8A (Widget Tests):** `@Sentinel` (primary)
- **Phase 8B (QA + Verification):** `@Sentinel` (primary), `@CodeGuard` (review)
- **Phase 9 (Documentation Sync):** `@SlineDocs` (primary)

**Session Log:** `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md`

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

### 0.1 Spec Lock
- [ ] (`@Sentinel`) Acceptance criteria defined (see Section 7 below — 22 items).
- [ ] (`@Architect`) Confirm touched modules: 7 view files in `lib/features/chat/view/` + 1 new file in `lib/core/widgets/`.
- [ ] (`@Architect`) Confirm Phase 5 completion: all chat files already use design tokens (AppMotion, AppStates, AppColors semantic, AppLayout, AppDimens, AppTypography). No token work needed.
- [ ] (`@Sentinel`) Confirm MVVM gaps documented (Section 2 above): reply storage, message delete, delivery receipts, explicit online status.
- [ ] (`@Sentinel`) Confirm Decisions 1 and 2 resolved (emoji regex = `\p{Extended_Pictographic}`, reply bar inside `_buildInputArea` Column).
- **GATE CHECK:** Scope is 7 view files + 1 new shared widget. No ViewModel/Service/Backend changes. MVVM gaps documented. Decisions resolved.

### 0.2 Codebase Discovery Scan
- [ ] (`@Architect`) Grep `lib/` for all imports of chat view files — confirm no unexpected dependents beyond known list (main_navigation, booking_details, task_details, work_item_details, public_profile, favorites).
- [ ] (`@Architect`) Grep `lib/features/chat/` for any files added since Phase 5 that the plan doesn't cover.
- [ ] (`@Architect`) Confirm `url_launcher: ^6.3.2` is in `pubspec.yaml` (line 53 — **CONFIRMED** in critique scan).
- [ ] (`@Architect`) Confirm `ChatViewModel.isPresenceReceiptsEnabled` getter exists (for Phase 2 online dot gate).
- [ ] (`@Sentinel`) Report any discovered files that need inclusion.
- **GATE CHECK:** File list is complete. No surprise dependencies. `url_launcher` present.

### 0.3 Screenshot Collection
- [ ] (`@Pixel`) Request screenshots from user:
  - Sub-step 0.3.1: MessagesScreen — default state (conversations loaded, some unread)
  - Sub-step 0.3.2: MessagesScreen — empty state
  - Sub-step 0.3.3: ChatScreen — message list with mixed types (text, offer, attachment)
  - Sub-step 0.3.4: ChatScreen — empty state (new conversation)
  - Sub-step 0.3.5: ChatScreen — input bar focused with text
  - Sub-step 0.3.6: ConversationListTile — close-up showing avatar, name, preview, time, badge
  - Sub-step 0.3.7: OfferMessageBubble — pending, accepted, declined states
  - Sub-step 0.3.8: All above in both dark and light mode (16 screenshots total)
- [ ] (`@Sentinel`) Confirm screenshots received and analyzed before implementation begins.
- **GATE CHECK:** Visual context locked. Agent knows exact current appearance.

---

## Phase 1: MessagesScreen — Conversation Search Bar

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add a search/filter bar at the top of the conversation inbox that filters the existing conversation list by name or last message content.
**Why:** Users with many conversations need quick access. Master Plan §6.1 specifies "Search bar at top — filter conversations by name/keyword."
**How:** Add a `TextField` search bar above the conversation list. Filter is client-side only (filters `ChatViewModel.conversations` list by `otherUserName` or `lastMessage` contains query). No backend search needed.
**Result:** Functional search bar with debounced filtering, clear button, animated show/hide, and proper lifecycle cleanup.

### 1.1 Add Search Bar Widget
- [ ] (`@Pixel` | Skill: `arrange`) Add a search `TextField` at the top of the conversation list:
  - Sub-step 1.1.1: Add `TextEditingController _searchController`, `String _searchQuery = ''`, and `Timer? _searchDebounce` fields to `_MessagesScreenState`.
  - Sub-step 1.1.2: Use a styled `TextField` with `Icons.search` prefix icon and conditional `Icons.clear` suffix icon (shown when query is non-empty).
  - Sub-step 1.1.3: Style: `AppDimens.r14` border radius, `colorScheme.inputBackground`, placeholder "Search conversations...", `AppTypography.bodyMedium`.
  - Sub-step 1.1.4: Position: pinned above the conversation list in a non-scrolling `SliverToBoxAdapter` or outside the `CustomScrollView`.
  - Sub-step 1.1.5: **Do NOT set `autofocus: true`** — keyboard must not open on screen entry.
- [ ] (`@Pixel` | Skill: `animate`) Add show/hide animation:
  - Sub-step 1.1.6: Search bar slides down from top with `AppMotion.standard` (300ms) + `curveDecel`.
  - Sub-step 1.1.7: Triggered by a search icon button in the screen header (toggle `_showSearch` bool).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 1.2 Implement Client-Side Filtering
- [ ] (`@Pixel`) Add filtering logic to `_MessagesScreenState`:
  - Sub-step 1.2.1: `_filteredConversations` getter that filters `chatCtrl.conversations` by `otherUserName.toLowerCase().contains(query)` OR `lastMessage?.toLowerCase().contains(query)`.
  - Sub-step 1.2.2: Debounce filter updates by 300ms using `Timer`:
    ```dart
    void _onSearchChanged(String value) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return; // FIX-8: Guard against unmounted setState
        setState(() => _searchQuery = value.trim().toLowerCase());
      });
    }
    ```
  - Sub-step 1.2.3: Show "No results" empty state when filter returns empty list but conversations exist.
- [ ] (`@Pixel` | Skill: `harden`) Handle edge cases:
  - Sub-step 1.2.4: Empty query shows all conversations (no filter applied).
  - Sub-step 1.2.5: Query with only whitespace treated as empty.
  - Sub-step 1.2.6: Clear button resets query, clears TextField, unfocuses field.
- [ ] (`@Pixel`) **FIX-8: Timer disposal in `dispose()`:**
  - Sub-step 1.2.7: Add `_searchDebounce?.cancel();` and `_searchController.dispose();` to existing `dispose()` method.
- [ ] (`@Sentinel`) Verify stagger entrance still works correctly with filtered list.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Search bar visible, filtering works, stagger animation unbroken, no unmounted-setState risk.

---

## Phase 2: ConversationListTile — Online Status Dot + Relative Time

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add a green online indicator dot on the avatar (gated behind feature flag) and improve time display to use relative formatting.
**Why:** Master Plan §6.1 specifies "Online status: Green dot on avatars of online users" and §6.2 specifies relative time ("Just now", "2m", "1h", "Yesterday").
**How:** Use `Conversation.presenceUpdatedAt` within 60s heuristic for online status, gated by `ChatViewModel.isPresenceReceiptsEnabled`. Create a `_formatRelativeTime()` helper for time display.
**Result:** Avatar shows green dot when feature flag is on AND other user is "online" (active within 60s). Time shows human-readable relative format.

### 2.1 Online Status Dot
- [ ] (`@Pixel` | Skill: `delight`) Add green online indicator to avatar:
  - Sub-step 2.1.1: Wrap the `SignedAvatar` in a `Stack` with `Positioned` green dot.
  - Sub-step 2.1.2: Dot: 12px circle, `colorScheme.success`, 2px white border (`colorScheme.cardBackground`), positioned bottom-right of the avatar.
  - Sub-step 2.1.3: **FIX-9: Gate behind feature flag.** Determine "online" from TWO conditions:
    1. `context.watch<ChatViewModel>().isPresenceReceiptsEnabled` is `true` (feature flag)
    2. `conversation.presenceUpdatedAt` is non-null AND within 60 seconds of `DateTime.now()`
    Both must be true to show the dot. If feature flag is off, dot is NEVER shown.
  - Sub-step 2.1.4: Animate dot entrance: `AnimatedScale` with `AppMotion.fast` (200ms) + `curveSpring`. Scale 0→1 when online, 1→0 when offline.
  - Sub-step 2.1.5: Add comment:
    ```dart
    // Online dot gated behind chat_presence_receipts_enabled feature flag.
    // presenceUpdatedAt within 60s = heuristic for "online".
    // TODO: Wire to explicit isOnline field when backend provides it.
    ```
- [ ] (`@Pixel` | Skill: `harden`) Add Semantics:
  - Sub-step 2.1.6: When dot is visible, wrap avatar Stack in `Semantics(label: '${name}, online')`.
- [ ] (`@Sentinel`) Verify dot does not overflow tile bounds (dot positioned within avatar's bounding box).
- [ ] (`@Sentinel`) Verify dot hidden when `isPresenceReceiptsEnabled` is false.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.2 Relative Time Formatting
- [ ] (`@Pixel` | Skill: `clarify`) Replace absolute time with relative:
  - Sub-step 2.2.1: Create `String _formatRelativeTime(DateTime? time)` helper method:
    - `null` → empty string
    - Under 60 seconds ago → "Just now"
    - 1-59 minutes ago → "${min}m"
    - 1-23 hours ago → "${hr}h"
    - Yesterday (same calendar day - 1) → "Yesterday"
    - This week (within 7 days) → weekday name ("Mon", "Tue", ...)
    - Older → "MMM d" format via `DateFormat.MMMd()` (e.g., "Mar 15")
    - Future timestamps (clock skew edge case) → treat as "Just now"
  - Sub-step 2.2.2: Replace current `date_utils.formatUtcToLocal` call for time display with `_formatRelativeTime(conversation.lastMessageTime)`.
  - Sub-step 2.2.3: Keep `formatUtcToLocal` import if used elsewhere in the file. Remove only if fully replaced.
- [ ] (`@Sentinel`) Verify time format is correct for all cases: null time, future time, same day, yesterday, last week, last month.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Online dot shows for recent presence when flag is on. Dot hidden when flag is off. Relative time renders correctly. Tile layout stable.

---

## Phase 3A: MessageBubble — StatefulWidget Conversion + Link Detection

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Convert MessageBubble to StatefulWidget (for `TapGestureRecognizer` lifecycle management) and add URL detection.
**Why:** Master Plan §6.4 specifies "Link detection: URLs become tappable links with teal color + underline." `TapGestureRecognizer` requires disposal, which needs a StatefulWidget.
**How:** Convert MessageBubble from `StatelessWidget` → `StatefulWidget`. Use `RegExp` for URL detection + `RichText` with `TapGestureRecognizer`. Dispose recognizers in `dispose()`.
**Result:** URLs are teal + underlined + tappable (launches browser). No memory leak from recognizers.

### 3A.1 Convert MessageBubble to StatefulWidget
- [ ] (`@Pixel`) Convert `MessageBubble` from `StatelessWidget` to `StatefulWidget`:
  - Sub-step 3A.1.1: Change `class MessageBubble extends StatelessWidget` → `class MessageBubble extends StatefulWidget`.
  - Sub-step 3A.1.2: Move all fields (`text`, `time`, `isMine`, `status`, `isFirstInGroup`, `isLastInGroup`) to the widget class.
  - Sub-step 3A.1.3: Create `_MessageBubbleState extends State<MessageBubble>`.
  - Sub-step 3A.1.4: Move `build()` method into `_MessageBubbleState`, replacing direct field access with `widget.text`, `widget.time`, etc.
  - Sub-step 3A.1.5: Add `List<TapGestureRecognizer> _recognizers = [];` field for lifecycle management.
  - Sub-step 3A.1.6: Add `dispose()` override that disposes all recognizers:
    ```dart
    @override
    void dispose() {
      for (final r in _recognizers) { r.dispose(); }
      super.dispose();
    }
    ```
- [ ] (`@Sentinel`) Verify existing call sites compile unchanged (constructor API unchanged).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 3A.2 Link Detection
- [ ] (`@Pixel` | Skill: `harden`) Add URL detection to `_MessageBubbleState`:
  - Sub-step 3A.2.1: Add static URL pattern: `static final _urlPattern = RegExp(r'https?://[^\s]+');`
  - Sub-step 3A.2.2: Create `bool get _hasLinks => _urlPattern.hasMatch(widget.text);`
  - Sub-step 3A.2.3: Create `Widget _buildRichText(AppColorScheme colorScheme)` method:
    - Parse `widget.text` using `_urlPattern.allMatches()`.
    - For each match: create a `TextSpan` with `recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url))`.
    - Store recognizer in `_recognizers` list.
    - Non-URL text: plain `TextSpan` with current style.
  - Sub-step 3A.2.4: Clear and rebuild `_recognizers` in `didUpdateWidget` when `widget.text` changes:
    ```dart
    @override
    void didUpdateWidget(covariant MessageBubble old) {
      super.didUpdateWidget(old);
      if (old.text != widget.text) _disposeRecognizers();
    }
    void _disposeRecognizers() {
      for (final r in _recognizers) { r.dispose(); }
      _recognizers.clear();
    }
    ```
  - Sub-step 3A.2.5: Link color logic:
    - **Sent messages (teal bubble, white text):** Links render as `Colors.white` with `TextDecoration.underline` (teal-on-teal is unreadable).
    - **Received messages (card background):** Links render as `colorScheme.primary` (teal) with `TextDecoration.underline`.
  - Sub-step 3A.2.6: For messages with no links, keep the simpler `Text` widget (avoid unnecessary RichText overhead).
- [ ] (`@Pixel` | Skill: `harden`) Handle edge cases:
  - Sub-step 3A.2.7: Very long URLs — text wraps within bubble (no horizontal overflow).
  - Sub-step 3A.2.8: URLs at start/end of message — no leading/trailing whitespace artifacts.
  - Sub-step 3A.2.9: Multiple URLs in same message — each independently tappable with separate recognizer.
  - Sub-step 3A.2.10: URL with trailing punctuation (e.g., `https://example.com.`) — regex may include the period. Trim trailing `.`, `,`, `)` from matched URL.
- [ ] (`@Sentinel`) Verify `url_launcher` import resolves (`import 'package:url_launcher/url_launcher.dart';`).
- [ ] (`@Sentinel`) Verify link text is readable in both sent and received bubbles.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Links tappable and styled. Recognizers disposed. No memory leak. Backward compatible.

---

## Phase 3B: MessageBubble — Emoji-Only Rendering

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Render emoji-only messages at larger scale without bubble background.
**Why:** Master Plan §6.4 specifies "Emoji-only messages: If message is 1-3 emoji only, display at 2x size without bubble background."
**How:** Detect emoji-only via `\p{Extended_Pictographic}` regex, render at 2x font size without Container background.
**Result:** Pure emoji messages display large without bubble. Mixed text+emoji messages unaffected.

### 3B.1 Emoji-Only Detection and Rendering
- [ ] (`@Pixel` | Skill: `delight`) Detect and render emoji-only messages:
  - Sub-step 3B.1.1: Add static regex using `\p{Extended_Pictographic}` (NOT `\p{Emoji}` which matches digits):
    ```dart
    /// Matches 1-3 visual emoji with optional variation selectors and ZWJ sequences.
    /// Uses Extended_Pictographic to exclude digits (#, *, 0-9) that \p{Emoji} includes.
    static final _emojiOnlyPattern = RegExp(
      r'^\s*(\p{Extended_Pictographic}[\u{FE0F}\u{200D}\p{Extended_Pictographic}]*\s*){1,3}\s*$',
      unicode: true,
    );
    ```
  - Sub-step 3B.1.2: Add `bool get _isEmojiOnly => _emojiOnlyPattern.hasMatch(widget.text);`
  - Sub-step 3B.1.3: When `_isEmojiOnly` is true:
    - Render text at 2x font size: `fontSize: 32` (approximately 2x body text).
    - **No** bubble Container background — remove the colored container.
    - Keep alignment: `Align` with `Alignment.centerRight` for sent, `Alignment.centerLeft` for received.
    - Keep timestamp (below the emoji, using `AppTypography.micro`).
  - Sub-step 3B.1.4: Keep grouping behavior (`isFirstInGroup`/`isLastInGroup`) for emoji-only — affects spacing only, not bubble.
  - Sub-step 3B.1.5: Do NOT apply emoji-only to messages that contain ANY non-emoji text.
  - Sub-step 3B.1.6: Do NOT apply emoji-only to messages with links (link detection takes priority).
- [ ] (`@Sentinel`) Test regex with: "😀" (single), "👍🏽" (skin tone), "👨‍👩‍👧" (ZWJ family), "❤️" (variation selector), "123" (must NOT match), "#" (must NOT match), "hello 😀" (must NOT match), "😀 😀 😀 😀" (must NOT match — 4 emoji exceeds limit).
- [ ] (`@Sentinel`) Verify emoji-only messages still have proper Semantics label.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Emoji-only renders large without bubble. Non-emoji messages unaffected. Regex rejects digits and mixed text.

---

## Phase 3C: MessageBubble — Reply Quote Visual

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add optional reply quote display above the message text.
**Why:** Phase 4A will add swipe-to-reply which needs a visual quote in the bubble. Building the visual first keeps phases independent.
**How:** Add optional `replyToText` and `replyToSender` parameters. When set, render a quoted section above message text.
**Result:** MessageBubble can display a reply quote. Not wired until backend supports it.

### 3C.1 Reply Quote Widget
- [ ] (`@Pixel` | Skill: `arrange`) Add optional reply quote display:
  - Sub-step 3C.1.1: Add optional parameters to `MessageBubble`:
    ```dart
    final String? replyToText;
    final String? replyToSender;
    ```
  - Sub-step 3C.1.2: Default both to `null` in constructor — **backward compatible**, no existing call sites need changes.
  - Sub-step 3C.1.3: When `replyToText != null`, render above the message text:
    - Container with thin left border (3px, `colorScheme.primary` at 0.5 opacity for received, `Colors.white` at 0.5 for sent).
    - Inside: sender name in `AppTypography.captionBold` (max 1 line, ellipsis), quoted text in `AppTypography.caption` (max 2 lines, ellipsis).
    - Background: slightly tinted (`colorScheme.primary.withOpacity(0.05)` for received, `Colors.white.withOpacity(0.1)` for sent).
    - Padding: `AppDimens.p8` all sides.
    - Corner radius: `AppDimens.r8`.
  - Sub-step 3C.1.4: Add comment:
    ```dart
    // TODO: Wire replyToText/replyToSender when Message model has reply_to_message_id.
    // Until then, these params are available for the View-layer reply preview in ChatScreen.
    ```
- [ ] (`@Sentinel`) Verify no existing call sites break (parameters are optional with null defaults).
- [ ] (`@Sentinel`) Verify reply quote renders correctly in both sent and received bubbles.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Reply quote visual ready. Backward compatible. Not yet wired to data.

---

## Phase 4A: ChatScreen — Reply State + Reply Preview Bar

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Add reply-to state management and the reply preview bar above the input field. This is the foundation that Phase 4B (swipe) and 4C (menu) depend on.
**Why:** Both swipe-to-reply and long-press Reply action need a target state and a preview UI. Building this first means 4B and 4C are simple gesture→state wiring.
**How:** Add `Message? _replyTarget` state. Convert `_buildInputArea` to return `Column(children: [replyBar, inputRow])`.
**Result:** Reply bar shows above input when `_replyTarget` is set. Sending clears the target.

### 4A.1 Reply State Management
- [ ] (`@Pixel`) Add reply-to state in `_ChatScreenState`:
  - Sub-step 4A.1.1: Add `Message? _replyTarget;` field.
  - Sub-step 4A.1.2: Add methods:
    ```dart
    void _setReplyTarget(Message msg) {
      setState(() => _replyTarget = msg);
      // Ensure input field gets focus when replying
      // (user expects to type immediately after triggering reply)
    }
    void _clearReplyTarget() => setState(() => _replyTarget = null);
    ```
  - Sub-step 4A.1.3: In the existing `onTap` send handler (line ~804-811), add `_clearReplyTarget();` after successful `sendMessage()`:
    ```dart
    await _chatCtrl.sendMessage(text);
    if (context.mounted) {
      _messageController.clear();
      _clearReplyTarget(); // Clear reply after send
    }
    ```
  - Sub-step 4A.1.4: Add comment:
    ```dart
    // TODO: Pass _replyTarget?.id to ChatViewModel.sendMessage() when backend
    // supports reply_to_message_id column. Currently reply context is View-only.
    ```

### 4A.2 Reply Preview Bar (Inside `_buildInputArea`)
- [ ] (`@Pixel` | Skill: `arrange`) Modify `_buildInputArea` to include reply bar:
  - Sub-step 4A.2.1: **Convert `_buildInputArea` return type from a single `AppCardContainer(child: Row(...))` to `AppCardContainer(child: Column(mainAxisSize: MainAxisSize.min, children: [_replyBar, _inputRow]))`**. The `_inputRow` is the existing Row. The `_replyBar` is the new widget.
  - Sub-step 4A.2.2: `_replyBar` widget (only built when `_replyTarget != null`):
    - Thin left accent border: 3px, `colorScheme.primary`.
    - Layout: `Row(children: [borderBar, Expanded(Column(senderName, preview)), closeButton])`.
    - Sender name: `AppTypography.captionBold`, 1 line.
    - Message preview: `AppTypography.caption`, 1 line, ellipsis, `colorScheme.textSecondary`.
    - Close button: `GestureDetector(onTap: _clearReplyTarget)` with `Icons.close` at `AppDimens.iconSizeSmall`.
    - Bottom divider: thin line separating reply bar from input row.
  - Sub-step 4A.2.3: Wrap `_replyBar` in `AnimatedSize(duration: AppMotion.fast, curve: AppMotion.curveDecel)` so it slides in/out smoothly.
  - Sub-step 4A.2.4: Verify bottom padding calculation still works — `MediaQuery.of(context).padding.bottom` must apply to the outer `AppCardContainer`, not the inner Row, to account for the reply bar's height.
- [ ] (`@Sentinel`) Verify reply bar doesn't push input below bottom safe area on small devices (iPhone SE).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Reply bar shows when `_replyTarget` is manually set in code. Bar dismisses on close. Send clears target. Input area layout stable.

---

## Phase 4B: ChatScreen — Swipe-to-Reply Gesture

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add swipe-right gesture on messages to trigger reply state (built in Phase 4A).
**Why:** Master Plan §6.3 specifies "Swipe-to-reply: Swipe right on a message to reply."
**How:** Custom horizontal drag detector on message items with reply icon reveal. Uses `_setReplyTarget()` from Phase 4A.
**Result:** Swiping right on a message sets it as reply target and shows the preview bar.

### 4B.1 Swipe Gesture
- [ ] (`@Pixel` | Skill: `animate`) Add swipe gesture to message items in the `itemBuilder`:
  - Sub-step 4B.1.1: Create a `_SwipeToReply` stateful widget (or use inline `GestureDetector` with `onHorizontalDragUpdate`/`onHorizontalDragEnd`).
  - Sub-step 4B.1.2: On horizontal drag (start-to-end direction only): `Transform.translate` the message bubble to the right. Reveal a reply `Icons.reply_rounded` icon behind it at the left edge.
  - Sub-step 4B.1.3: Drag threshold: 60px. Reply icon appears at ~30px, scales up to full size at 60px using `curveSpring`.
  - Sub-step 4B.1.4: When drag exceeds 60px threshold and user releases: call `_setReplyTarget(message)` + `AppInteractionStates.hapticTap()`.
  - Sub-step 4B.1.5: When drag doesn't reach threshold OR user drags in wrong direction: spring message back with `AnimationController(duration: AppMotion.fast)` + `curveSpring`.
  - Sub-step 4B.1.6: Only enable swipe on:
    - Regular text messages (`MessageType.text`)
    - Attachment messages (image type)
    - NOT date separators, system messages, or offer bubbles.
- [ ] (`@Pixel` | Skill: `harden`) Handle gesture arena conflicts:
  - Sub-step 4B.1.7: Set `onHorizontalDragStart` to only accept when dx > 0 (right-swipe only). This prevents left-swipe and avoids competing with ListView's vertical scroll.
  - Sub-step 4B.1.8: Do not wrap in `Dismissible` — use raw `GestureDetector` to avoid dismissal behavior. (MessagesScreen's `Dismissible` is on a different screen entirely — no conflict.)
- [ ] (`@Sentinel`) Verify swipe doesn't break vertical scrolling of the message list.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Swiping right on a text message triggers reply bar. Swiping on offers/separators does nothing. Vertical scroll unaffected.

---

## Phase 4C: ChatScreen — Long-Press Context Menu

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Add long-press context menu with Copy and Reply options on message bubbles.
**Why:** Master Plan §6.3 specifies "Long-press message: Context menu (copy, reply, delete) — use a nice popover, not AlertDialog."
**How:** `GestureDetector(onLongPress: ...)` that calls `showModalBottomSheet` with Copy + Reply options. Uses `_setReplyTarget()` from Phase 4A.
**Result:** Long-press on a message shows a styled bottom sheet with Copy and Reply.

### 4C.1 Context Menu
- [ ] (`@Pixel` | Skill: `delight`) Add long-press to message bubbles:
  - Sub-step 4C.1.1: Wrap each message widget (inside the swipe wrapper from 4B) with `GestureDetector(onLongPress: () => _showMessageMenu(context, message, isMine))`.
  - Sub-step 4C.1.2: `_showMessageMenu` calls `showModalBottomSheet` with:
    - Background: `colorScheme.cardBackground`.
    - Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r24)))`.
    - Content: `Column` of `ListTile`-style rows:
      - **Copy** (icon: `Icons.copy_outlined`, text: "Copy") — for text and offer messages
      - **Reply** (icon: `Icons.reply_rounded`, text: "Reply") — for text and attachment messages
    - Haptic on open: `HapticFeedback.mediumImpact()`.
  - Sub-step 4C.1.3: **Copy** action:
    ```dart
    Clipboard.setData(ClipboardData(text: message.content));
    Navigator.pop(context); // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied')),
    );
    AppInteractionStates.hapticTap();
    ```
  - Sub-step 4C.1.4: **Reply** action:
    ```dart
    Navigator.pop(context); // Close sheet
    _setReplyTarget(message);
    ```
  - Sub-step 4C.1.5: Style each option: `AppTypography.bodyMedium`, `AppDimens.iconSizeSmall` icons, `AppDimens.p16` padding.
- [ ] (`@Pixel` | Skill: `harden`) Message-type-specific menus:
  - Sub-step 4C.1.6: Date separators: no `onLongPress` (no context menu).
  - Sub-step 4C.1.7: System messages: no context menu.
  - Sub-step 4C.1.8: Offer bubbles: show **Copy** only (copies price + description), no Reply.
  - Sub-step 4C.1.9: Attachment messages (images): show **Reply** only (no text to copy). If there's a caption, show both Copy + Reply.
- [ ] (`@Sentinel`) Verify bottom sheet appears correctly in both light and dark mode.
- [ ] (`@Sentinel`) Verify bottom sheet doesn't appear behind the chat header (Positioned Z-order — bottom sheets use overlay, so this should be fine).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Long-press shows Copy/Reply. Copy puts text on clipboard. Reply triggers reply bar. Menu options vary by message type.

---

## Phase 5: OfferMessageBubble — StatefulWidget Conversion + Visual Elevation

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Convert OfferMessageBubble to StatefulWidget and add visual elevation with animated status border.
**Why:** Master Plan §6.5 specifies elevated card with status-driven border. AnimatedContainer for border transition requires StatefulWidget. OfferMessageBubble is confirmed `StatelessWidget` (line 22).
**How:** Explicit conversion carrying all 13 constructor parameters, then add elevation + border animation.
**Result:** Offer bubbles are visually distinct elevated cards with animated status borders.

### 5.1 StatelessWidget → StatefulWidget Conversion (FIX-3: Explicit, Not Conditional)
- [ ] (`@Pixel`) Convert `OfferMessageBubble`:
  - Sub-step 5.1.1: Change `class OfferMessageBubble extends StatelessWidget` → `class OfferMessageBubble extends StatefulWidget`.
  - Sub-step 5.1.2: Carry ALL 13 constructor parameters to the widget class:
    1. `title` (String, required)
    2. `description` (String, required)
    3. `price` (String, required)
    4. `deliveryDays` (String, required)
    5. `status` (OfferStatus, default pending)
    6. `isMine` (bool, required)
    7. `time` (String, required)
    8. `onAccept` (VoidCallback?, optional)
    9. `onDecline` (VoidCallback?, optional)
    10. `offerId` (String?, optional)
    11. `rawStatus` (String?, optional)
    12. `onCancel` (VoidCallback?, optional)
    13. `onDeliver` (VoidCallback?, optional)
    14. `onComplete` (VoidCallback?, optional)
    *(Note: 14 parameters total — plan originally said 13, scan shows 14.)*
  - Sub-step 5.1.3: Create `_OfferMessageBubbleState extends State<OfferMessageBubble>`.
  - Sub-step 5.1.4: Move `build()` method into state, replacing `title` with `widget.title`, etc.
  - Sub-step 5.1.5: Verify constructor is byte-identical for call sites (required/optional params unchanged).
- [ ] (`@Sentinel`) Run existing 9 OfferMessageBubble tests — all must pass unchanged.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 5.2 Elevated Card Treatment
- [ ] (`@Pixel` | Skill: `normalize`) Add elevation and status-driven border:
  - Sub-step 5.2.1: Wrap the existing offer bubble content in a `Container` (or `AnimatedContainer`) with:
    - `boxShadow: AppDecorations.elevation(2)` — Level 2 shadow (raised).
    - `borderRadius: BorderRadius.circular(AppDimens.r16)`.
    - `color: colorScheme.cardBackground`.
  - Sub-step 5.2.2: Add a 1.5px `Border.all` with status-driven color:
    - `OfferStatus.pending` → `colorScheme.warning` (gold)
    - `OfferStatus.accepted` → `colorScheme.success` (green)
    - `OfferStatus.declined` → `colorScheme.danger.withOpacity(0.6)` (muted red)
  - Sub-step 5.2.3: Use `AnimatedContainer(duration: AppMotion.standard, curve: AppMotion.curveStandard)` so border color and shadow transition smoothly when status changes.
- [ ] (`@Sentinel`) Verify animation doesn't cause layout shift in the chat list.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Re-run 9 OfferMessageBubble tests — all must still pass.
- **GATE CHECK:** OfferMessageBubble is StatefulWidget. Elevated with Level 2 shadow. Border color reflects status. Transition animated. All 9 tests pass.

---

## Phase 6A: FullscreenImageViewer — Shared Core Widget

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Create a reusable fullscreen image viewer in `lib/core/widgets/` that can be used by chat attachments, portfolio, task images, and profile photos.
**Why:** Master Plan §6.4 specifies "tap to full-screen" for image messages. Building it as a shared widget (FIX-7) prevents re-implementation in future phases.
**How:** Create a new file with a static `show()` method that pushes a fullscreen route with Hero animation and InteractiveViewer.
**Result:** Reusable `FullscreenImageViewer.show()` available in `lib/core/widgets/`.

### 6A.1 Create Shared Widget
- [ ] (`@Pixel` | Skill: `animate`) Create `lib/core/widgets/fullscreen_image_viewer.dart`:
  - Sub-step 6A.1.1: File doc comment explaining purpose and reusability.
  - Sub-step 6A.1.2: Static method signature:
    ```dart
    /// Opens a fullscreen image viewer with Hero animation, pinch-to-zoom, and
    /// swipe-to-dismiss. Reusable across chat attachments, portfolio, and profile.
    static Future<void> show(
      BuildContext context, {
      required String imageUrl,
      String? heroTag,
      String? caption,
    })
    ```
  - Sub-step 6A.1.3: Push a `PageRouteBuilder` with `FadeRoute`-style transition (reference `custom_route_transitions.dart`):
    - Background: `Colors.black`.
    - Body: `Hero(tag: heroTag ?? imageUrl, child: InteractiveViewer(child: CachedNetworkImage(imageUrl: imageUrl)))`.
    - Hero tag defaults to `imageUrl` if not provided.
    - `InteractiveViewer` for pinch-to-zoom (min scale 1.0, max scale 4.0).
  - Sub-step 6A.1.4: Dismiss by:
    - Tapping the black background area (outside the image).
    - Android back button / iOS swipe-back.
    - Vertical drag down gesture (threshold: 100px → `Navigator.pop(context)`).
  - Sub-step 6A.1.5: Caption overlay at bottom (when `caption != null`):
    - Semi-transparent black bar (`Colors.black.withOpacity(0.6)`).
    - `AppTypography.bodySmall` in white.
    - Positioned at bottom with safe area padding.
  - Sub-step 6A.1.6: Semantics: `Semantics(label: 'Fullscreen image${caption != null ? ': $caption' : ''}')`.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Verify the file has no feature imports (only core + flutter + cached_network_image).
- **GATE CHECK:** `FullscreenImageViewer.show()` exists. File compiles. No feature dependencies.

---

## Phase 6B: AttachmentMessageTile — Wire Fullscreen Viewer

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Wire the existing `AttachmentMessageTile` to open `FullscreenImageViewer` on tap.
**Why:** Master Plan §6.4 specifies "Image messages: tap to full-screen."
**How:** Wrap the image in `GestureDetector(onTap: ...)` that calls `FullscreenImageViewer.show()`. Hero tag = storage path for uniqueness.
**Result:** Tapping an image in chat opens the fullscreen viewer with hero animation.

### 6B.1 Wire Tap Gesture
- [ ] (`@Pixel`) Add tap-to-fullscreen in `AttachmentMessageTile`:
  - Sub-step 6B.1.1: Import `fullscreen_image_viewer.dart`.
  - Sub-step 6B.1.2: Wrap the `CachedNetworkImage` / image widget in `GestureDetector(onTap: _openFullscreen)`.
  - Sub-step 6B.1.3: `_openFullscreen` method:
    ```dart
    void _openFullscreen() {
      if (_signedUrl == null || _hasError) return; // Don't open if loading or error
      FullscreenImageViewer.show(
        context,
        imageUrl: _signedUrl!,
        heroTag: 'attachment_${widget.storagePath}',
        caption: widget.caption,
      );
    }
    ```
  - Sub-step 6B.1.4: Wrap the image with `Hero(tag: 'attachment_${widget.storagePath}')` to enable the transition animation.
  - Sub-step 6B.1.5: Disable tap when image is still loading (skeleton state) or failed (error state) — check `_signedUrl != null && !_hasError`.
- [ ] (`@Sentinel`) Verify Hero tag uses `storagePath` (unique per attachment) not the signed URL (changes on each generation).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Tap opens fullscreen viewer. Hero animation smooth. Disabled during loading/error.

---

## Phase 7: ChatContextWidget — Task Pill Polish

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Minor visual polish to the task context pill at the top of chat.
**Why:** Master Plan §6.2 specifies "Task context: Small pill showing linked task/booking name (optional)" — current implementation uses `AppCardContainer`, can be polished to a compact pill.
**How:** Adjust styling to a pill-shaped chip with icon + title + chevron.
**Result:** Task context rendered as a compact pill. Tap navigation preserved.

### 7.1 Pill Styling
- [ ] (`@Pixel` | Skill: `polish`) Adjust ChatContextWidget layout:
  - Sub-step 7.1.1: Replace `AppCardContainer` with a `Container` using `StadiumBorder()` or `BorderRadius.circular(AppDimens.r20)`.
  - Sub-step 7.1.2: Reduce padding: `EdgeInsets.symmetric(horizontal: AppDimens.p12, vertical: AppDimens.p8)`.
  - Sub-step 7.1.3: Background: `colorScheme.primary.withOpacity(0.08)`.
  - Sub-step 7.1.4: Layout: `Row(mainAxisSize: MainAxisSize.min, children: [icon, SizedBox, title, SizedBox, chevron])`.
  - Sub-step 7.1.5: Leading icon: `Icons.work_outline_rounded` (for task) at `AppDimens.iconSizeSmall`, color `colorScheme.primary`.
  - Sub-step 7.1.6: Title: `AppTypography.caption`, single line, `TextOverflow.ellipsis`, `Flexible` to handle long titles.
  - Sub-step 7.1.7: Trailing: `Icons.chevron_right_rounded` at `AppDimens.iconSizeSmall`, color `colorScheme.textSecondary`.
  - Sub-step 7.1.8: Wrap pill in `Center` or `Align(alignment: Alignment.center)` with horizontal margin.
- [ ] (`@Sentinel`) Verify pill doesn't overflow on long task titles (Flexible + ellipsis).
- [ ] (`@Sentinel`) Verify tap navigation to task details still works.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** Task context renders as compact pill. Overflow handled. Navigation preserved.

---

## Phase 8A: Widget Tests (FIX-5: Maintain Test Quality)

**Primary Agent(s):** `@Sentinel`
**Goal:** Add widget tests for the new interaction features to maintain Phase 5's test quality discipline.
**Why:** Phase 5 added 17 widget tests. Adding 0 tests for 7 files of new interaction logic is a quality regression.
**How:** Add 5+ focused widget tests in `test/widget/chat/`.
**Result:** New tests covering search, emoji, links, reply bar, and relative time.

### 8A.1 Test Implementations
- [ ] (`@Sentinel` | Skill: `flutter-testing`) Add tests to `test/widget/chat/`:
  - Sub-step 8A.1.1: **Search test** — `messages_screen_search_test.dart`:
    - Pump MessagesScreen with 3 conversations.
    - Enter search query matching 1 conversation name.
    - Verify only 1 tile visible. Clear search → all 3 visible.
  - Sub-step 8A.1.2: **Emoji-only test** — `message_bubble_emoji_test.dart`:
    - Pump MessageBubble with text "😀".
    - Verify no Container with bubble background color exists.
    - Pump MessageBubble with text "hello 😀".
    - Verify bubble background IS present (not emoji-only).
  - Sub-step 8A.1.3: **Link detection test** — `message_bubble_link_test.dart`:
    - Pump MessageBubble with text "Check https://example.com please".
    - Verify `RichText` is present (not plain `Text`).
    - Verify text span count = 3 (before + link + after).
  - Sub-step 8A.1.4: **Reply bar test** — `chat_screen_reply_test.dart`:
    - Pump ChatScreen with messages.
    - Manually trigger reply state (call `_setReplyTarget` via test helper or by long-pressing + tapping Reply).
    - Verify reply bar appears with message preview text.
    - Tap close → verify reply bar disappears.
  - Sub-step 8A.1.5: **Relative time test** — `conversation_list_tile_time_test.dart`:
    - Test `_formatRelativeTime` with:
      - 30 seconds ago → "Just now"
      - 5 minutes ago → "5m"
      - 3 hours ago → "3h"
      - Yesterday → "Yesterday"
      - 3 days ago → weekday name
      - 30 days ago → "MMM d" format
      - null → empty string
- [ ] (`@Sentinel`) Run `flutter test test/widget/chat/` — all new tests pass.
- [ ] (`@Sentinel`) Run `flutter test` full suite — baseline unchanged, no regressions.
- **GATE CHECK:** 5+ new tests pass. Full test suite stable.

---

## Phase 8B: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 8B.1 Static Analysis
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass with 0 errors, 0 warnings.
- [ ] (`@Sentinel`) Run `dart format . --set-exit-if-changed` — verify formatting.
- [ ] (`@CodeGuard`) Verify no new lint rule violations.

### 8B.2 Architecture Guard
- [ ] (`@Sentinel`) Verify no NEW Supabase imports in modified view files:
  - `grep -r "import.*supabase_flutter" lib/features/chat/view/` — only `attachment_message_tile.dart` should have it (pre-existing).
  - `fullscreen_image_viewer.dart` must NOT import supabase.
- [ ] (`@Sentinel`) Verify no business logic added to View layer — all new features are display/gesture logic only.
- [ ] (`@Sentinel`) Verify no ViewModel modifications — `chat_view_model.dart` must be byte-identical to pre-phase state:
  ```bash
  git diff HEAD -- lib/features/chat/viewmodels/chat_view_model.dart
  ```
  Must return empty.

### 8B.3 Token Compliance
- [ ] (`@Sentinel`) Grep modified files for hardcoded `Color(0x` — must find 0 new.
- [ ] (`@Sentinel`) Grep modified files for hardcoded `Duration(milliseconds:` — must find 0 new instances (pre-existing justified ones OK).
- [ ] (`@Sentinel`) Grep modified files for hardcoded `fontSize:` — must find 0 new (emoji-only uses a documented constant, not raw fontSize).
- [ ] (`@Sentinel`) Grep modified files for hardcoded `BoxShadow(` — must find 0 new (use `AppDecorations.elevation()`).

### 8B.4 Memory Safety
- [ ] (`@Sentinel`) Verify `MessageBubble._disposeRecognizers()` is called in `dispose()` and `didUpdateWidget`.
- [ ] (`@Sentinel`) Verify `MessagesScreen._searchDebounce` is cancelled in `dispose()`.
- [ ] (`@Sentinel`) Verify `OfferMessageBubble` state `dispose()` cleans up AnimationController (if any).

### 8B.5 Functional QA Checklist
- [ ] (`@Sentinel`) MessagesScreen: search bar filters correctly, clear resets, "No results" shows, debounce doesn't crash on navigate-away.
- [ ] (`@Sentinel`) ConversationListTile: online dot shows when flag=on AND presence recent. Dot HIDDEN when flag=off. Relative time renders for all cases (null, seconds, minutes, hours, yesterday, weekday, old).
- [ ] (`@Sentinel`) MessageBubble: URL tappable, styled correctly in sent (white link) and received (teal link) bubbles. Emoji-only renders large without bubble. "123" does NOT trigger emoji-only. Reply quote displays when props set.
- [ ] (`@Sentinel`) ChatScreen: reply bar shows when `_replyTarget` set (via swipe or menu). Bar dismisses on close. Send clears target. Swipe only on text/attachment messages. Menu has correct options per message type.
- [ ] (`@Sentinel`) OfferMessageBubble: elevated with shadow, border matches status (gold/green/red), AnimatedContainer transition visible.
- [ ] (`@Sentinel`) AttachmentMessageTile: tap opens fullscreen, pinch-to-zoom, dismiss by tap/back/swipe. Tap disabled during loading/error.
- [ ] (`@Sentinel`) ChatContextWidget: pill styling, overflow handled, navigation works.

### 8B.6 Regression Checks
- [ ] (`@Sentinel`) Run `flutter test` — baseline must not decrease.
- [ ] (`@Sentinel`) Verify stagger entrance animation on MessagesScreen still works (Phase 5 feature).
- [ ] (`@Sentinel`) Verify message grouping still works (Phase 5 feature).
- [ ] (`@Sentinel`) Verify date separators still render (Phase 5 feature).
- [ ] (`@Sentinel`) Verify scroll-to-bottom FAB still works (Phase 5 feature).
- [ ] (`@Sentinel`) Verify typing dots still animate on ConversationListTile (Phase 5 feature).
- [ ] (`@Sentinel`) Verify shake validation on CreateOfferSheet still works (Phase 5 feature).
- **GATE CHECK:** All static analysis clean. All new features verified. Memory safe. All Phase 5 features regression-free.

---

## Phase 9: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@SlineDocs`

- [ ] (`@SlineDocs`) Update session log `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md` with all phase completions.
- [ ] (`@SlineDocs`) Write `.TODO/DOCS_SYNC_2026-04-10_Phase6_Chat.md` documenting:
  - New features added (search, online dot, relative time, link detection, emoji-only, reply quote, swipe-to-reply, context menu, reply bar, offer elevation, fullscreen images, task pill)
  - New shared widget created (`FullscreenImageViewer`)
  - StatefulWidget conversions (MessageBubble, OfferMessageBubble)
  - MVVM gaps documented (reply storage, message delete, delivery receipts)
  - File line count changes
  - Widget tests added
- [ ] (`@SlineDocs`) Verify session log and docs sync are cross-linked.
- **GATE CHECK:** Session log complete. Docs sync written.

---

## 7) Acceptance Criteria (MANDATORY)

1. MessagesScreen has a functional search bar that filters conversations by name or message content.
2. Search debounce timer is cancelled in `dispose()` with `mounted` guard in callback.
3. ConversationListTile shows green online dot ONLY when `isPresenceReceiptsEnabled` is true AND `presenceUpdatedAt` is within 60s.
4. ConversationListTile shows relative time ("Just now", "2m", "1h", "Yesterday", "Mon", "Mar 15").
5. MessageBubble is a `StatefulWidget` (converted from `StatelessWidget`).
6. MessageBubble detects and renders URLs as tappable links (white underline for sent, teal underline for received).
7. `TapGestureRecognizer` instances are disposed in `dispose()` and `didUpdateWidget`.
8. MessageBubble renders emoji-only messages (1-3 emoji, detected via `\p{Extended_Pictographic}`) at 2x size without bubble background. Digits "123" do NOT trigger emoji-only.
9. MessageBubble accepts optional `replyToText`/`replyToSender` params and renders reply quote.
10. ChatScreen has `_replyTarget` state with `_setReplyTarget` and `_clearReplyTarget` methods.
11. `_buildInputArea` returns a `Column` with reply bar + input row inside `AppCardContainer`.
12. Reply bar shows when `_replyTarget` is set, with sender name, preview, and close button.
13. Sending a message clears `_replyTarget`.
14. ChatScreen supports swipe-to-reply gesture (right swipe >60px on text/attachment messages sets reply target).
15. ChatScreen shows long-press context menu (bottom sheet) with Copy and/or Reply options, varying by message type.
16. OfferMessageBubble is a `StatefulWidget` (converted from `StatelessWidget`, all 14 constructor parameters preserved).
17. OfferMessageBubble has Level 2 elevation shadow and status-driven border color (gold/green/red) with `AnimatedContainer` transition.
18. `FullscreenImageViewer` exists at `lib/core/widgets/fullscreen_image_viewer.dart` with `static show()` method.
19. AttachmentMessageTile opens `FullscreenImageViewer` on tap with Hero animation. Tap disabled during loading/error.
20. ChatContextWidget renders as a compact pill with icon + title + chevron.
21. All modified files pass `flutter analyze` with 0 errors.
22. All modified files use design tokens only (no hardcoded colors, durations, font sizes, shadows).
23. No ViewModel, Service, Repository, or Backend files are modified.
24. All Phase 5 features (grouping, date separators, stagger, FAB, typing dots, Semantics, shake validation) still work.
25. `flutter test` baseline does not decrease. 5+ new widget tests pass.
26. MVVM gaps documented with TODO comments in code and in session log.

## 8) Rollback Plan

- **Immediate revert:** All changes are View-layer only. `git revert` of the commit(s) restores prior state with zero backend impact.
- **Per-file revert:** Each phase modifies independent files. Individual files can be reverted without affecting others.
- **Feature-flag potential:** Search bar can be hidden by removing from build method. Swipe-to-reply can be disabled by removing gesture wrapper. Both are isolated additions.
- **StatefulWidget revert:** If MessageBubble or OfferMessageBubble conversion causes issues, revert the file — the public API is identical, so call sites are unaffected.
- **No migrations:** Zero schema changes. Nothing to rollback in Supabase.
- **No dependency risk:** `url_launcher` (already in pubspec) is a first-party Flutter plugin. If it causes issues, link detection can be removed from MessageBubble independently.

## 9) References (From Scan)

### Docs Scanned
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — Phase 6 (§6.1–6.5) requirements
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Token infrastructure (all tokens confirmed present)
- `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md` — Phase 5 completion record
- `.impeccable.md` — Design context (confirmed present)
- `.TODO/PLAN_CRITIQUE_2026-04-10_Phase6_ChatAdvancedInteractions.md` — Critique with 9 fixes applied

### Code Paths Scanned
- `lib/features/chat/view/` — 7 view files (messages_screen, chat_screen, message_bubble, conversation_list_tile, offer_message_bubble, chat_context_widget, create_offer_sheet)
- `lib/features/chat/attachments/widgets/attachment_message_tile.dart` — attachment bubble
- `lib/features/chat/viewmodels/chat_view_model.dart` — ViewModel API surface (verified: `isPresenceReceiptsEnabled`, `deleteConversation`, `sendMessage`, `currentMessages`, `conversations`)
- `lib/features/chat/models/` — Conversation (`presenceUpdatedAt`, `otherUserTyping`), Message (`content`, `senderId`, `deliveredAt`, `seenAt`), ChatOfferPayload
- `lib/features/chat/services/` — MessageService, AttachmentService, ChatRealtimeMerger
- `lib/features/chat/data/chat_repository.dart` — Repository facade
- `lib/core/theme/` — All 8 theme files confirmed present and populated
- `lib/core/widgets/skeleton_card.dart` — Skeleton patterns
- `lib/core/widgets/signed_avatar.dart` — Avatar widget (for Stack wrapping)
- `lib/core/utils/custom_route_transitions.dart` — FadeRoute pattern
- `test/widget/chat/chat_screen_test.dart` — Existing 3 tests + fixture patterns
- `pubspec.yaml` line 53 — `url_launcher: ^6.3.2` CONFIRMED present

### Database Objects (Not Applicable)
- No Supabase scan needed — this plan makes zero backend changes.

## 10) Plan Appendix: Scan Evidence (Mandatory)

### Constructor Signatures (View Files)
| Class | Constructor | Base Class | Converts To |
|-------|------------|------------|-------------|
| `MessagesScreen` | `const MessagesScreen({super.key})` | `StatefulWidget` | — (already Stateful) |
| `ChatScreen` | `ChatScreen({super.key, required this.conversation, this.enableLifecycleEffects = true, this.attachmentSignedUrlResolver})` | `StatefulWidget` | — (already Stateful) |
| `MessageBubble` | `MessageBubble({super.key, required this.text, required this.time, required this.isMine, this.status, this.isFirstInGroup = true, this.isLastInGroup = true})` | `StatelessWidget` | **→ StatefulWidget** (Phase 3A) |
| `ConversationListTile` | `ConversationListTile({super.key, required this.conversation, required this.onTap})` | `StatefulWidget` | — (already Stateful) |
| `OfferMessageBubble` | 14 params (see Phase 5.1) | `StatelessWidget` | **→ StatefulWidget** (Phase 5) |
| `AttachmentMessageTile` | `AttachmentMessageTile({super.key, required this.isMine, required this.storagePath, required this.time, this.caption, this.signedUrlResolver})` | `StatefulWidget` | — (already Stateful) |
| `ChatContextWidget` | `const ChatContextWidget({super.key, required this.conversation})` | `StatelessWidget` | — (stays Stateless) |

### Line Counts
| File | Lines (Current) | Estimated After |
|------|----------------|-----------------|
| `messages_screen.dart` | 424 | ~500 (+search bar, debounce, disposal) |
| `chat_screen.dart` | 989 | ~1,150 (+reply state, reply bar, swipe, menu) |
| `message_bubble.dart` | 197 | ~310 (+StatefulWidget, links, emoji, reply quote) |
| `conversation_list_tile.dart` | 404 | ~450 (+online dot, relative time) |
| `offer_message_bubble.dart` | 488 | ~540 (+StatefulWidget, elevation, border anim) |
| `attachment_message_tile.dart` | 400 | ~420 (+fullscreen tap, hero) |
| `chat_context_widget.dart` | 157 | ~140 (simplified to pill) |
| **NEW: `fullscreen_image_viewer.dart`** | 0 | ~100 |
| **TOTAL** | **3,059** | **~3,610 (+551 net)** |

### Design Token Files (Confirmed Present)
| Token File | Lines | Status |
|------------|-------|--------|
| `app_motion.dart` | 122 | Present — `fast` (200ms), `standard` (300ms), `curveSpring`, `curveDecel` used |
| `app_states.dart` | 114 | Present — `hapticTap()`, `hapticHeavy()`, `loadingSize` used |
| `app_layout.dart` | 202 | Present — `spacingSection`, `iconStandard`, `buttonHeightCompact` used |
| `app_colors.dart` | 440 | Present — `success`, `warning`, `danger`, `primary` used for status borders |
| `app_decorations.dart` | 113 | Present — `elevation(2)` used for offer bubble |
| `app_typography.dart` | 143 | Present — `caption`, `captionBold`, `bodyMedium`, `micro` used |
| `app_dimens.dart` | 65 | Present — `r14`, `r16`, `r20`, `r24`, `p8`, `p12`, `iconSizeSmall` used |
| `app_theme.dart` | 305 | Present — `context.colorScheme` extension used |

### ViewModel API Surface (Read-Only Reference)
| Method/Field | Available | Used By Phase |
|-------------|-----------|---------------|
| `conversations` | Yes (List<Conversation>) | Phase 1 (search filter) |
| `isPresenceReceiptsEnabled` | Yes (bool) | Phase 2 (online dot gate) |
| `deleteConversation(id)` | Yes | Existing (MessagesScreen) |
| `activeConversation` | Yes | Existing (ChatScreen) |
| `currentMessages` | Yes (List<Message>) | Phase 4B/4C (swipe/reply) |
| `sendMessage(text)` | Yes | Phase 4A (send clears reply) |
| `otherUserTyping` | Yes (bool) | Existing (typing dots) |
| `presenceUpdatedAt` (on Conversation) | Yes | Phase 2 (online dot) |
| `deleteMessage(id)` | **NO** | Gap — not available |
| `replyToMessage(id, text)` | **NO** | Gap — not available |

END.
