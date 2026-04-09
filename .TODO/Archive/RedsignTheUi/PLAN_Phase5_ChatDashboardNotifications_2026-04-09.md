# Plan: Phase 5 — Chat, Dashboard & Notifications UI Redesign

## 1) Goal
- **Goal:** Redesign all chat/messaging screens, notification UI, and remaining dashboard components to match the premium design system established in Phases 0-4. Replace all hardcoded values with design tokens. Add motion, haptics, accessibility, and rich states throughout.
- **Why:** Chat is the most interaction-heavy feature (600-line ChatScreen, 379-line OfferBubble, realtime subscriptions, read receipts, typing indicators). Currently zero animations, no message grouping, no stagger entrances, basic input bar, no empty states in chat, and no accessibility labels. Notifications modal is basic DraggableScrollableSheet with CircularProgressIndicator loading. Dashboard still has untouched components (ActivityFeedPreview, DashboardScreen tabs, Work Tab sub-tabs, Bookings Tab, empty states). These are the most frequently used screens — every user session touches chat + dashboard + notifications.
- **Result:** 17 view/widget files redesigned. All chat screens with stagger entrances, message grouping, animated send button, rich empty/loading/error states. Notifications with skeleton loading and animated badges. Dashboard tabs with polished transitions and enhanced ActivityFeedPreview. Zero hardcoded Duration/BoxShadow/fontSize values in modified files. Full Semantics coverage.
- **Architecture:** View layer ONLY. No ViewModel, Service, Repository, or Backend changes. All changes consume existing design tokens (AppMotion, AppStates, AppColors semantic, AppLayout, AppDecorations elevation, AppTypography).

## 2) Scope

### In-Scope
**Chat Feature (10 files, ~2,343 lines):**
- `chat_screen.dart` (600 lines) — message list, input bar, send button, scroll-to-bottom
- `messages_screen.dart` (271 lines) — conversation inbox, stagger entrance, empty state
- `message_bubble.dart` (105 lines) — asymmetric corners, grouping awareness, status icons, Semantics
- `conversation_list_tile.dart` (255 lines) — rich preview, typing dots, unread badge, haptics
- `offer_message_bubble.dart` (379 lines) — status-driven design, action buttons, semantic colors
- `create_offer_sheet.dart` (209 lines) — bottom sheet polish, validation feedback
- `chat_context_widget.dart` (144 lines) — context banner polish
- `attachment_message_tile.dart` (266 lines) — image loading states, shimmer placeholder
- Skeleton updates in `skeleton_card.dart` for SkeletonMessageBubble and SkeletonConversationTile

**Notifications Feature (3 files, ~345 lines):**
- `notifications_modal.dart` (135 lines) — skeleton loading, stagger entrance, rich empty state
- `notification_tile.dart` (122 lines) — token normalization, haptics, Semantics
- `notification_badge_button.dart` (88 lines) — animated badge entrance, spring scale

**Dashboard Remaining (4 files, ~1,074 lines):**
- `dashboard_screen.dart` (332 lines) — tab transitions, role switch polish
- `activity_feed_preview.dart` (174 lines) — timeline visual, stagger entrance, grouping
- `work_tab.dart` (464 lines) — sub-tab polish, empty state enhancement, review section
- `bookings_tab.dart` (144 lines) — empty state, section headers

### Out-of-Scope
- ViewModel/Service/Repository changes (View layer only)
- Backend/Supabase changes
- Chat functionality changes (no new features like swipe-to-reply, message reactions — pure visual)
- Wallet tab (delegates to wallet feature — separate phase)
- Inbox tab (uses DashboardOfferCard already redesigned in Phase 2)
- Overview tab (uses already-redesigned DashboardCountersGrid, NextActionsList)
- New dependencies in pubspec.yaml

## 3) Evidence & Findings (From Scan)

### Existing
- **Design system fully complete:** AppMotion (7 durations, 7 curves, 4 scales, 3 staggers), AppStates (8-state model, haptics), AppDecorations.elevation(0-4), semantic colors (success/warning/info/danger + muted), AppLayout (cards, avatars, spacing, icons, thumbnails), AppTypography (14 styles with explicit heights)
- **Skeleton infrastructure:** SkeletonMessageBubble and SkeletonConversationTile exist in `skeleton_card.dart` (655 lines)
- **ScaleButton:** Fully redesigned with AppMotion.curveSpring, haptics, reduced-motion support
- **AppCard/AppCardContainer:** Solid surfaces (NO GLASS), elevation parameter, border from colorScheme
- **StatusBadge:** Redesigned core widget available
- **Chat ViewModel:** Exposes isLoadingConversations, isLoadingMessages, isSending, otherUserTyping, presenceUpdatedAt — all states needed for rich UI
- **Notification ViewModel:** Exposes isLoading, error, unreadCount, notifications list
- **Realtime infrastructure:** Message subscriptions, presence/typing, read receipts all functional in ViewModel layer
- **ConversationListTile:** Already has AnimatedContainer (200ms) for unread state, online indicator, typing status, task/booking context badge

### Missing
- **No animations in ChatScreen** — messages appear instantly, no stagger, no send animation
- **No message grouping** — same sender within minutes shows full bubble each time
- **No scroll-to-bottom FAB** — user must manually scroll to see new messages
- **No animated send button** — static icon, no grey→teal transition on text input
- **No empty state in ChatScreen** — just blank space when no messages
- **No date separators** in message list (Today, Yesterday, etc.)
- **No Semantics** in any chat widget (0 Semantics widgets)
- **Notifications use CircularProgressIndicator** — no skeleton loading
- **No stagger entrance** in messages_screen conversation list
- **ActivityFeedPreview** — basic timeline, no visual grouping, no enhanced icons
- **Dashboard tabs** — default Material TabBar transitions, no custom polish
- **Work Tab** — basic sub-tab styling, empty states are plain icon+text
- **Bookings Tab** — plain empty state, no skeleton loading

### Must NOT Duplicate
- `SkeletonConversationTile` already exists — update dimensions if needed, don't create new
- `SkeletonMessageBubble` already exists — update if needed, don't recreate
- DashboardCountersGrid, NextActionsList, WorkItemCard, DashboardOfferCard already redesigned in Phase 2 — do NOT touch
- Overview Tab already composes redesigned widgets — minimal changes only

### Conflicts / Risks
- **ChatScreen is 600 lines** — large file but well-structured (ListView builder, input area, header). Can be enhanced in-place without extraction.
- **ConversationListTile already has some animation** — enhance existing AnimatedContainer, don't duplicate animation layers.
- **OfferMessageBubble is 379 lines with complex status logic** — focus on visual polish and token replacement, don't restructure conditional logic.
- **Dashboard tabs compose widgets from other features** (booking, wallet, tasks) — changes scoped to tab-level layout and transitions only.
- **Typography height changes from Phase 0** may affect chat bubble sizing — verify message bubble layout after token replacement.

## 3A) Screenshot Analysis (26 screenshots, dark + light)

> Screenshots: `.TODO/Phase5_Screenshots/` (HEIC originals + `converted/` JPEGs)

### MessagesScreen (Conversation Inbox)
**Dark (18.45.36) | Light (18.48.52)**
- **Header:** Large bold "Messages" title, subtitle "0 unread conversations" (plain text, no emphasis)
- **Conversation tiles:** Card-style with dark/light surface, ~48px circular avatars with fallback image, task title banner at top of each card (gold "BOOK MATHEMATICS..." / teal "OUTDOOR PERSONAL..."), user name bold, preview text below (truncated), timestamp right-aligned ("4d ago", "13/3/2026")
- **No visible unread dot** on any tile — the plan's unread indicator addition is correct
- **Light mode:** "[photo]" preview text visible, "No messages yet" for empty conversations — good existing preview logic
- **FAB:** Teal "+" floating action button bottom-right
- **PLAN IMPACT:** Stagger entrance will animate these card tiles on first load. Unread boolean "New" badge needs to be added. No empty state screenshot provided — plan's empty state design is speculative (acceptable).

### ChatScreen (Active Conversation)
**Dark (18.45.48, 18.46.49) | Light (18.48.57, 18.49.03)**
- **App bar:** Back arrow, user name "Farooq Omar", teal "$ Offer" button, 3-dot menu. On empty chat (18.46.10) the title shows "Chat" instead of user name — this is a different conversation entry point.
- **Message bubbles (mine):** Right-aligned, teal/dark background, text "hi", timestamp below ("12/3/2026"), no grouping — each message stands alone with full spacing
- **Message bubbles (theirs):** Left-aligned, slightly lighter surface. Currently NO avatar shown next to other user's messages.
- **Offer cards:** Inline in chat, full-width-ish, "CUSTOM OFFER" gold badge top-left, price "$300000" / "$100000" top-right, title "fix ACC" / "Macbook Pro", description "fast and super" / "fixing", delivery "3 Days Delivery" with clock icon, status badge "Completed + Paid" in green pill. Card has dark surface with subtle border.
- **Image attachment (18.46.49, 18.49.03):** Waterfall photo, rounded corners (~12px), no caption visible, right-aligned (mine), natural aspect ratio, timestamp "2m ago" below
- **Context banner (18.48.57 light only):** Orange/amber "BOOKING CONTEXT" label with icon, "Outdoor Personal Photo Session" title, sits at top of chat below app bar, card-style with border
- **Input bar:** "Type a message..." placeholder, left-aligned, teal circular send button right, no attachment button visible in these screenshots
- **Date separator:** "12/3/2026" and "13/3/2026" visible as centered plain text between messages — already exists but very plain (no line, no pill, no emphasis)
- **Empty chat (18.46.10):** Completely blank black/white body — zero empty state, just void. Title shows "Chat" not user name.
- **PLAN IMPACT:**
  - **Message grouping:** Currently zero grouping — each bubble has full spacing. Plan's isFirstInGroup/isLastInGroup API is critical.
  - **Date separators already exist** as plain centered text. Plan should ENHANCE existing separators (add horizontal lines, pill background) rather than INSERT new ones. Update Phase 4.2 accordingly.
  - **No avatars next to messages** — plan should NOT add avatars (they don't exist in current design). Grouping should reduce spacing between same-sender consecutive messages only.
  - **Send button is always teal** — plan says animate grey→teal on text input, but current state shows teal even when empty. Verify in code whether this is conditional.
  - **Empty chat needs rich state** — confirmed completely empty, plan's empty state addition is essential.
  - **Offer cards are well-structured** — plan correctly focuses on token replacement (hardcoded teal/gold), not restructuring.

### CreateOfferSheet
**Dark (18.47.02)**
- Bottom sheet with thin handle bar (~48x6), dark surface
- 4 fields: Title, Description (multiline), Price ($), Delivery (Days) — side by side
- Teal "Send Offer" button full-width at bottom
- No validation error state visible
- Fields have dark input background with subtle border
- **PLAN IMPACT:** Plan correctly targets handle bar dimensions, padding tokens, shake animation on validation. Field layout is clean — don't restructure.

### NotificationsModal
**Dark (18.47.16, 18.47.20) | Light (18.48.41, 18.48.47)**
- **DraggableScrollableSheet** overlaying home screen (~60% height)
- **Header:** "Notifications" bold title, teal "Mark all as read" link, "X" close button
- **Notification tiles:** Icon left (type-colored: blue document, gold warning triangle, teal checkmark), bold title, grey subtitle, timestamp right-aligned ("4d ago" or "15/3/2026", "13/3/2026")
- **No unread indicator dots** on individual notifications — the plan's 10px dot/left accent bar is a new addition
- **No skeleton loading visible** — confirms plan's CircularProgressIndicator→skeleton replacement is needed
- **Tile spacing:** Tight, divider lines between tiles (subtle)
- **Light mode:** White/cream surface, same layout, type-colored icons are more visible against white
- **PLAN IMPACT:**
  - Skeleton loading replacement confirmed needed
  - Stagger entrance will animate tile list
  - Individual tile unread indicator (10px dot or left accent bar) is a NEW visual — currently no read/unread distinction visible
  - "Mark all as read" link position and style should be preserved
  - NotificationBadgeButton (bell icon) visible in home screen behind modal — small, top-right, appears to have no badge dot in these screenshots (0 unread state)

### Dashboard — Overview Tab
**Dark (18.47.43) | Light (18.49.09) | Client role (18.48.22)**
- **Tab bar:** 5 icons with labels (Overview/Bookings/Work/Wallet/Inbox), selected tab has teal underline
- **Greeting:** "Hello, there!" bold, "Ready to pick up some work?" / "Let's get your projects moving." subtitle
- **Counters grid (freelancer):** 4 tiles: Pending Requests (0), Active Work (0), Messages (0), New Offers (0) — each with colored icon + count
- **Counters grid (client, 18.48.22/18.49.09):** Pending Payment, Needs Review (red!), Completed (18) — different counters by role. "Needs Review" has red icon with count "0" but prominent styling.
- **Next Actions:** "No actions pending." — single line, no visual treatment
- **Recent Activity:** "Recent Activity" header with "See All" link, timeline items: icon + title + subtitle + "4d ago". Basic list layout, no vertical line connecting items, no colored dots.
- **Settings gear icon** top-right (dark mode: visible, light mode: visible)
- **PLAN IMPACT:**
  - Counters grid already redesigned in Phase 2 — DO NOT TOUCH
  - NextActionsList already redesigned in Phase 2 — DO NOT TOUCH
  - ActivityFeedPreview: Currently basic icon+text+time list with no visual timeline. Plan's vertical line + colored dots redesign is a significant visual upgrade. "See All" expand/collapse link exists.
  - Tab bar icons need token normalization but work correctly
  - Role switch (gear icon → settings) needs ScaleButton + haptic only

### Dashboard — Bookings Tab
**Dark (18.47.47) | Light (18.49.11)**
- **Sections:** "Upcoming" and "Past" with bold headers
- **Booking cards:** Card-style tiles, title (booking/task name), "Due 2026-04-10 18:32" in red/teal, "Delivery: 5 days" / "12 days", status badge pills (green "COMPLETED", red "CANCELLED")
- **No empty state screenshot** — plan's empty state design is speculative
- **No skeleton loading** — cards appear instantly
- **PLAN IMPACT:** Plan correctly targets empty state and skeleton loading. Status badges may already use StatusBadge from Phase 2 — verify before touching.

### Dashboard — Work Tab
**Dark (18.47.50, 18.47.53, 18.47.55) | Light (18.49.14)**
- **Sub-tabs:** Segmented control style: Active(0) / Done(16) / Cancelled — selected tab has teal fill, others have border
- **Active tab (empty):** Icon + "No active work." centered text — very minimal empty state
- **Done tab (items, 18.47.53):** WorkItemCard tiles with type badge (CUSTOM OFFER amber, BOOKING purple, TASK teal), title, user avatar, "COMPLETED" status. Items are NOT visibly dimmed at 0.7 — they look full opacity in the Done tab. The 0.7 dimming may only apply within individual card status rendering, not the whole tile.
- **Cancelled tab (empty):** Same minimal style as Active empty
- **Light mode (18.49.14):** Same empty Active state, white background
- **PLAN IMPACT:**
  - Sub-tab segmented control height (40px) → token replacement confirmed
  - Empty states are very plain — plan's enhanced empty states with icons + descriptive text + CTA are warranted
  - **CORRECTION:** Done tab items appear full opacity, NOT dimmed. The 0.7 dimming might be more subtle than expected or applied differently. Verify in code exactly where `withValues(alpha: 0.7)` is applied before changing anything.
  - WorkItemCard already redesigned in Phase 2 — DO NOT TOUCH the card itself

### Dashboard — Wallet Tab (OUT OF SCOPE — reference only)
**Dark (18.47.58, 18.48.03) | Light (18.49.19)**
- Gradient teal card, balance breakdown, "Coming Soon" badge on withdrawals
- Already well-designed, OUT OF SCOPE per plan — confirmed correct exclusion

### Dashboard — Inbox Tab
**Dark (18.48.07) | Light (18.49.23)**
- **Dark with items:** DashboardOfferCard tiles with "UNAVAILABLE" red badges, "My Offer" titles, price/delivery
- **Light empty:** "No Proposals Yet" with clipboard icon + subtitle "Proposals you receive or send will appear here."
- DashboardOfferCard already redesigned in Phase 2 — DO NOT TOUCH
- **PLAN IMPACT:** Inbox tab is correctly OUT OF SCOPE. The empty state pattern here is a good reference for other empty states.

---

### Key Corrections from Screenshots

1. **Date separators already exist in ChatScreen** — they render as plain centered date text ("12/3/2026"). Phase 4.2 should ENHANCE existing separators with horizontal rules and pill background, not create them from scratch. The `_ChatListItem` sealed class approach may need to account for how separators are currently generated.

2. **No avatars next to message bubbles** — the current design has no avatars beside messages. Message grouping should reduce inter-bubble spacing for same-sender runs, NOT add/remove avatars. Remove any avatar-related grouping logic from the plan.

3. **Send button appears always teal** — verify in code whether the send button changes color based on text input. If it's already teal when empty, the grey→teal animation target changes to opacity or icon-only animation.

4. **Done tab items may NOT be dimmed at 0.7** — visually they appear full opacity in screenshots. The 0.7 code path may apply only to specific sub-states. Verify exact usage before preserving or changing.

5. **NotificationBadgeButton** — the bell icon is visible in the home screen screenshots but shows no badge (0 unread state). Need to test with unread notifications to see the current badge rendering.

6. **Inbox empty state** ("No Proposals Yet" with icon + subtitle) is a good pattern reference for other empty states across the app.

## 4) System Impact Map
- **UI:** 17 view/widget files modified. Stagger entrances, skeleton loading, message grouping, animated send button, rich empty/error states, date separators, Semantics coverage.
- **MVVM / App Logic:** None. View layer only.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None (UI changes only — realtime infrastructure untouched).
- **Observability:** None.
- **Compatibility & Migration:** None.
- **Contracts:** None.

## 5) Agent Map
- **Phase 0 (Preconditions + Stagger Pattern Lock):** `@SlinePlanner`, `@Sentinel`, `@Architect`
- **Phase 1 (Messages Screen — Inbox):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 2 (ConversationListTile):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 3 (MessageBubble — Grouping API & Polish):** `@Pixel` (primary), `@Sentinel` (gate) — **MOVED UP (was Phase 4)**
- **Phase 4 (ChatScreen — Message List & Input):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate) — **MOVED DOWN (was Phase 3)**
- **Phase 5 (OfferMessageBubble & CreateOfferSheet):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6 (AttachmentMessageTile & ChatContextWidget):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (Notifications + StatefulWidget conversion):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 8 (Dashboard — Tabs & ActivityFeed):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 9 (Dashboard — Work Tab & Bookings Tab):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 10 (Skeleton Updates):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 10A (Widget Tests — NEW):** `@Sentinel` (primary), `@Pixel` (support)
- **Phase 11 (QA & Verification):** `@Sentinel` (primary), `@CodeGuard` (review)
- **Phase 12 (Documentation Sync):** `@SlineDocs` (primary)

**Critique File:** `.TODO/PLAN_CRITIQUE_2026-04-09_Phase5_ChatDashboardNotifications.md` — READ FULLY before execution.

**Session Log Path:** `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

### 0.1 Spec Lock
- [x] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [x] (`@Architect`) Confirm touched modules: `lib/features/chat/view/`, `lib/features/chat/attachments/widgets/`, `lib/features/notifications/view/`, `lib/features/dashboard/view/`, `lib/core/widgets/skeleton_card.dart`.
- [x] (`@SlineDocs`) Confirm `.impeccable.md` exists and is current.
- [x] (`@Architect`) Confirm design tokens available: AppMotion, AppStates, AppDecorations.elevation(), semantic colors, AppLayout, AppTypography — all verified present.
- **GATE CHECK:** Scope is limited to View layer files. No ViewModel/Service/Backend changes. All required tokens exist.

### 0.2 Codebase Discovery Scan
- [x] (`@Pixel`) Grep for `chat` across `lib/` to find ALL files touching chat (callers, navigation references, deep link handlers).
- [x] (`@Pixel`) Grep for `notification` across `lib/` to find all notification-related files.
- [x] (`@Pixel`) Grep for `dashboard` across `lib/` to find related dashboard files.
- [x] (`@Pixel`) Check for any new files added since the plan was written.
- [x] (`@Pixel`) Report discovered files to user before writing code.
- **GATE CHECK:** Full file scope confirmed. No files missed.

### 0.3 Screenshot Collection — COMPLETED
- [x] 26 screenshots collected (13 dark + 13 light) in `.TODO/Phase5_Screenshots/`
- [x] Analysis complete — see **Section 3A: Screenshot Analysis** below for per-screen observations.
- **GATE CHECK:** ✅ Visual context established.

### 0.4 Stagger Pattern Lock (ADDED BY @PlanCritic)
- [x] (`@Architect`) Document the canonical stagger pattern from auth screens:
  - Single `AnimationController` per screen (duration: `AppMotion.emphasis` or `AppMotion.standard`)
  - Per-element `Animation<Offset>` + `Animation<double>` pairs using `Interval` curves
  - `CurvedAnimation` with `AppMotion.curveDecel`
  - Trigger via `WidgetsBinding.instance.addPostFrameCallback`
  - Guard: `_hasAnimatedEntrance` bool to prevent replay on back-navigation/refresh
  - Reference implementation: `lib/features/auth/view/login_screen.dart` lines 47-152
- [x] (`@Architect`) Confirm all 4 stagger targets (messages_screen, notifications_modal, activity_feed_preview, chat date separators) will use this exact pattern.
- [x] (`@Sentinel`) Verify pattern reference file exists and is unchanged.
- **GATE CHECK:** Stagger pattern documented and locked. All implementations will be consistent.

---

## Phase 1: Messages Screen — Conversation Inbox

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Transform the conversation inbox into a polished, animated list with stagger entrance, rich empty state, and enhanced loading.
**Why:** This is the first screen users see when opening chat. Currently loads with 6 basic skeleton tiles and has a plain empty state. No stagger entrance, no haptic on pull-to-refresh.
**How:** Replace hardcoded values with tokens. Add stagger entrance animation. Enhance empty state. Add Semantics.
**Result:** `messages_screen.dart` fully tokenized with stagger entrance and rich states.

> **From screenshots:** Large bold "Messages" header with "0 unread conversations" subtitle. Card-style conversation tiles on dark/light surface: ~48px avatar (circular, fallback image), task title banner at top of each card (gold/teal colored text with icon), bold user name, preview text (truncated, includes "[photo]" for images, "No messages yet" for empty convos), right-aligned timestamp. Teal "+" FAB bottom-right. No visible unread dot on any tile. No empty state captured.

### 1.1 Token Replacement & Cleanup (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace all hardcoded `AppDimens.p24`, `p16`, `p18`, `p12`, `p100` with `AppLayout.*` equivalents where applicable.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.lightRed` direct usage with `colorScheme.danger` where appropriate.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.teal` direct usage with `colorScheme.primary` where appropriate.
- [x] (`@Pixel` | Skill: `normalize`) Ensure all `AppTypography` usages are correct (h2 for title, h5 for section headers, bodySmall for empty state).
- [x] (`@Sentinel`) Verify no raw `Color(0x`, `Duration(milliseconds:`, `BoxShadow(`, or `fontSize:` remain.
- **GATE CHECK:** All hardcoded values replaced with design tokens.

### 1.2 Stagger Entrance Animation (`@Pixel` | Skill: `animate`)
- [x] (`@Pixel` | Skill: `animate`) Add stagger entrance for conversation tiles: each tile slides up from bottom + fades in, with `AppMotion.staggerSmall` (30ms) delay between items.
- [x] (`@Pixel` | Skill: `animate`) Use `AppMotion.standard` (300ms) duration and `AppMotion.curveDecel` curve for entrance.
- [x] (`@Pixel` | Skill: `animate`) Only animate on first load (not on pull-to-refresh or back-navigation).
- [x] (`@Pixel` | Skill: `animate`) Respect `AppMotion.respectMotion()` for reduced-motion users.
- [x] (`@Sentinel`) Verify entrance animation plays on first load, does not re-trigger on refresh.
- **GATE CHECK:** Stagger entrance works correctly on first load only.

### 1.3 Empty State Enhancement (`@Pixel` | Skill: `clarify`)
- [x] (`@Pixel` | Skill: `clarify`) Replace plain icon+text empty state with richer design: larger icon (AppLayout.iconFeature), descriptive title, subtitle with guidance, CTA button ("Find Freelancers" or "Browse Services").
- [x] (`@Pixel` | Skill: `animate`) Fade-in empty state with `AppMotion.standard` duration.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics wrapper for empty state with descriptive label.
- [x] (`@Sentinel`) Verify empty state renders correctly in both light and dark mode.
- **GATE CHECK:** Empty state is visually rich and accessible.

### 1.4 Unread Badge Enhancement (`@Pixel` | Skill: `delight`)
- [x] (`@Pixel` | Skill: `delight`) Enhance unread conversation count display in header — use `StatusBadge` or a dedicated pill with semantic color.
- [x] (`@Pixel` | Skill: `animate`) Animated badge entrance using `AppMotion.curveSpring` and `AppMotion.badgeEntrance` scale.
- [x] (`@Sentinel`) Verify unread count updates correctly when conversations are read.
- **GATE CHECK:** Unread indicator is prominent and animated.

### 1.5 Pull-to-Refresh & Dismiss (`@Pixel` | Skill: `harden`)
- [x] (`@Pixel` | Skill: `harden`) Ensure RefreshIndicator uses `colorScheme.primary` color.
- [x] (`@Pixel` | Skill: `harden`) Verify Dismissible swipe-to-delete still works with stagger animation.
- [x] (`@Pixel` | Skill: `harden`) Add `AppInteractionStates.hapticTap()` on conversation tile tap.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to conversation list (label: "Conversations", child: list).
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** `messages_screen.dart` fully redesigned. All tokens, animations, states, accessibility.

---

## Phase 2: ConversationListTile — Rich Preview

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Enhance conversation tile with animated typing dots, spring unread badge, and improved visual hierarchy.
**Why:** Currently has basic AnimatedContainer (200ms) and small 12x12 unread dot. Avatar is 48x48 (should use AppLayout token). Typing status shows "typing..." as plain text.
**How:** Replace hardcoded values. Add animated typing dots. Enhance unread badge to pill with count. Add Semantics.
**Result:** `conversation_list_tile.dart` polished with enhanced motion and accessibility.

### 2.1 Token Replacement (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace avatar size 48x48 with `AppLayout.avatarMedium` (44) or appropriate token.
- [x] (`@Pixel` | Skill: `normalize`) Replace `Duration(milliseconds: 200)` AnimatedContainer with `AppMotion.fast` (200ms) — same value but from token.
- [x] (`@Pixel` | Skill: `normalize`) Replace `BorderRadius.circular(r14)` for avatar with `AppDimens.r14` or nearest token.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded icon size 10px with `AppLayout.iconTiny` (12).
- [x] (`@Pixel` | Skill: `normalize`) Replace all `AppColors.teal`, `AppColors.gold`, `AppColors.offWhite`, `AppColors.almostBlack` with `colorScheme.*` equivalents.
- [x] (`@Sentinel`) Verify no raw Color, Duration, or size values remain.
- **GATE CHECK:** All tokens normalized.

### 2.2 Typing Indicator Enhancement (`@Pixel` | Skill: `animate`)
- [x] (`@Pixel` | Skill: `animate`) Replace plain "typing..." text with animated dots: three dots that pulse sequentially (opacity 0.3→1.0, 200ms each, 100ms stagger). Use `AppMotion.fast` duration.
- [x] (`@Pixel` | Skill: `animate`) Show typing indicator only when `otherUserTyping == true` and within 15s TTL.
- [x] (`@Sentinel`) Verify typing dots animate correctly and stop when typing stops.
- **GATE CHECK:** Typing indicator is animated and respects TTL.

### 2.3 Unread Indicator Enhancement (`@Pixel` | Skill: `delight`) — CORRECTED BY @PlanCritic
> **NOTE:** Conversation model has NO `unreadCount` field — only boolean `_isUnread()`. Numeric count badge requires ViewModel + model changes that violate View-layer-only scope. Using enhanced boolean indicator instead. Numeric count logged as future enhancement.
- [x] (`@Pixel` | Skill: `delight`) Replace 12x12 dot with enhanced boolean indicator: 10px filled circle using `colorScheme.primary` with subtle border, OR a "New" text label in `AppTypography.micro` with `colorScheme.danger` background.
- [x] (`@Pixel` | Skill: `animate`) Indicator entrance: scale from 0→1 with `AppMotion.curveSpring` and `AppMotion.fast` duration.
- [x] (`@Pixel` | Skill: `normalize`) Use existing `_isUnread()` boolean — do NOT assume numeric `unreadCount` exists.
- [x] (`@Sentinel`) Verify indicator renders correctly for read/unread states.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Unread indicator is boolean, prominent, and animated.
- **FUTURE ENHANCEMENT:** Numeric unread count badge requires adding `unreadCount` to Conversation model + ChatViewModel computation. Separate task.

### 2.4 Accessibility (`@Pixel` | Skill: `harden`)
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: '${conversation.otherUserName}, ${lastMessagePreview}, ${timeAgo}${unread ? ", unread" : ""}')`.
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: 'typing')` when typing indicator is active.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** `conversation_list_tile.dart` fully polished. Tokens, animation, accessibility.

---

## Phase 3: MessageBubble — Grouping API & Polish (MOVED UP — was Phase 4)

> **@PlanCritic fix:** MessageBubble API must be stable BEFORE ChatScreen consumes it. ChatScreen cannot pass `isFirstInGroup`/`isLastInGroup` until MessageBubble accepts them.

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Update MessageBubble API with grouping params and polish visuals BEFORE ChatScreen consumes it.
**Why:** ChatScreen (Phase 4) needs MessageBubble to accept `isFirstInGroup`/`isLastInGroup` for grouping computation. Bubble API must be stable first. Current constructor: `MessageBubble({required text, required time, required isMine, this.status})`.
**How:** Add new optional bool params with defaults (backward compatible — all 3 instantiation sites in ChatScreen still compile). Normalize tokens. Add Semantics.
**Result:** MessageBubble has stable API with grouping support. ChatScreen can consume it in Phase 4.

### 3.1 Token Replacement (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded `EdgeInsets.symmetric(vertical: 4)` margin with `AppLayout.spacingTight`.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded `EdgeInsets.symmetric(horizontal: 14, vertical: 10)` padding with AppDimens tokens.
- [x] (`@Pixel` | Skill: `normalize`) Replace 75% width constraint — keep `0.75` ratio but add a doc comment explaining it.
- [x] (`@Pixel` | Skill: `normalize`) Replace `withValues(alpha: 0.7)` for metadata with `colorScheme.textTertiary`.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded blue color for read receipts with `colorScheme.info`.
- [x] (`@Sentinel`) Verify all hardcoded values normalized.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Tokens normalized.

### 3.2 Message Grouping API (`@Pixel` | Skill: `arrange`)
> **From screenshots:** Current design has NO avatars next to message bubbles. Grouping affects SPACING and CORNER RADIUS only — do NOT add/remove avatar logic.
- [x] (`@Pixel` | Skill: `arrange`) Add `bool isFirstInGroup = true` and `bool isLastInGroup = true` optional params to MessageBubble constructor (defaults maintain backward compat).
- [x] (`@Pixel` | Skill: `arrange`) When `!isFirstInGroup`: reduce top margin to 2px (tight grouping — currently each bubble has full vertical spacing).
- [x] (`@Pixel` | Skill: `arrange`) When `isFirstInGroup`: show full bubble with standard margins.
- [x] (`@Pixel` | Skill: `arrange`) Corner radius adjusts: inner corner (side facing same-sender bubble) is r4, outer corners are r18 for first/last in group, r12 for middle.
- [x] (`@Pixel` | Skill: `arrange`) When `isLastInGroup`: show timestamp below bubble. When `!isLastInGroup`: hide timestamp (reduces noise in grouped runs).
- [x] (`@Sentinel`) Verify: existing ChatScreen code still compiles (defaults = true, so all messages render as standalone).
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** MessageBubble API accepts grouping flags. Existing callers unaffected.

### 3.3 Status Icons & Accessibility (`@Pixel` | Skill: `harden`)
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: '$senderName said: $text, sent at $time, status: $status')` to each bubble.
- [x] (`@Pixel` | Skill: `animate`) Animate status icon transition: sending (clock) → sent (check) → delivered (double check) → read (teal double check). Fade transition `AppMotion.fast`.
- [x] (`@Pixel` | Skill: `colorize`) Read status icon uses `colorScheme.info` (not hardcoded blue).
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** `message_bubble.dart` polished with grouping API, status animation, Semantics.

---

## Phase 4: ChatScreen — Message List & Input Bar (MOVED DOWN — was Phase 3)

> **@PlanCritic fix:** Now executes AFTER MessageBubble (Phase 3) so grouping API is available.

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Redesign the core chat experience: message grouping computation, date separators, animated send button, scroll-to-bottom FAB, rich empty state, and full accessibility.
**Why:** ChatScreen is 600 lines with zero animations, no date separators, no message grouping, static send button, no scroll-to-bottom, no empty state, and no Semantics. This is the most interaction-heavy screen in the app. ListView.builder does NOT use reverse:true — messages are pre-sorted by ViewModel.
**How:** Build flat list of chat items (messages + separators), compute grouping flags, animate send button, add scroll FAB, add empty state, add Semantics.
**Result:** `chat_screen.dart` with grouping, date separators, animated input, scroll FAB, rich empty state, full accessibility.

### 4.1 Token Replacement (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace all hardcoded padding (14px, 10px, 46px button heights) with AppDimens/AppLayout tokens.
- [x] (`@Pixel` | Skill: `normalize`) Replace `BorderRadius.circular(r23)` for input with nearest AppDimens token.
- [x] (`@Pixel` | Skill: `normalize`) Replace all `withValues(alpha: 0.5)` with `AppInteractionStates.disabledOpacity` where appropriate.
- [x] (`@Pixel` | Skill: `normalize`) Ensure all `AppTypography` usages are consistent.
- [x] (`@Sentinel`) Verify no raw hardcoded values remain.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Full token normalization.

### 4.2 Message Grouping & Date Separator Enhancement (ADDED BY @PlanCritic — `@Pixel` | Skill: `arrange`)
> **Critical sub-phase:** This is non-trivial View-layer display logic. Must be explicit.
> **From screenshots:** Date separators ALREADY EXIST as plain centered text ("12/3/2026"). This phase ENHANCES their visual treatment and adds the grouping computation layer on top.
- [x] (`@Pixel` | Skill: `arrange`) **First:** Read how date separators are currently generated in ChatScreen. They already appear as centered date text between messages. Identify the existing logic before restructuring.
- [x] (`@Pixel` | Skill: `arrange`) Create `_ChatListItem` — a simple class or sealed type with two variants: `messageItem(Message, {bool isFirstInGroup, bool isLastInGroup})` and `dateSeparatorItem(DateTime)`. This REPLACES the existing separator logic with a unified flat list approach.
- [x] (`@Pixel` | Skill: `arrange`) Create `List<_ChatListItem> _buildChatItems(List<Message> messages)` method:
  - Sub-step 4.2.1: Iterate messages in chronological order.
  - Sub-step 4.2.2: Insert `dateSeparatorItem` at day boundaries (comparing `message.createdAt.toLocal().day` with previous message's day).
  - Sub-step 4.2.3: Compute `isFirstInGroup`: true if previous item is a separator, or previous message has different `senderId`, or time gap > 2 minutes.
  - Sub-step 4.2.4: Compute `isLastInGroup`: true if next item is a separator, or next message has different `senderId`, or time gap > 2 minutes, or is last message.
- [x] (`@Pixel` | Skill: `arrange`) Update `ListView.builder` to use `_chatItems.length` as `itemCount` and switch on item type in `itemBuilder`.
- [x] (`@Pixel` | Skill: `arrange`) **Enhance** date separator visual: currently plain centered text. Upgrade to centered pill with `AppTypography.caption`, `colorScheme.textTertiary` text, subtle `colorScheme.inputBackground` pill background, horizontal hairline rules on either side. Format: "Today", "Yesterday", or "Mon, Apr 7" (instead of current raw "12/3/2026" format).
- [x] (`@Pixel` | Skill: `harden`) Date separators use `Semantics(label: 'Messages from $date')`.
- [x] (`@Sentinel`) Verify: single message = first AND last in group. Two same-sender messages within 2 min = grouped. Messages across day boundary get separator. Different senders always break groups.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Grouping computation correct. Date separators appear at day boundaries with enhanced visual. MessageBubble receives correct grouping flags.

### 4.3 Send Button Animation (`@Pixel` | Skill: `animate`)
> **From screenshots:** Send button appears teal even when input is empty. Verify in code whether it's conditionally colored before implementing grey→teal transition. If already always teal, change approach to opacity animation (0.5→1.0) or icon-only transform instead.
- [x] (`@Pixel` | Skill: `audit`) **First:** Check current send button color logic in code. If always teal, use opacity/scale animation instead of color transition.
- [x] (`@Pixel` | Skill: `animate`) Animate send button: disabled state (faded, `opacity: 0.5`) → enabled state (full opacity) when text is entered. Use `AnimatedOpacity` with `AppMotion.fast` (200ms). If button is already conditionally styled, enhance the existing transition.
- [x] (`@Pixel` | Skill: `animate`) Scale send button slightly on press using `ScaleButton` wrapper.
- [x] (`@Pixel` | Skill: `delight`) Add `AppInteractionStates.hapticTap()` on send.
- [x] (`@Pixel` | Skill: `animate`) When `isSending`, show mini spinner replacing send icon (18px, `AppInteractionStates.loadingSize`).
- [x] (`@Sentinel`) Verify send animation transitions smoothly and doesn't flash on rapid typing.
- **GATE CHECK:** Send button animates state and responds to send state.

### 4.4 Scroll-to-Bottom FAB (`@Pixel` | Skill: `delight`) — CORRECTED BY @PlanCritic
- [x] (`@Pixel` | Skill: `delight`) Add a small FAB (36px) that appears when user scrolls up more than 2 screen heights from bottom.
- [x] (`@Pixel` | Skill: `animate`) FAB entrance: slide up + fade in with `AppMotion.standard` (300ms), `AppMotion.curveDecel`.
- [x] (`@Pixel` | Skill: `animate`) FAB exit: slide down + fade out with `AppMotion.fast` (200ms), `AppMotion.curveAccel`.
- [x] (`@Pixel` | Skill: `harden`) **Keyboard awareness:** Hide FAB when `MediaQuery.viewInsets.bottom > 0` (keyboard open). OR position FAB above input bar using bottom inset calculation. FAB must NEVER overlap keyboard or input area.
- [x] (`@Pixel` | Skill: `delight`) Tap FAB scrolls to bottom with `AppMotion.emphasis` (500ms) duration.
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(button: true, label: 'Scroll to latest messages')` to FAB.
- [x] (`@Sentinel`) Verify FAB appears/disappears at correct scroll threshold. Verify FAB is hidden when keyboard is open.
- **GATE CHECK:** Scroll-to-bottom FAB works correctly, is animated, and is keyboard-aware.

### 4.5 Empty State (`@Pixel` | Skill: `clarify`)
- [x] (`@Pixel` | Skill: `clarify`) Add empty state when message list is empty: icon (AppLayout.iconFeature), "Start the conversation" title, subtitle with context (task/booking name if available).
- [x] (`@Pixel` | Skill: `animate`) Fade-in with `AppMotion.standard`.
- [x] (`@Pixel` | Skill: `harden`) Semantics label for empty state.
- [x] (`@Sentinel`) Verify empty state shows correctly for new conversations.
- **GATE CHECK:** Empty state is rich and accessible.

### 4.6 Input Bar Polish (`@Pixel` | Skill: `polish`)
- [x] (`@Pixel` | Skill: `polish`) Ensure input field uses `AppCardContainer` with consistent border/background.
- [x] (`@Pixel` | Skill: `polish`) Attachment button (left) and send button (right) properly aligned.
- [x] (`@Pixel` | Skill: `harden`) Input field auto-expands for multi-line (up to 4 lines, then scroll).
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics` labels: input field, send button, attachment button.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- [x] (`@Sentinel`) Run `flutter test` — checkpoint after all chat phases complete.
- **GATE CHECK:** `chat_screen.dart` fully redesigned with grouping, date separators, animated send, keyboard-aware scroll FAB, empty state, accessibility.

---

## Phase 5: OfferMessageBubble & CreateOfferSheet

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish the in-chat offer card and creation sheet with semantic colors, consistent styling, and accessibility.
**Why:** OfferMessageBubble is 379 lines with complex status-driven UI. Uses hardcoded colors (teal 10% alpha, gold for badges). CreateOfferSheet is basic with no validation animation. Both lack Semantics.
**How:** Replace hardcoded colors with semantic tokens. Polish action buttons. Add Semantics. Enhance validation feedback in create sheet.
**Result:** Both files polished with semantic tokens and accessibility.

### 5.1 OfferMessageBubble Token Replacement (`@Pixel` | Skill: `normalize`)
> **From screenshots:** Offer cards inline in chat show: "CUSTOM OFFER" gold badge top-left, price "$300000" top-right, title, description, "3 Days Delivery" with clock icon, status pill "Completed + Paid" in green. Dark surface card with subtle border. Cards are fairly wide (~85% chat width). No Accept/Decline buttons visible in "Completed + Paid" state — those only appear for pending offers.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.teal` with `colorScheme.primary` throughout.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.gold` with `colorScheme.warning` for pending states.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.lightTeal` with `colorScheme.success` for active/completed.
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.lightRed` with `colorScheme.danger` for declined.
- [x] (`@Pixel` | Skill: `normalize`) Replace all `withValues(alpha: 0.1/0.2/0.3)` patterns with consistent opacity tokens.
- [x] (`@Pixel` | Skill: `normalize`) Replace 85% max width with consistent ratio.
- [x] (`@Sentinel`) Verify no raw AppColors or hardcoded colors remain.
- **GATE CHECK:** Semantic colors throughout.

### 5.2 OfferMessageBubble Polish (`@Pixel` | Skill: `polish`)
- [x] (`@Pixel` | Skill: `polish`) Ensure action buttons (Accept/Decline) use `AppButton` or styled equivalent with consistent height (`AppLayout.buttonHeightSmall`).
- [x] (`@Pixel` | Skill: `delight`) Add `AppInteractionStates.hapticTap()` on Accept/Decline.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to entire offer card: `Semantics(label: 'Direct offer: $title, $price IQD, $deliveryDays days, status: $status')`.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to each action button.
- [x] (`@Sentinel`) Verify all status states render correctly with semantic colors.
- **GATE CHECK:** OfferMessageBubble polished and accessible.

### 5.3 CreateOfferSheet Polish (`@Pixel` | Skill: `polish`)
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded handle bar (48x6) with consistent dimension tokens.
- [x] (`@Pixel` | Skill: `normalize`) Replace all padding values with AppDimens tokens.
- [x] (`@Pixel` | Skill: `animate`) Add shake animation on validation failure using `AppInteractionStates.shakeAmplitude` and `AppInteractionStates.shakeDuration`.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics labels to all form fields and submit button.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** CreateOfferSheet polished with validation feedback and accessibility.

---

## Phase 6: AttachmentMessageTile & ChatContextWidget

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish attachment rendering and chat context banner with design tokens and loading states.
**Why:** AttachmentMessageTile (266 lines) uses hardcoded Colors.black12 placeholder, 180px image height, 70% width. ChatContextWidget (144 lines) has hardcoded icon sizes. Both lack Semantics.
**How:** Replace hardcoded values, add shimmer loading for images, add Semantics.
**Result:** Both files polished with tokens and accessibility.

### 6.1 AttachmentMessageTile (`@Pixel` | Skill: `normalize`)
> **From screenshots:** Image attachments render inline with ~12px rounded corners, natural aspect ratio (waterfall photo shows landscape orientation), right-aligned for own messages. No caption visible. Timestamp "2m ago" / "Now" appears below image. No loading shimmer — images appear to load directly.
- [x] (`@Pixel` | Skill: `normalize`) Replace `Colors.black12` placeholder with `colorScheme.inputBackground`.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded 180px image height with `AppLayout.thumbnailMedium * 2.25` or an appropriate constant.
- [x] (`@Pixel` | Skill: `normalize`) Replace 70% width constraint with consistent ratio.
- [x] (`@Pixel` | Skill: `normalize`) Replace loading spinner (20x20, strokeWidth 2) with `AppInteractionStates.loadingSize` and `AppInteractionStates.loadingStrokeWidth`.
- [x] (`@Pixel` | Skill: `animate`) Add shimmer placeholder (SkeletonLoader) while image loads instead of grey box.
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: 'Image attachment${caption != null ? ": $caption" : ""}')`.
- [x] (`@Sentinel`) Verify image loading states: shimmer → loaded (fade in) → error (icon + retry).
- **GATE CHECK:** Attachment tiles polished with shimmer loading and Semantics.

### 6.2 ChatContextWidget (`@Pixel` | Skill: `normalize`)
> **From screenshots (18.48.57 light):** Context banner at top of chat: "BOOKING CONTEXT" label in small caps with orange/amber icon left, task/booking title "Outdoor Personal Photo Session" below, card-style with subtle border, sits between app bar and message list. Compact height, single card.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded icon sizes (16px, 8px) with `AppDimens.iconSizeSmall` or `AppLayout.iconTiny`.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded padding with AppDimens tokens.
- [x] (`@Pixel` | Skill: `normalize`) Use `colorScheme.warning` for booking context (gold) and `colorScheme.primary` for task context (teal).
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: '$contextType context: $taskTitle, tap to view details')`.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** ChatContextWidget polished with tokens and Semantics.

---

## Phase 7: Notifications

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Enhance notifications modal with skeleton loading, stagger entrance, polished tiles, and accessibility.
**Why:** Currently uses CircularProgressIndicator for loading, basic tile layout, small 8x8 unread dot. NotificationBadgeButton badge is positioned at (-4, -4) with hardcoded sizing.
**How:** Replace CircularProgressIndicator with skeleton list. Add stagger entrance. Enhance unread indicator. Add Semantics.
**Result:** All 3 notification files polished.

### 7.1 NotificationsModal (`@Pixel` | Skill: `normalize`)
> **From screenshots:** DraggableScrollableSheet at ~60% screen height. Header: "Notifications" bold left, teal "Mark all as read" link center-right, "X" close right. Tiles have type-colored icon left (blue doc, gold warning, teal check), bold title, grey subtitle, timestamp right. Tight spacing with subtle dividers. No visible read/unread distinction between tiles. No skeleton loading — content appears instantly.
- [x] (`@Pixel` | Skill: `normalize`) Replace `CircularProgressIndicator` loading with skeleton list: 5x `SkeletonNotificationTile` (create small skeleton in-file or use SkeletonLoader directly).
- [x] (`@Pixel` | Skill: `animate`) Add stagger entrance for notification tiles: slide up + fade, `AppMotion.staggerSmall` (30ms), `AppMotion.standard` (300ms).
- [x] (`@Pixel` | Skill: `clarify`) Enhance empty state: larger icon, descriptive title "You're all caught up!", subtitle "No new notifications".
- [x] (`@Pixel` | Skill: `harden`) Enhance error state: icon, error message, styled retry button.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics: modal label, list label, "Mark all as read" button label. Preserve existing header layout (title left, mark-all-read link, X close).
- [x] (`@Sentinel`) Verify skeleton → content transition is smooth.
- **GATE CHECK:** NotificationsModal polished with skeleton loading and stagger entrance.

### 7.2 NotificationTile (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace `AppColors.teal`, `AppColors.mediumGrey`, `AppColors.lightRed`, `AppColors.gold` with `colorScheme.*` semantic equivalents.
- [x] (`@Pixel` | Skill: `normalize`) Replace 8x8 unread dot with a more visible indicator (10px dot or left accent bar).
- [x] (`@Pixel` | Skill: `delight`) Add `AppInteractionStates.hapticTap()` on tile tap.
- [x] (`@Pixel` | Skill: `delight`) Add ScaleButton wrapper for press feedback.
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: '${type} notification: $title, $timeAgo${!isRead ? ", unread" : ""}')`.
- [x] (`@Sentinel`) Verify all notification types render correctly with semantic colors.
- **GATE CHECK:** NotificationTile polished with semantic colors and accessibility.

### 7.3 NotificationBadgeButton (`@Pixel` | Skill: `animate`)
- [x] (`@Pixel` | Skill: `normalize`) **Convert StatelessWidget → StatefulWidget** with `TickerProviderStateMixin`. NotificationBadgeButton is currently a StatelessWidget and cannot host AnimationController. Add `late final AnimationController _pulseController` and `@override void dispose()` to clean up.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded Positioned(-4, -4) with calculated offset.
- [x] (`@Pixel` | Skill: `normalize`) Replace 16x16 badge with consistent min-size token.
- [x] (`@Pixel` | Skill: `animate`) Add badge entrance animation: scale from 0→1 with `AppMotion.curveSpring`, `AppMotion.fast` duration using `_pulseController`.
- [x] (`@Pixel` | Skill: `animate`) Badge should pulse subtly when count changes (scale 1.0→1.1→1.0, `AppMotion.fast`). Trigger via `didUpdateWidget` when `unreadCount` changes.
- [x] (`@Pixel` | Skill: `harden`) Add `Semantics(label: 'Notifications${unreadCount > 0 ? ", $unreadCount unread" : ""}')`.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** All 3 notification files polished.

---

## Phase 8: Dashboard — Screen & ActivityFeed

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish dashboard screen tabs and redesign ActivityFeedPreview with timeline visual and stagger entrance.
**Why:** DashboardScreen has hardcoded `Duration(milliseconds: 200)` for role button, default Material TabBar. ActivityFeedPreview (174 lines) has basic timeline with hardcoded icon sizes, divider heights, and no animations.
**How:** Replace hardcoded values with tokens. Add tab transitions. Redesign ActivityFeedPreview with enhanced timeline.
**Result:** Dashboard screen and ActivityFeedPreview polished.

### 8.1 DashboardScreen Polish (`@Pixel` | Skill: `normalize`)
> **From screenshots:** "Dashboard" title centered, settings gear icon top-right. 5 tab icons with labels (Overview/Bookings/Work/Wallet/Inbox) — selected tab has teal text, unselected is grey. Tab icons are outlined style. Content area below switches per tab. Same layout in both dark/light. Role switching (freelancer vs client) shows different counter grids and greeting text.
- [x] (`@Pixel` | Skill: `normalize`) Replace `Duration(milliseconds: 200)` in AnimatedContainer with `AppMotion.fast`.
- [x] (`@Pixel` | Skill: `normalize`) Replace `EdgeInsets.only(bottom: 80)` with `AppLayout.bottomNavHeight + AppLayout.spacingStandard`.
- [x] (`@Pixel` | Skill: `normalize`) Replace `PreferredSize(height: 48)` with consistent token.
- [x] (`@Pixel` | Skill: `polish`) Ensure role switch button (settings gear) uses ScaleButton with haptic feedback.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to tab bar and role switch buttons.
- [x] (`@Sentinel`) Verify no hardcoded durations or sizes remain.
- **GATE CHECK:** DashboardScreen tokens normalized.

### 8.2 ActivityFeedPreview Redesign (`@Pixel` | Skill: `arrange`)
> **From screenshots:** Current layout is: "Recent Activity" header + "See All" link, then flat list of items: small type-icon (document/circle) left, bold title + grey subtitle, "4d ago" right. No vertical timeline line, no colored dots. Client view (18.48.22) shows items like "Booking completed", "Task Update", "Booking paid_request_pending" — note raw status strings leaking into display text.
- [x] (`@Pixel` | Skill: `arrange`) Redesign timeline: replace basic icon+text with enhanced visual — vertical line connecting colored dots, each dot colored by activity type.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded `Container(padding: EdgeInsets.all(8))` with `AppDimens.p8`.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded `Container(width: 1, height: 40)` divider with tokenized values.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded `SizedBox(height: 2)`, `SizedBox(height: 16)` with `AppLayout.spacingTight`, `AppLayout.spacingSection`.
- [x] (`@Pixel` | Skill: `colorize`) Activity type colors: booking → `colorScheme.primary`, task → `colorScheme.info`, status_change → `colorScheme.warning`.
- [x] (`@Pixel` | Skill: `animate`) Stagger entrance for activity rows: fade + slide, `AppMotion.staggerMedium` (50ms), `AppMotion.standard` (300ms).
- [x] (`@Pixel` | Skill: `animate`) "See All" → expand/collapse: preserve existing "See All" link, add `AnimatedCrossFade` or `AnimatedSize` with `AppMotion.standard` duration for showing more items.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to timeline: `Semantics(label: '$activityType: $description, $timeAgo')`.
- [x] (`@Pixel` | Skill: `harden`) Enhance empty state with descriptive text and icon.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** ActivityFeedPreview fully redesigned with timeline visual, stagger, and accessibility.

---

## Phase 9: Dashboard — Work Tab & Bookings Tab

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Polish Work Tab sub-tabs and Bookings Tab with enhanced empty states, token normalization, and accessibility.
**Why:** Work Tab (464 lines) has hardcoded sub-tab heights (40px), empty state heights (0.5 * screenHeight), opacity values (0.7 for dimming). Bookings Tab (144 lines) has basic empty state and no skeleton loading.
**How:** Replace hardcoded values. Enhance empty states. Add Semantics. Add skeleton loading to bookings.
**Result:** Both tabs polished with tokens and rich states.

> **From screenshots:**
> - Sub-tabs are segmented control style: selected tab has teal fill, others have border outline. Active(0)/Done(16)/Cancelled.
> - Empty states (Active, Cancelled) are very minimal: just an icon + single line text "No active work." centered.
> - Done tab shows WorkItemCard items with type badges (CUSTOM OFFER/BOOKING/TASK), user avatars, COMPLETED status — items appear full opacity in screenshots (dimming may apply to specific sub-states, not the whole card). Verify exact 0.7 usage in code.
> - WorkItemCard already redesigned in Phase 2 — DO NOT TOUCH the card widget itself, only the Work Tab container/layout.

### 9.1 Work Tab Token Replacement (`@Pixel` | Skill: `normalize`)
- [x] (`@Pixel` | Skill: `normalize`) Replace `Container(height: 40)` sub-tab bar height with `AppLayout.statusIndicatorHeight` (40).
- [x] (`@Pixel` | Skill: `normalize`) Replace `BorderRadius.circular(AppDimens.r10)` with direct `AppDimens.r10` usage.
- [x] (`@Pixel` | Skill: `normalize`) **KEEP** `Opacity(opacity: isDimmed ? 0.7 : 1.0)` as-is — 0.7 is intentional design for completed/cancelled items (readable but de-emphasized). `AppInteractionStates.disabledOpacity` (0.38) would make them nearly invisible. **Verify in code** exactly where 0.7 is applied (screenshots show Done items at full opacity — dimming may apply within specific status branches only). Add a doc comment: `// 0.7 dimming — intentional: completed items should remain readable`.
- [x] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(height: 0.5 * screenHeight)` empty state sizing with a more responsive approach.
- [x] (`@Pixel` | Skill: `normalize`) Replace all hardcoded spacing (p8, p12, p16, p20, p24) — verify they use AppDimens correctly.
- [x] (`@Sentinel`) Verify no raw hardcoded values remain.
- **GATE CHECK:** Work Tab tokens normalized.

### 9.2 Work Tab Empty States & Polish (`@Pixel` | Skill: `clarify`)
- [x] (`@Pixel` | Skill: `clarify`) Enhance empty states for each sub-tab:
  - Active: "No active work — browse tasks to get started" with CTA.
  - Done: "No completed work yet" with subtle check icon.
  - Cancelled: "No cancelled work" with muted styling.
- [x] (`@Pixel` | Skill: `animate`) Fade-in for empty states with `AppMotion.standard`.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to "Needs Your Review" section header.
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to sub-tab bar and each sub-tab content.
- [x] (`@Sentinel`) Verify all three sub-tabs render correctly in both roles.
- **GATE CHECK:** Work Tab polished with rich empty states.

### 9.3 Bookings Tab Polish (`@Pixel` | Skill: `normalize`)
> **From screenshots:** Bookings Tab has "Upcoming" and "Past" section headers (bold text). Booking cards show title, "Due 2026-04-10 18:32" in colored text (red for overdue?, teal for normal), "Delivery: X days", and status pill badges (green COMPLETED, red CANCELLED). Cards are clean card-style tiles. No empty state screenshot provided.
- [x] (`@Pixel` | Skill: `normalize`) Replace `SizedBox(height: 0.6 * screenHeight)` empty state with responsive sizing.
- [x] (`@Pixel` | Skill: `normalize`) Replace hardcoded icon size (48) with `AppLayout.iconFeature`.
- [x] (`@Pixel` | Skill: `clarify`) Enhance empty state: "No bookings yet — discover services to book" with CTA. Reference the Inbox tab empty state pattern ("No Proposals Yet" with icon + subtitle) for consistency.
- [x] (`@Pixel` | Skill: `harden`) Add skeleton loading while bookings load (reuse SkeletonBookingCard or simple skeleton list).
- [x] (`@Pixel` | Skill: `harden`) Add Semantics to section headers ("Upcoming", "Past").
- [x] (`@Pixel` | Skill: `harden`) Verify status badge pills (COMPLETED/CANCELLED) use semantic colors from `colorScheme.success` / `colorScheme.danger` — may already be correct from Phase 2 StatusBadge.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** Bookings Tab polished with skeleton loading and rich empty state.

---

## Phase 10: Skeleton Updates

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Ensure all skeleton variants in `skeleton_card.dart` match their redesigned counterparts' layouts.
**Why:** Skeletons were written to match original card layouts. After redesigning ConversationListTile, MessageBubble, and notification tiles, the skeletons may need dimension updates.
**How:** Compare skeleton dimensions with redesigned widget dimensions. Update mismatches.
**Result:** Skeletons accurately match redesigned layouts.

### 10.1 Skeleton Audit (`@Pixel` | Skill: `audit`)
- [x] (`@Pixel` | Skill: `audit`) Compare `SkeletonConversationTile` dimensions (52px avatar) with redesigned `ConversationListTile` avatar size — update if changed.
- [x] (`@Pixel` | Skill: `audit`) Compare `SkeletonMessageBubble` dimensions (70% width, 14h+12h lines) with redesigned `MessageBubble` — update if changed.
- [x] (`@Pixel` | Skill: `audit`) Verify skeleton border radii match redesigned card border radii.
- [x] (`@Pixel` | Skill: `audit`) Verify skeleton padding matches redesigned card padding.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** All skeletons match their redesigned counterparts.

---

## Phase 10A: Widget Tests

**Primary Agent(s):** `@Sentinel`, `@Pixel`
**Goal:** Add widget tests for new behavior introduced in this phase — message grouping, date separators, notification skeleton transitions, and stagger guard.
**Why:** 17 files modified with new parameters (`isFirstInGroup`, `isLastInGroup`), new sealed types (`_ChatListItem`), and new animation guards (`_hasAnimatedEntrance`). Zero tests in the original plan would leave regressions undetected.
**How:** Write targeted widget tests for the highest-risk new logic.
**Result:** Regression-safe coverage for grouping, separators, and animation guards.

### 10A.1 MessageBubble Grouping Tests (`@Sentinel`)
- [x] (`@Sentinel`) Test `MessageBubble` renders with full border radius when `isFirstInGroup: true, isLastInGroup: true` (solo message).
- [x] (`@Sentinel`) Test `MessageBubble` renders with reduced corner radius on consecutive side when `isFirstInGroup: false` (middle of group).
- [x] (`@Sentinel`) Test `MessageBubble` hides avatar/sender when `isFirstInGroup: false`.
- [x] (`@Sentinel`) Test `MessageBubble` shows timestamp only when `isLastInGroup: true`.

### 10A.2 Date Separator Tests (`@Sentinel`)
- [x] (`@Sentinel`) Test that `ChatScreen` inserts a date separator between messages on different calendar days.
- [x] (`@Sentinel`) Test that no date separator appears between messages on the same day.
- [x] (`@Sentinel`) Test date separator displays correct formatted date text.

### 10A.3 Notification Skeleton Tests (`@Sentinel`)
- [x] (`@Sentinel`) Test `NotificationsModal` shows skeleton tiles during loading state.
- [x] (`@Sentinel`) Test skeleton-to-content crossfade completes without errors.

### 10A.4 Verification (`@Sentinel`)
- [x] (`@Sentinel`) Run `flutter test` — all new tests must pass.
- [x] (`@Sentinel`) Run `flutter analyze` — must pass clean.
- **GATE CHECK:** All widget tests pass, `flutter analyze` clean.

---

## Phase 11: QA & Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 11.1 Static Analysis
- [x] (`@Sentinel`) Run `flutter analyze` — must pass with zero errors, zero warnings.
- [x] (`@Sentinel`) Run `dart format .` — must produce no changes.

### 11.2 Test Suite
- [x] (`@Sentinel`) Run `flutter test` — must produce zero new failures.
- [x] (`@Sentinel`) If test failures occur, document each with file name, test name, and root cause.

### 11.3 Architecture Guard
- [x] (`@Sentinel`) Verify no new imports of Supabase in View files.
- [x] (`@Sentinel`) Verify no new imports of feature code from core/widgets/.
- [x] (`@Sentinel`) Verify no ViewModel logic added to View files.

### 11.4 Token Compliance Audit
- [x] (`@Sentinel`) Grep for `Duration(milliseconds:` in all modified files — count should be 0 (all replaced with AppMotion tokens, except existing ViewModel debounces which are out of scope).
- [x] (`@Sentinel`) Grep for `BoxShadow(` in all modified files — count should be 0 (all use AppDecorations.elevation).
- [x] (`@Sentinel`) Grep for `fontSize:` in all modified View files — count should be 0 (all use AppTypography).
- [x] (`@Sentinel`) Grep for raw `Color(0x` in all modified View files — count should be 0.
- [x] (`@Sentinel`) Verify all modified files have Semantics coverage for interactive elements.

### 11.5 Visual Spot Check
- [x] (`@Pixel` | Skill: `audit`) Run app on device/emulator. Navigate to: Messages (inbox), Chat (active conversation), Chat (empty), Notifications, Dashboard (all tabs). Verify:
  - Stagger entrances play on first load only.
  - Date separators appear correctly in chat.
  - Send button animates grey→teal on text input.
  - Scroll-to-bottom FAB appears when scrolled up.
  - Notification skeleton loads then transitions to content.
  - Activity timeline renders correctly.
  - All empty states look rich and contextual.
  - Dark mode renders correctly.
- [x] (`@Pixel` | Skill: `audit`) Check for layout overflow on small screens (360px width).
- **GATE CHECK:** All tests pass. All tokens verified. Visual spot check clean.

---

## Phase 12: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@SlineDocs`

- [x] (`@SlineDocs`) Update session log `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md` with execution timeline, discoveries, and agent improvement notes.
- [x] (`@SlineDocs`) Update `Sline_everything/STRUCTURE.md` if file structure changed.
- [x] (`@SlineDocs`) Ensure session log references this plan file.
- **GATE CHECK:** Docs and session log aligned with implementation.

---

## 7) Acceptance Criteria (MANDATORY)

1. **Chat — messages_screen.dart:** Stagger entrance on first load. Rich empty state with CTA. Unread badge animated. All tokens normalized. Semantics on list and empty state.
2. **Chat — conversation_list_tile.dart:** Animated typing dots. Unread pill badge with count. All tokens from design system. Semantics on each tile.
3. **Chat — chat_screen.dart:** Date separators between day groups. Animated send button (grey→teal). Scroll-to-bottom FAB with animation. Rich empty state. Input bar polished. Full Semantics.
4. **Chat — message_bubble.dart:** Message grouping support (isFirstInGroup/isLastInGroup). Status icon animation (send→delivered→read). Semantic colors for status. Semantics on each bubble.
5. **Chat — offer_message_bubble.dart:** All hardcoded colors replaced with semantic tokens. Action buttons with haptics. Full Semantics.
6. **Chat — create_offer_sheet.dart:** Token normalization. Validation shake animation. Semantics on form fields.
7. **Chat — attachment_message_tile.dart:** Shimmer loading placeholder. Semantic colors. Semantics label.
8. **Chat — chat_context_widget.dart:** Token normalization. Semantics.
9. **Notifications — notifications_modal.dart:** Skeleton loading (no CircularProgressIndicator). Stagger entrance. Rich empty/error states. Semantics.
10. **Notifications — notification_tile.dart:** Semantic colors. ScaleButton haptics. Semantics.
11. **Notifications — notification_badge_button.dart:** Animated badge entrance (spring scale). Pulse on count change. Semantics.
12. **Dashboard — dashboard_screen.dart:** Token normalization. Role switch haptics. Semantics on tabs.
13. **Dashboard — activity_feed_preview.dart:** Enhanced timeline visual. Stagger entrance. Semantic colors. Expand/collapse animation. Semantics.
14. **Dashboard — work_tab.dart:** Token normalization. Enhanced empty states. Semantics on sub-tabs.
15. **Dashboard — bookings_tab.dart:** Skeleton loading. Rich empty state. Semantics on sections.
16. **Skeleton updates:** SkeletonConversationTile and SkeletonMessageBubble match redesigned layouts.
17. **Zero regressions:** `flutter analyze` clean. `flutter test` passes. No new architecture violations.
18. **Zero hardcoded tokens** in modified View files: no raw Duration, BoxShadow, fontSize, or Color(0x values.

## 8) Rollback Plan

- **All changes are View-layer only and non-breaking:**
  - Every modified file can be individually reverted with `git checkout -- <file>`.
  - No ViewModel, Service, Repository, or Backend changes to revert.
  - No database, RLS, or storage changes.
  - No new dependencies added.
- **Rollback strategy:** `git revert` the Phase 5 commit(s). Pure UI changes with zero data-layer impact.
- **Forward-fix preference:** Individual file fixes are preferred over full revert. If a specific animation causes issues, disable it by replacing with `Duration.zero` while keeping other improvements.
- **Risk areas:**
  - Message grouping logic in ChatScreen — if grouping algorithm has edge cases, revert grouping flags to always-true.
  - Date separators — if performance degrades on long conversations, add a max-messages threshold.
  - Stagger animations — if they feel slow, reduce stagger delay or disable.

## 9) References (From Scan)

### Docs Scanned
- `Sline_everything/DEVELOPER_GUIDE.md` — MVVM patterns, error handling
- `.impeccable.md` — Design context, brand personality, NO GLASS policy
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — Master Plan Phase 6 (Chat) and Phase 7 (Dashboard)
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Token definitions and naming conventions
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md` — Phase 2 card redesign scope (what was already done)
- `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md` — Phase 4 discovery scan patterns

### Code Paths Scanned
- `lib/features/chat/` — 24 files (views, widgets, models, viewmodels, services, attachments)
- `lib/features/notifications/` — 8 files (views, widgets, models, viewmodels, services)
- `lib/features/dashboard/view/` — 10 files (screen, tabs, widgets)
- `lib/core/theme/` — all token files (app_motion, app_states, app_colors, app_layout, app_dimens, app_decorations, app_typography, app_theme)
- `lib/core/widgets/` — skeleton_card.dart, scale_button.dart, app_card.dart, app_card_container.dart, status_badge.dart

### Existing .TODO/ Artifacts
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — parent plan
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Phase 0 token plan
- `.TODO/PLAN_Phase4_HomeDiscovery_2026-04-08.md` — Phase 4 plan

### Session Log
- **Path:** `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`

## 10) Scan Evidence (Mandatory Appendix)

### File Line Counts
| File | Lines | Status |
|------|-------|--------|
| `lib/features/chat/view/chat_screen.dart` | 600 | To redesign |
| `lib/features/chat/view/messages_screen.dart` | 271 | To redesign |
| `lib/features/chat/view/widgets/message_bubble.dart` | 105 | To redesign |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | 255 | To redesign |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | 379 | To redesign |
| `lib/features/chat/view/widgets/create_offer_sheet.dart` | 209 | To redesign |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | 144 | To redesign |
| `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | 266 | To redesign |
| `lib/features/notifications/view/notifications_modal.dart` | 135 | To redesign |
| `lib/features/notifications/view/widgets/notification_tile.dart` | 122 | To redesign |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | 88 | To redesign |
| `lib/features/dashboard/view/dashboard_screen.dart` | 332 | To polish |
| `lib/features/dashboard/view/widgets/activity_feed_preview.dart` | 174 | To redesign |
| `lib/features/dashboard/view/tabs/work_tab.dart` | 464 | To polish |
| `lib/features/dashboard/view/tabs/bookings_tab.dart` | 144 | To polish |
| `lib/core/widgets/skeleton_card.dart` | 655 | Skeleton updates |
| **TOTAL** | **4,343** | |

### Design System Token Availability
| Token System | Status | Key APIs Available |
|-------------|--------|-------------------|
| AppMotion | ✅ Complete | micro/fast/standard/slow/emphasis/dramatic/shimmer, 7 curves, 4 scales, 3 staggers, respectMotion() |
| AppStates | ✅ Complete | disabledOpacity, hoverOverlay, pressedOverlay, flashOverlay, focusRing, loading, shake, flash, hapticTap/Selection/Success/Heavy |
| AppDecorations | ✅ Complete | elevation(0-4, isDark), glass, bottomNav, inputField, hotBadge, authorInitials |
| AppColors semantic | ✅ Complete | success/successMuted, warning/warningMuted, info/infoMuted, danger/dangerMuted, hoverOverlay, pressedOverlay, focusRing, disabledFill |
| AppLayout | ✅ Complete | cardPadding, avatarTiny/Small/Default/Medium/Large/Hero, buttonHeight/Compact/Small, spacingTight/Standard/Section/Screen/Large, iconTiny/Standard/Feature, thumbnailSmall/Medium |
| AppTypography | ✅ Complete | 14 styles with explicit heights (1.0-1.5), letter-spacing |
| AppDimens | ✅ Complete | p0-p100 (25 values), r4-r50 (12 values), 3 icon sizes |

### Constructor Signatures (Key View Files)
- `ChatScreen({required Conversation conversation})` — StatefulWidget
- `MessagesScreen()` — StatefulWidget (no params)
- `MessageBubble({required text, required time, required isMine, required status})` — StatelessWidget
- `ConversationListTile({required conversation, required onTap})` — StatelessWidget
- `OfferMessageBubble({title, description, price, deliveryDays, status, isMine, time, onAccept, onDecline, offerId, rawStatus, onCancel, onDeliver, onComplete})` — StatelessWidget
- `CreateOfferSheet()` — StatefulWidget (modal)
- `NotificationsModal.show(context)` — returns NotificationItem?
- `NotificationTile({required notification, required onTap})` — StatelessWidget
- `NotificationBadgeButton()` — StatelessWidget
- `DashboardScreen({tabViews})` — StatelessWidget
- `ActivityFeedPreview({limit})` — StatelessWidget
- `WorkTab()` — StatefulWidget
- `BookingsTab()` — StatelessWidget

### Singleton/Static State
- ChatViewModel uses `_mounted` guard flag — no singleton, but dispose safety relevant
- NotificationViewModel subscribes to auth state — disconnects on sign out
- No static singletons touched in View layer

### Provider Dependencies
- `ChatViewModel` — consumed by ChatScreen and MessagesScreen via `Provider.of` and `Consumer`
- `NotificationViewModel` — consumed by NotificationsModal and NotificationBadgeButton
- `DashboardViewModel` — consumed by all dashboard tabs via `Consumer`
- `WalletViewModel` — consumed by OverviewTab (lazy load)
- `SavedTasksViewModel` — consumed by task cards (already redesigned)

### Animation Baseline (Before Redesign)
| Widget | Current Animation | Token Used |
|--------|------------------|------------|
| ConversationListTile | AnimatedContainer 200ms | None (hardcoded) |
| DashboardCountersGrid | IntTween count-up | AppMotion.emphasis ✅ |
| DashboardCountersGrid | Shimmer pulse | AppMotion.shimmer ✅ |
| DashboardOfferCard | Pulse 2s | Duration(seconds: 2) hardcoded |
| DashboardScreen | AnimatedContainer 200ms | None (hardcoded) |
| All others | None | N/A |

### Anti-Pattern Counts in Target Files
| Pattern | Count | Files |
|---------|-------|-------|
| Hardcoded Duration | 3 | conversation_list_tile, dashboard_screen, dashboard_offer_card |
| `AppColors.*` direct | 40+ | All chat and notification files |
| `withValues(alpha:` | 15+ | conversation_list_tile, offer_message_bubble, attachment_message_tile |
| Hardcoded px sizes | 20+ | chat_screen (46px), conversation_list_tile (48px, 14x14), offer_message_bubble (14px) |
| Missing Semantics | 17 | All target files |

END.
