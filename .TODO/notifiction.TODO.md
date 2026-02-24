# notifiction — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview

- What this feature does: renders the notification bell badge and modal list, streams notifications from Supabase, marks notifications read, and deep-links on tap via `DeepLinkService`. File References: `lib/features/home/view/home_screen.dart:104-145`, `lib/features/notifications/view/widgets/notification_badge_button.dart:10-75`, `lib/features/notifications/view/notifications_modal.dart:9-97`, `lib/features/notifications/viewmodels/notification_view_model.dart:9-87`, `lib/features/notifications/services/notification_service.dart:5-157`, `lib/core/services/deep_link_service.dart:18-126`.
- Boundaries (in scope): `lib/features/notifications/**` plus direct dependencies/imports/calls used by the feature (`lib/main.dart`, `lib/features/home/view/home_screen.dart`, `lib/core/services/deep_link_service.dart`, `lib/core/utils/format_date.dart`) and direct notification API consumers (chat/tasks/booking callsites only). File References: `lib/main.dart:152-166`, `lib/features/home/view/home_screen.dart:104-145`, `lib/core/services/deep_link_service.dart:1-254`, `lib/core/utils/format_date.dart:13-25`, `lib/features/chat/services/message_service.dart:281-309`, `lib/features/tasks/services/task_service.dart:199-226`, `lib/features/tasks/services/task_requests_service.dart:132-154`, `lib/features/tasks/services/task_requests_service.dart:246-306`, `lib/features/booking/services/booking_service.dart:123-134`, `lib/features/booking/services/booking_service.dart:249-272`.
- Boundaries (out of scope): full audits of chat/tasks/booking feature internals beyond notification dispatch callsites. UNVERIFIED (scope control decision; no missing file).
- Entry points (screens/routes/calls): home header bell widget entry (`NotificationBadgeButton`), global `NotificationViewModel` provider creation, notification modal tap path, and direct notification dispatch calls from chat/tasks/booking services. File References: `lib/features/home/view/home_screen.dart:144-145`, `lib/main.dart:156-166`, `lib/features/notifications/view/notifications_modal.dart:46-61`, `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270`.

## 1) Feature Map (Current Repo State)

- Primary feature files (with references):
  - Model: `NotificationItem` + `NotificationType` parsing/serialization. File Reference: `lib/features/notifications/models/notification_model.dart:3-67`.
  - Service: Supabase reads/realtime/updates/inserts/grouping logic. File Reference: `lib/features/notifications/services/notification_service.dart:5-157`.
  - ViewModel: subscription lifecycle, unread count, tap handler, mark read APIs. File Reference: `lib/features/notifications/viewmodels/notification_view_model.dart:9-87`.
  - Modal UI: list rendering, item tap handling, mark-all action, sheet helper. File Reference: `lib/features/notifications/view/notifications_modal.dart:9-97`.
  - Badge UI: unread badge rendering and bottom-sheet opening. File Reference: `lib/features/notifications/view/widgets/notification_badge_button.dart:10-75`.
  - Tile UI: notification row rendering + timestamp formatting. File Reference: `lib/features/notifications/view/widgets/notification_tile.dart:8-129`.
- Direct dependencies (with references):
  - Global provider wiring creates `NotificationViewModel` app-wide. File Reference: `lib/main.dart:152-166`.
  - Home screen embeds notification bell in header. File Reference: `lib/features/home/view/home_screen.dart:104-145`.
  - Notification tap uses `DeepLinkService` for routing and data fetch navigation. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`, `lib/core/services/deep_link_service.dart:33-126`.
  - Timestamp formatting depends on shared date utility. File References: `lib/features/notifications/view/widgets/notification_tile.dart:50-52`, `lib/core/utils/format_date.dart:13-25`.
  - Reverse direct consumers (notification dispatch API surface): chat/tasks/booking services call `NotificationService.createNotification/createOrUpdateNotification`. File References: `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270`.
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs):
  - Table `notifications` reads (`select/order/limit`). File Reference: `lib/features/notifications/services/notification_service.dart:8-23`.
  - Table `notifications` realtime stream (`stream(primaryKey: ['id'])`). File Reference: `lib/features/notifications/services/notification_service.dart:25-35`.
  - Table `notifications` updates (`markAsRead`, `markAllAsRead`). File Reference: `lib/features/notifications/services/notification_service.dart:37-67`.
  - Table `notifications` inserts (`createNotification`, `createOrUpdateNotification`). File Reference: `lib/features/notifications/services/notification_service.dart:69-157`.
  - SQL migration also inserts into `public.notifications` with a different payload shape. File Reference: `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416`.
  - Supabase schema docs describe `notifications` columns expected by app (`message`, `is_read`, `metadata`). File Reference: `Sline_everything/SUPABASE_SETUP.md:698-714`.
  - Historical log documents notification policy names (`insert_any`, `select_own`, `update_own`). File Reference: `Sline_everything/Sline_Log.md:536-545`.
  - Actual `public.notifications` policy DDL in local repo: UNVERIFIED (no matching SQL policy definition found in `supabase/migrations` by scan; missing source file for notifications RLS policy SQL).
  - Feature-local RPC / storage bucket / edge function usage: UNVERIFIED by absence scan (no direct evidence file because claim is based on no matches within `lib/features/notifications/**`).

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| E-01 | Home screen renders the notification bell (`NotificationBadgeButton`) in the header. | `lib/features/home/view/home_screen.dart:104-145` | Low | Confirms user-visible entry point. |
| E-02 | App creates `NotificationViewModel` as a global provider during app startup. | `lib/main.dart:152-166` | Medium | Enables app-wide lifecycle implications. |
| E-03 | `NotificationViewModel` auto-subscribes on construction and computes unread count by scanning list. | `lib/features/notifications/viewmodels/notification_view_model.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:26-31`, `lib/features/notifications/viewmodels/notification_view_model.dart:33-50` | Medium | Relevant for lifecycle/performance. |
| E-04 | Notification tap handler in ViewModel uses `BuildContext`/`Provider`, calls `markAsRead` without `await`, then deep-links. | `lib/features/notifications/viewmodels/notification_view_model.dart:58-68` | High | MVVM boundary + sequencing risk. |
| E-05 | Modal item tap pops the sheet and then passes the same modal `context` into `vm.handleNotificationTap(...)`. | `lib/features/notifications/view/notifications_modal.dart:46-61` | High | Disposed-context race risk. |
| E-06 | Read and realtime stream queries access `notifications` without explicit user filter. | `lib/features/notifications/services/notification_service.dart:8-23`, `lib/features/notifications/services/notification_service.dart:25-35` | High | RLS-only scoping. |
| E-07 | `markAsRead` updates by `id` only; `markAllAsRead` uses current user filter. | `lib/features/notifications/services/notification_service.dart:37-67` | High | Inconsistent client-side scoping. |
| E-08 | `createNotification` inserts arbitrary `user_id` on client and swallows errors (no rethrow). | `lib/features/notifications/services/notification_service.dart:69-94` | Critical | Cross-user write surface and silent failure mode. |
| E-09 | `createOrUpdateNotification` uses `.maybeSingle()`, matches `related_entity_id` with `relatedEntityId ?? ''`, and swallows errors. | `lib/features/notifications/services/notification_service.dart:96-157` | High | Duplicate/lossy notification behavior risk. |
| E-10 | App notification model expects `message`, `is_read`, `metadata`; unknown type falls back to `system`. | `lib/features/notifications/models/notification_model.dart:31-43`, `lib/features/notifications/models/notification_model.dart:61-65` | High | Schema/type drift can be hidden. |
| E-11 | Local SQL migration inserts notification rows with `body`, `data`, `read` and custom type values (e.g., `offer_awarded`, `payment_required`). | `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416` | Critical | Potential app/DB contract mismatch. |
| E-12 | Supabase setup docs define `notifications` schema with `message`, `is_read`, `metadata`. | `Sline_everything/SUPABASE_SETUP.md:698-714` | Medium | Supports contract comparison. |
| E-13 | Historical log claims notification RLS policy names include `insert_any`, `select_own`, `update_own`. | `Sline_everything/Sline_Log.md:536-545` | High | Historical-only; not source of truth. |
| E-14 | `DeepLinkService` imports notification model + multiple feature services/screens and logs notification entity IDs. | `lib/core/services/deep_link_service.dart:1-16`, `lib/core/services/deep_link_service.dart:24-31`, `lib/core/services/deep_link_service.dart:33-46`, `lib/core/services/deep_link_service.dart:82-126` | Medium | Cross-feature coupling + metadata logging. |
| E-15 | `AppLogger` logs only in debug mode (`kDebugMode`), prints messages/errors, and `AppLogger.e` reports to crash reporting. | `lib/core/services/logger_service.dart:82-92`, `lib/core/services/logger_service.dart:115-147`, `lib/core/services/logger_service.dart:162-182` | Medium | Clarifies logging/telemetry exposure paths. |
| E-16 | Badge button uses broad `Consumer<NotificationViewModel>` and inlines `showModalBottomSheet`. | `lib/features/notifications/view/widgets/notification_badge_button.dart:17-31`, `lib/features/notifications/view/widgets/notification_badge_button.dart:57-59` | Medium | Rebuild scope + duplicate sheet invocation logic. |
| E-17 | Modal defines `NotificationsModal.show(...)`, handles loading/empty/list states, and exposes mark-all action, but no `vm.error` rendering branch. | `lib/features/notifications/view/notifications_modal.dart:12-19`, `lib/features/notifications/view/notifications_modal.dart:36-63`, `lib/features/notifications/view/notifications_modal.dart:72-96` | Medium | Unused helper candidate + silent error UX. |
| E-18 | Tile uses `formatFriendlyTime(notification.createdAt)` and contains a stale cleanup comment. | `lib/features/notifications/view/widgets/notification_tile.dart:19-22`, `lib/features/notifications/view/widgets/notification_tile.dart:50-52` | Low | Code-quality + timestamp rendering dependency. |
| E-19 | `formatFriendlyTime()` fallback renders raw `time.day/month/year` without explicit local conversion. | `lib/core/utils/format_date.dart:13-25` | Low | Possible date-label inconsistency. |
| E-20 | Integration test opens notifications and explicitly fails if no notifications exist in environment. | `integration_test/notification_deeplink_flow_test.dart:14-50` | Medium | Coverage exists but is environment-dependent. |
| E-21 | Integration test verifies supported deep-link types only after selecting a live notification row. | `integration_test/notification_deeplink_flow_test.dart:53-145` | Medium | Smoke coverage, not deterministic fixture coverage. |
| E-22 | Notification payloads include raw message content / price text before dispatch. | `lib/features/chat/services/message_service.dart:281-309` | Medium | PII/data minimization consideration. |
| E-23 | Direct notification dispatch is called from chat/tasks/booking service callsites (reverse direct consumers). | `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270` | High | Cross-user notification writes originate in client features. |
| E-24 | `NotificationViewModel` exposes `error`, but feature search only found the getter declaration (no `vm.error` reads in notifications UI). | `lib/features/notifications/viewmodels/notification_view_model.dart:24` | Medium | UNVERIFIED by absence scan for UI reads (`rg "vm\\.error"` in `lib/features/notifications`). |
| E-25 | `getNotifications()` search returned only the method definition. | `lib/features/notifications/services/notification_service.dart:8-23` | Low | UNVERIFIED by search-count inference (no external callsite found). |
| E-26 | `NotificationsModal.show(...)` callsite search returned no matches. | UNVERIFIED (no matches for `NotificationsModal.show(` in `lib`, `test`, `integration_test`) | Low | Supports unused helper candidate. |
| E-27 | Local `supabase/migrations` search returned no explicit `notifications` policy DDL matches. | UNVERIFIED (no matches for `policy .*notifications|on public.notifications|on notifications`) | Critical | Missing local RLS source-of-truth file for verification. |

## 3) Findings

### 3.1 Security (Highest Priority)

- `SEC-01` (Evidence: `E-08`, `E-23`, `E-13`, `E-27`) — Client-side cross-user notification writes are possible through `NotificationService.createNotification/createOrUpdateNotification`, which accept an arbitrary `userId` and are called from multiple client feature services. File References: `lib/features/notifications/services/notification_service.dart:69-157`, `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270`, `Sline_everything/Sline_Log.md:536-545`. Impact: broken access control if RLS allows insert-any or weak `WITH CHECK`; silent notification loss if RLS blocks these writes because errors are swallowed. Exploit/Failure scenario: a compromised client path or bug sends a notification row to another user by supplying a different `userId`, or production silently stops sending notifications after policy tightening because the client catches and ignores insert errors.

- `SEC-02` (Evidence: `E-06`, `E-07`, `E-27`) — Notification reads/streams and single-row updates rely on RLS as the only scoping mechanism and omit client-side user predicates in `getNotifications`, `streamNotifications`, and `markAsRead`. File References: `lib/features/notifications/services/notification_service.dart:8-23`, `lib/features/notifications/services/notification_service.dart:25-35`, `lib/features/notifications/services/notification_service.dart:37-43`. Impact: if RLS drifts or is misconfigured, the feature can over-read or mutate other users’ rows; even with correct RLS, missing filters increase blast radius and debugging ambiguity. Exploit/Failure scenario: a permissive/buggy policy exposes cross-user rows in the realtime stream or allows `markAsRead` on any row by ID.

- `SEC-03` (Evidence: `E-14`, `E-15`) — Deep-link handling logs notification entity type and ID in debug logs. File References: `lib/core/services/deep_link_service.dart:33-46`, `lib/core/services/logger_service.dart:82-92`, `lib/core/services/logger_service.dart:115-147`. Impact: metadata leakage in shared debug environments/log captures. Exploit/Failure scenario: QA/staging logs expose internal IDs tied to user activity, which can be correlated with other logs/screenshots.

- `SEC-04` (Evidence: `E-22`, `E-08`) — Notification payloads may contain raw message content and pricing details before insertion. File References: `lib/features/chat/services/message_service.dart:281-309`, `lib/features/notifications/services/notification_service.dart:69-94`. Impact: PII/data minimization risk if notifications are visible on shared devices/screens or if logs/analytics later capture payload text. Exploit/Failure scenario: private chat content is surfaced in notification UI or screenshots when a shorter generic preview would be safer.

- `SEC-05` (Evidence: `E-13`, `E-27`) — The current repo does not contain verifiable `notifications` RLS policy DDL, so authorization for this feature is not locally auditable from source-of-truth SQL. File References: `Sline_everything/Sline_Log.md:536-545`. Impact: security review cannot prove actual deployed authz rules. Exploit/Failure scenario: a stale doc says `select_own/update_own`, but deployed policy differs and exposes notification data. Status: UNVERIFIED (missing local `notifications` policy SQL file in `supabase/migrations`).

### 3.2 Data Integrity

- `DATA-01` (Evidence: `E-10`, `E-11`, `E-12`) — App notification row contract and local SQL migration contract do not match (`message/is_read/metadata` vs `body/read/data`, plus different type values). File References: `lib/features/notifications/models/notification_model.dart:31-43`, `lib/features/notifications/models/notification_model.dart:61-65`, `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416`, `Sline_everything/SUPABASE_SETUP.md:698-714`. Impact: runtime parse failures, missing fields, or silent misclassification to `system`. Exploit/Failure scenario: a DB function inserts `body/read/data`, the client tries to parse `message/is_read/metadata`, and the modal crashes or renders corrupted rows.

- `DATA-02` (Evidence: `E-04`) — `handleNotificationTap()` does not `await` `markAsRead()` before deep-link navigation. File Reference: `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`. Impact: race conditions between read-state mutation and navigation/error handling; read state may be inconsistent with actual user navigation outcome. Exploit/Failure scenario: navigation fails, but the notification is still marked read (or read update fails after UI moved on with no user feedback).

- `DATA-03` (Evidence: `E-05`, `E-04`) — Modal tap handler pops the bottom sheet and then uses the popped modal context for provider lookup/navigation via the ViewModel. File References: `lib/features/notifications/view/notifications_modal.dart:54-58`, `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`. Impact: intermittent invalid-context or deactivated-widget errors during deep-link navigation. Exploit/Failure scenario: on slower frames/devices, `context.read<DeepLinkService>()` or navigation paths run after the modal context is disposed, causing tap failures or exceptions.

- `DATA-04` (Evidence: `E-09`) — `createOrUpdateNotification()` cannot coalesce rows when `relatedEntityId` is `null` because it compares DB `related_entity_id` to `''`, and duplicate matches can error under `.maybeSingle()` with swallowed catch. File Reference: `lib/features/notifications/services/notification_service.dart:110-117`, `lib/features/notifications/services/notification_service.dart:149-155`. Impact: duplicate notifications or dropped updates under contention/data drift. Exploit/Failure scenario: two unread notifications exist for same type/user; `.maybeSingle()` errors, catch swallows it, and the intended insert/update path never completes.

- `DATA-05` (Evidence: `E-10`, `E-19`) — Older date labels may show UTC calendar date instead of local calendar date because the model stores UTC and `formatFriendlyTime()` fallback prints raw `time.day/month/year`. File References: `lib/features/notifications/models/notification_model.dart:41`, `lib/core/utils/format_date.dart:13-25`. Impact: user-visible incorrect date labels near timezone boundaries. Exploit/Failure scenario: a notification created late at night UTC appears with the previous/next day date in local timezone.

### 3.3 Architecture

- `ARCH-01` (Evidence: `E-04`) — `NotificationViewModel` violates strict MVVM boundaries by accepting `BuildContext`, using `Provider`, and directly orchestrating navigation. File Reference: `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`. Impact: ViewModel becomes UI-context dependent, harder to test, and fragile across widget lifecycle changes. Exploit/Failure scenario: a future refactor moves provider scope and notification taps start failing because ViewModel assumes widget-context access.

- `ARCH-02` (Evidence: `E-14`) — `DeepLinkService` in `core/services` depends on multiple feature services/screens (including notifications model), creating broad cross-feature coupling in a core layer. File References: `lib/core/services/deep_link_service.dart:1-16`, `lib/core/services/deep_link_service.dart:24-31`. Impact: architecture drift and change ripple across unrelated features. Exploit/Failure scenario: changing a feature screen constructor or service API breaks core routing service and notification taps simultaneously.

- `ARCH-03` (Evidence: `E-02`, `E-03`) — Notifications realtime subscription starts eagerly at app provider creation and is not explicitly auth-gated in the feature code. File References: `lib/main.dart:156-166`, `lib/features/notifications/viewmodels/notification_view_model.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:28-50`. Impact: unnecessary listener lifecycle work, possible stale state across auth transitions, and noisy error paths before auth is ready. Exploit/Failure scenario: app starts signed out, subscription attempts stream access and repeatedly enters error state until sign-in.

- `ARCH-04` (Evidence: `E-03`, `E-08`) — `NotificationViewModel` constructs `NotificationService()` by default and `NotificationService` hardcodes `Supabase.instance.client`, weakening DI/testability. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:17-18`, `lib/features/notifications/services/notification_service.dart:5-7`. Impact: hard-to-mock feature logic and hidden global dependencies. Exploit/Failure scenario: unit tests cannot isolate notification behavior without heavy app/bootstrap setup.

### 3.4 Code Quality

- `CQ-01` (Evidence: `E-17`, `E-16`, `E-26`) — `NotificationsModal.show(...)` is a likely unused helper while `NotificationBadgeButton` duplicates bottom-sheet setup inline. File References: `lib/features/notifications/view/notifications_modal.dart:12-19`, `lib/features/notifications/view/widgets/notification_badge_button.dart:24-30`. Impact: duplicate UI entry logic and drift risk when sheet config changes. Exploit/Failure scenario: one call path updates bottom-sheet options (e.g., barrier/style) and the other path remains stale. Status: callsite absence is UNVERIFIED by search (`E-26`).

- `CQ-02` (Evidence: `E-25`) — `NotificationService.getNotifications()` appears unused in current repo state. File Reference: `lib/features/notifications/services/notification_service.dart:8-23`. Impact: dead API surface and maintenance overhead. Exploit/Failure scenario: schema contract changes are patched in stream path but not this unused method, then a future caller reactivates stale behavior. Status: UNVERIFIED by search-count inference (`E-25`).

- `CQ-03` (Evidence: `E-17`, `E-24`) — The ViewModel exposes an error string, but notifications UI handles loading/empty/list only and does not render `vm.error`. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:24`, `lib/features/notifications/viewmodels/notification_view_model.dart:43-47`, `lib/features/notifications/viewmodels/notification_view_model.dart:73-76`, `lib/features/notifications/viewmodels/notification_view_model.dart:82-85`, `lib/features/notifications/view/notifications_modal.dart:36-63`, `lib/features/notifications/view/widgets/notification_badge_button.dart:17-74`. Impact: silent user-facing failures. Exploit/Failure scenario: stream/update errors occur, logs capture the error, but users see neither retry nor error message.

- `CQ-04` (Evidence: `E-18`) — `NotificationTile` contains a stale cleanup comment (`"theme variable unused, removed"`). File Reference: `lib/features/notifications/view/widgets/notification_tile.dart:19-22`. Impact: signal/noise degradation and reviewer confusion. Exploit/Failure scenario: future maintainers search for removed variable context that no longer exists.

- `CQ-05` (Evidence: `E-10`, `E-11`) — Unknown DB notification types silently map to `NotificationType.system` with no telemetry. File References: `lib/features/notifications/models/notification_model.dart:61-65`, `supabase/migrations/20260226_tender_award_payment_flow.sql:118-119`, `supabase/migrations/20260226_tender_award_payment_flow.sql:141-142`, `supabase/migrations/20260226_tender_award_payment_flow.sql:258-259`, `supabase/migrations/20260226_tender_award_payment_flow.sql:410-411`. Impact: contract drift is hidden instead of surfaced. Exploit/Failure scenario: new DB type ships and renders as generic system notification for weeks without anyone noticing.

### 3.5 Performance

- `PERF-01` (Evidence: `E-02`, `E-03`, `E-06`) — The feature opens a realtime notifications stream globally at app startup and keeps it running regardless of whether the notifications UI is visible. File References: `lib/main.dart:156-166`, `lib/features/notifications/viewmodels/notification_view_model.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:33-50`, `lib/features/notifications/services/notification_service.dart:25-35`. Impact: persistent network/listener overhead and unnecessary state churn. Exploit/Failure scenario: app sessions that never open notifications still maintain a realtime stream and rebuild badge consumers on updates.

- `PERF-02` (Evidence: `E-16`, `E-03`) — Badge UI listens to the full ViewModel via `Consumer` and recomputes unread count with a full list scan. File References: `lib/features/notifications/view/widgets/notification_badge_button.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:26`. Impact: avoidable rebuild and O(n) recomputation on every `notifyListeners()`. Exploit/Failure scenario: larger notification lists or frequent stream updates cause unnecessary rebuilds for the entire badge subtree.

- `PERF-03` (Evidence: `E-06`) — Stream path hard-limits results to 50 with no pagination/history path in the feature. File Reference: `lib/features/notifications/services/notification_service.dart:25-35`. Impact: silent truncation and no access to older notifications. Exploit/Failure scenario: users miss older unread notifications after high-volume periods because they are outside the last 50 rows.

### 3.6 Testing Gaps

- `TEST-01` (Evidence: `E-20`, `E-21`) — Existing notification integration coverage is environment-dependent and fails when no notifications exist. File References: `integration_test/notification_deeplink_flow_test.dart:14-50`, `integration_test/notification_deeplink_flow_test.dart:53-145`. Impact: flaky/non-deterministic CI and weak regression signal. Exploit/Failure scenario: test passes in staging with seeded data, fails in another environment with empty notifications, masking real logic regressions.

- `TEST-02` (Evidence: `E-24`, `E-25`, `E-26`) — Feature-local unit/widget coverage for notification model/service/viewmodel/modal behavior is missing in current repo state. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:24`, `lib/features/notifications/services/notification_service.dart:8-23`, `lib/features/notifications/view/notifications_modal.dart:12-19`. Impact: no deterministic regression checks for parsing, read-state sequencing, error UI, or modal tap lifecycle. Exploit/Failure scenario: a refactor breaks `markAsRead` sequencing or modal navigation and only manual testing catches it. Status: UNVERIFIED by absence scans (no matching `test/...notifications...` files were found; only `integration_test/notification_deeplink_flow_test.dart` was found).

- `TEST-03` (Evidence: `E-04`, `E-05`, `E-09`, `E-10`, `E-11`) — Critical edge cases are untested: disposed-context tap flow, non-awaited read mark, null `relatedEntityId` coalescing, duplicate `.maybeSingle()` behavior, and schema/type alias drift. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`, `lib/features/notifications/view/notifications_modal.dart:54-58`, `lib/features/notifications/services/notification_service.dart:110-117`, `lib/features/notifications/services/notification_service.dart:149-155`, `lib/features/notifications/models/notification_model.dart:31-43`, `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`. Impact: high-risk defects remain unguarded. Exploit/Failure scenario: production notification rows from SQL functions break app parsing with no automated alert until users report it.

## 4) Dead/Unused Code Candidates

- Candidate: `NotificationService.getNotifications()` in `lib/features/notifications/services/notification_service.dart:8-23`.
  - Why likely unused: repo search for `getNotifications(` returned only the definition (`E-25`).
  - How to confirm: run `rg -n "getNotifications\\(" lib test integration_test -g '*.dart'` and check for any callsites outside `lib/features/notifications/services/notification_service.dart`.
  - Status: UNVERIFIED (absence-by-search confirmation required at change time).

- Candidate: `NotificationsModal.show(BuildContext)` helper in `lib/features/notifications/view/notifications_modal.dart:12-19`.
  - Why likely unused: `NotificationBadgeButton` opens the modal inline instead (`lib/features/notifications/view/widgets/notification_badge_button.dart:24-30`) and search for `NotificationsModal.show(` returned no matches (`E-26`).
  - How to confirm: run `rg -n "NotificationsModal\\.show\\(" lib test integration_test -g '*.dart'`.
  - Status: UNVERIFIED (absence-by-search confirmation required at change time).

- Candidate: `NotificationViewModel.error` as a user-facing API in `lib/features/notifications/viewmodels/notification_view_model.dart:24`.
  - Why likely unused: feature UI renders loading/empty/list only (`lib/features/notifications/view/notifications_modal.dart:36-63`) and feature search found only the getter declaration (`E-24`).
  - How to confirm: run `rg -n "vm\\.error|\\.error\\b" lib/features/notifications -g '*.dart'` and verify no notification UI reads.
  - Status: UNVERIFIED (absence-by-search confirmation required at change time).

## 5) Duplicate Code Candidates

- Duplicate bottom-sheet launch configuration:
  - `lib/features/notifications/view/notifications_modal.dart:12-19` (`NotificationsModal.show(...)`)
  - `lib/features/notifications/view/widgets/notification_badge_button.dart:24-30` (inline `showModalBottomSheet(...)`)
  - Proposed shared abstraction: use `NotificationsModal.show(...)` as the single public entry-point and remove inline sheet setup from badge button.

- Repeated client-side notification dispatch calls across features:
  - `lib/features/chat/services/message_service.dart:300-309`
  - `lib/features/tasks/services/task_service.dart:217-226`
  - `lib/features/tasks/services/task_requests_service.dart:142-150`
  - `lib/features/tasks/services/task_requests_service.dart:248-257`
  - `lib/features/tasks/services/task_requests_service.dart:295-304`
  - `lib/features/booking/services/booking_service.dart:125-133`
  - `lib/features/booking/services/booking_service.dart:262-270`
  - Proposed shared abstraction: server-side notification dispatch via RPC/trigger/Edge Function (client sends event intent only), plus a thin client adapter for fire-and-forget invocation.

- Repeated deep-link loading/fetch/hide/navigate pattern in `DeepLinkService`:
  - `lib/core/services/deep_link_service.dart:128-151`
  - `lib/core/services/deep_link_service.dart:153-178`
  - `lib/core/services/deep_link_service.dart:180-208`
  - Proposed shared abstraction: a private helper that wraps loading dialog + guarded async fetch + navigate/error handling.

## 6) Refactor Plan (Exact Paths)

- Split notification data access by responsibility (query/read-state/dispatch):
  - Create `lib/features/notifications/services/notification_query_service.dart` (read + realtime stream only).
  - Create `lib/features/notifications/services/notification_read_state_service.dart` (`markAsRead`, `markAllAsRead`).
  - Create `lib/features/notifications/services/notification_dispatch_service.dart` (temporary client adapter to server-side RPC/Edge Function call).
  - Keep `lib/features/notifications/services/notification_service.dart` as a compatibility facade during migration, then deprecate/remove.
  - Migration strategy: wrapper forwards existing method names to new services until callsites are migrated.

- Separate ViewModel state from navigation orchestration:
  - Create `lib/features/notifications/viewmodels/notification_feed_view_model.dart` (stream state, unread count, read-state actions only).
  - Create `lib/features/notifications/services/notification_navigation_adapter.dart` (maps `NotificationItem` to deep-link calls using a stable UI context outside the ViewModel).
  - Keep `lib/features/notifications/viewmodels/notification_view_model.dart` as a compatibility shim/typedef during transition (or replace provider wiring directly in one commit if tests are in place).

- Refactor modal interaction to return a selected item instead of navigating from sheet context:
  - Create `lib/features/notifications/view/widgets/notifications_list_body.dart` (loading/empty/error/list rendering).
  - Update `lib/features/notifications/view/notifications_modal.dart` so `NotificationsModal.show(...)` returns `Future<NotificationItem?>`.
  - Update `lib/features/notifications/view/widgets/notification_badge_button.dart` to call `NotificationsModal.show(...)` and trigger navigation from parent context after the sheet closes.

- Add explicit DB-row mapping boundary for schema drift compatibility:
  - Create `lib/features/notifications/models/notification_row_mapper.dart` (normalizes aliases like `body -> message`, `data -> metadata`, `read -> is_read`, and logs unknown types).
  - Update `lib/features/notifications/models/notification_model.dart` usage sites in `notification_service.dart` to parse via mapper first.
  - Migration strategy: keep mapper until SQL schema/producers are aligned and validated in prod/staging.

- Server-side contract hardening artifacts (SQL):
  - Create `supabase/migrations/20260301_notifications_contract_alignment.sql` (exact schema/projection alignment or compatibility view, depending deployed state).
  - Create `supabase/migrations/20260301_notifications_rls_hardening.sql` (explicit `SELECT/UPDATE own` policies and restricted insert path).
  - Status: UNVERIFIED prerequisite because current repo lacks local `notifications` policy DDL source (`E-27`).

## 7) Fix Plan (Phases)

### Phase 1: Critical security & correctness

1. `P1.1` Remove direct client cross-user notification row inserts.
   - What to change: replace `createNotification/createOrUpdateNotification` DB writes with server-side dispatch (RPC/Edge Function/trigger-backed flow); client sends event intent only. File References (current risk surface): `lib/features/notifications/services/notification_service.dart:69-157`, `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_service.dart` (or new `notification_dispatch_service.dart`), all listed producer callsites, plus SQL migration files `supabase/migrations/20260301_notifications_contract_alignment.sql` and/or `supabase/migrations/20260301_notifications_rls_hardening.sql`.
   - Acceptance criteria: no client code path writes arbitrary `user_id` directly to `notifications`; notification dispatch succeeds via server-side path; failures are observable (not silently swallowed).

2. `P1.2` Fix notification tap lifecycle and read sequencing.
   - What to change: stop using modal child context after `Navigator.pop`; return selected notification from modal or pass stable parent context; define and implement deterministic `markAsRead` sequencing (`await` before/after navigation with explicit fallback behavior). File References: `lib/features/notifications/view/notifications_modal.dart:54-58`, `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`.
   - Exact file(s) to edit/create: `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/features/notifications/viewmodels/notification_view_model.dart` (or `notification_feed_view_model.dart` + `notification_navigation_adapter.dart`).
   - Acceptance criteria: tapping a row never uses a disposed context; deep-link navigation succeeds or fails with visible feedback; read-state behavior matches the documented rule in tests.

3. `P1.3` Align notification row contract (schema/type compatibility).
   - What to change: reconcile app parser expectations (`message/is_read/metadata`, known enum values) with SQL producer rows (`body/read/data`, custom types) via schema migration and/or client mapper compatibility layer. File References: `lib/features/notifications/models/notification_model.dart:31-43`, `lib/features/notifications/models/notification_model.dart:61-65`, `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416`, `Sline_everything/SUPABASE_SETUP.md:698-714`.
   - Exact file(s) to edit/create: `lib/features/notifications/models/notification_model.dart`, `lib/features/notifications/models/notification_row_mapper.dart` (new), `lib/features/notifications/services/notification_service.dart`, `supabase/migrations/20260301_notifications_contract_alignment.sql`.
   - Acceptance criteria: notifications created by SQL functions and client dispatch render without parse errors; unknown types are either mapped explicitly or logged and visibly handled.

4. `P1.4` Harden client-side scoping as defense-in-depth while keeping RLS as source of truth.
   - What to change: add explicit current-user filters to `getNotifications`, `streamNotifications`, and `markAsRead` paths; retain RLS as authoritative authz. File References: `lib/features/notifications/services/notification_service.dart:8-23`, `lib/features/notifications/services/notification_service.dart:25-35`, `lib/features/notifications/services/notification_service.dart:37-43`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_service.dart` (or split query/read-state services).
   - Acceptance criteria: all client notification reads/updates include `user_id == currentUser.id` where applicable; tests verify no-op/safe behavior when `currentUser` is null.

5. `P1.5` Stop swallowing critical notification dispatch/update errors without visibility.
   - What to change: convert silent catches to structured error propagation or explicit telemetry/user feedback (especially dispatch and coalescing paths). File References: `lib/features/notifications/services/notification_service.dart:90-93`, `lib/features/notifications/services/notification_service.dart:149-155`, `lib/features/notifications/viewmodels/notification_view_model.dart:73-85`, `lib/features/notifications/view/notifications_modal.dart:36-63`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_service.dart`, `lib/features/notifications/viewmodels/notification_view_model.dart`, `lib/features/notifications/view/notifications_modal.dart`.
   - Acceptance criteria: failures are visible to logs/telemetry and (for user-triggered actions) visible in UI; no silent failure in mark/read or dispatch code paths.

### Phase 2: Refactor/structure

1. `P2.1` Split `NotificationService` into query/read-state/dispatch components.
   - What to change: separate responsibilities and introduce DI-friendly constructors. File References (current monolith): `lib/features/notifications/services/notification_service.dart:5-157`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_query_service.dart` (new), `lib/features/notifications/services/notification_read_state_service.dart` (new), `lib/features/notifications/services/notification_dispatch_service.dart` (new), `lib/features/notifications/services/notification_service.dart` (compat wrapper).
   - Acceptance criteria: each service has one responsibility; provider/test setup can inject mocks without `Supabase.instance` coupling.

2. `P2.2` Restore MVVM boundaries for notifications tap handling.
   - What to change: remove `BuildContext` and `Provider` usage from notification ViewModel and shift navigation orchestration to a view-layer callback/adapter. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`, `lib/features/notifications/view/notifications_modal.dart:54-58`.
   - Exact file(s) to edit/create: `lib/features/notifications/viewmodels/notification_feed_view_model.dart` (new), `lib/features/notifications/services/notification_navigation_adapter.dart` (new), `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/main.dart` (provider wiring update at `lib/main.dart:156-166`).
   - Acceptance criteria: ViewModel is UI-context free; notification taps are driven from view/adapters using stable contexts; widget tests cover tap flow.

3. `P2.3` Reduce core-layer coupling around notification deep links.
   - What to change: isolate notification-specific mapping from `DeepLinkService`; keep core service focused on entity navigation primitives. File References: `lib/core/services/deep_link_service.dart:1-16`, `lib/core/services/deep_link_service.dart:24-31`, `lib/core/services/deep_link_service.dart:33-46`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_navigation_adapter.dart` (new), `lib/core/services/deep_link_service.dart`.
   - Acceptance criteria: `DeepLinkService` no longer needs notification-model-specific orchestration entrypoint (or it is clearly generic and context-safe).

4. `P2.4` Consolidate modal presentation API.
   - What to change: make `NotificationsModal.show(...)` the single sheet opener; remove duplicated inline `showModalBottomSheet` config. File References: `lib/features/notifications/view/notifications_modal.dart:12-19`, `lib/features/notifications/view/widgets/notification_badge_button.dart:24-30`.
   - Exact file(s) to edit/create: `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_badge_button.dart`.
   - Acceptance criteria: one sheet-launch implementation exists; UI behavior matches current visuals/options.

### Phase 3: Tests

1. `P3.1` Add model/unit tests for notification row parsing and type compatibility.
   - What to change: test canonical schema rows plus compatibility aliases and unknown types. File References (behavior under test): `lib/features/notifications/models/notification_model.dart:31-43`, `lib/features/notifications/models/notification_model.dart:61-65`.
   - Exact file(s) to edit/create: `test/features/notifications/models/notification_item_test.dart` (new), `test/features/notifications/models/notification_row_mapper_test.dart` (new if mapper is added).
   - Acceptance criteria: tests cover `message/is_read/metadata`, alias rows (`body/read/data`), and unknown type handling.

2. `P3.2` Add ViewModel tests for subscription/error/read-state transitions.
   - What to change: mock notification services and verify loading/error/unread behavior and tap/read sequencing policy. File References: `lib/features/notifications/viewmodels/notification_view_model.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:33-50`, `lib/features/notifications/viewmodels/notification_view_model.dart:58-87`.
   - Exact file(s) to edit/create: `test/features/notifications/viewmodels/notification_feed_view_model_test.dart` (new) or `test/features/notifications/viewmodels/notification_view_model_test.dart` (new if class not renamed yet).
   - Acceptance criteria: deterministic tests assert `isLoading`, `notifications`, `unreadCount`, error propagation, and mark-all/read error handling.

3. `P3.3` Add widget tests for badge/modal states and tap lifecycle.
   - What to change: test badge count rendering (`0`, `1`, `9+`), modal loading/empty/error/list, mark-all action, and safe selection-return flow. File References: `lib/features/notifications/view/widgets/notification_badge_button.dart:17-31`, `lib/features/notifications/view/widgets/notification_badge_button.dart:57-59`, `lib/features/notifications/view/notifications_modal.dart:36-63`, `lib/features/notifications/view/notifications_modal.dart:72-96`.
   - Exact file(s) to edit/create: `test/features/notifications/view/widgets/notification_badge_button_test.dart` (new), `test/features/notifications/view/notifications_modal_test.dart` (new), `test/features/notifications/view/widgets/notification_tile_test.dart` (new).
   - Acceptance criteria: no widget test relies on staging data; modal tap flow does not use disposed context.

4. `P3.4` Stabilize integration test with controlled fixture/seed strategy.
   - What to change: seed a deterministic notification fixture or inject a test backend path so `notification_deeplink_flow_test` does not fail on empty environments. File References: `integration_test/notification_deeplink_flow_test.dart:14-50`, `integration_test/notification_deeplink_flow_test.dart:53-145`.
   - Exact file(s) to edit/create: `integration_test/notification_deeplink_flow_test.dart`, plus existing integration support files under `integration_test/support/` as needed.
   - Acceptance criteria: test passes in a clean test environment without manual pre-seeding or hidden staging state.

### Phase 4: Polish/perf

1. `P4.1` Narrow rebuild scope for badge updates.
   - What to change: replace broad `Consumer<NotificationViewModel>` with `Selector` or equivalent unread-count-only listening; cache unread count if necessary. File References: `lib/features/notifications/view/widgets/notification_badge_button.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:26`, `lib/features/notifications/viewmodels/notification_view_model.dart:37-48`.
   - Exact file(s) to edit/create: `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/features/notifications/viewmodels/notification_feed_view_model.dart` or `lib/features/notifications/viewmodels/notification_view_model.dart`.
   - Acceptance criteria: badge rebuilds only when unread count changes; behavior remains identical (`9+` cap preserved).

2. `P4.2` Add pagination/history path beyond 50 rows.
   - What to change: define paged fetch API and modal UX for older notifications, or document deliberate cap if product decision is fixed. File Reference (current cap): `lib/features/notifications/services/notification_service.dart:25-35`.
   - Exact file(s) to edit/create: `lib/features/notifications/services/notification_query_service.dart` (new) or `lib/features/notifications/services/notification_service.dart`, `lib/features/notifications/view/notifications_modal.dart`.
   - Acceptance criteria: users can access older notifications (or the cap is explicitly documented and tested as intentional).

3. `P4.3` Improve error UX and telemetry for notification failures.
   - What to change: render `vm.error`/retry affordances and log unknown types/schema drift with non-PII diagnostics. File References: `lib/features/notifications/view/notifications_modal.dart:36-63`, `lib/features/notifications/viewmodels/notification_view_model.dart:24`, `lib/features/notifications/models/notification_model.dart:61-65`.
   - Exact file(s) to edit/create: `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/viewmodels/notification_feed_view_model.dart` or `lib/features/notifications/viewmodels/notification_view_model.dart`, `lib/features/notifications/models/notification_row_mapper.dart` (new) or `lib/features/notifications/models/notification_model.dart`.
   - Acceptance criteria: user-visible errors are actionable and retryable; unknown notification types are observable in logs/telemetry without leaking sensitive message content.

## 8) Verification Checklist

### Commands

- `flutter analyze lib/features/notifications lib/core/services/deep_link_service.dart lib/main.dart`
- `flutter test test/features/notifications/models/notification_item_test.dart`
- `flutter test test/features/notifications/models/notification_row_mapper_test.dart` (if mapper added)
- `flutter test test/features/notifications/viewmodels/notification_feed_view_model_test.dart` (or `notification_view_model_test.dart` if no rename)
- `flutter test test/features/notifications/view/notifications_modal_test.dart`
- `flutter test test/features/notifications/view/widgets/notification_badge_button_test.dart`
- `flutter test integration_test/notification_deeplink_flow_test.dart`
- `rg -n "createNotification\\(|createOrUpdateNotification\\(" lib/features/{chat,tasks,booking} -g '*.dart'` (expect no direct DB-row notification writes after Phase 1 if server-side dispatch is adopted)
- `rg -n "BuildContext context,\\s*NotificationItem item|context\\.read<DeepLinkService>" lib/features/notifications/viewmodels -g '*.dart'` (expect no notification ViewModel UI-context coupling after Phase 2)
- `rg -n "NotificationsModal\\.show\\(" lib test integration_test -g '*.dart'` (expect single standardized callsites)

### Manual Scenarios

- Open app signed in and verify the bell badge renders in the home header. File References: `lib/features/home/view/home_screen.dart:144-145`, `lib/features/notifications/view/widgets/notification_badge_button.dart:10-75`.
- Open notifications modal, verify loading -> empty/list states render correctly, and UI strings remain English (`Notifications`, `No notifications yet`, `Mark all as read`). File References: `lib/features/notifications/view/notifications_modal.dart:38-44`, `lib/features/notifications/view/notifications_modal.dart:78-86`.
- Tap an unread notification and verify: modal closes, navigation succeeds, no disposed-context errors, read state updates per the implemented sequencing rule. File References (current risk): `lib/features/notifications/view/notifications_modal.dart:54-58`, `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`.
- Trigger an unsupported or invalid notification target and verify friendly error handling without crash. File References: `lib/core/services/deep_link_service.dart:88-126`.
- Verify mark-all affects only the current user’s notifications. File Reference (client-side filter only): `lib/features/notifications/services/notification_service.dart:53-67`. RLS behavior is source-of-truth and must be validated separately (see next section).
- Log out and log in as a different user; verify notification state does not leak across sessions. File References (current lifecycle risk): `lib/main.dart:156-166`, `lib/features/notifications/viewmodels/notification_view_model.dart:17-20`, `lib/features/notifications/viewmodels/notification_view_model.dart:33-50`.
- Create/trigger notifications from chat, task, task-request, and booking flows; verify all render with correct type/title/message and deep-link behavior. File References: `lib/features/chat/services/message_service.dart:281-309`, `lib/features/tasks/services/task_service.dart:199-226`, `lib/features/tasks/services/task_requests_service.dart:132-154`, `lib/features/tasks/services/task_requests_service.dart:246-306`, `lib/features/booking/services/booking_service.dart:123-134`, `lib/features/booking/services/booking_service.dart:249-272`.

### Supabase/RLS Contract Checks

- Verify `public.notifications` RLS is enabled (RLS is source of truth for authz).
  - SQL check (Supabase SQL editor): `select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname='public' and c.relname='notifications';`
  - Expected: `true`.
  - Status in repo source: UNVERIFIED because local `notifications` policy DDL is missing (`E-27`).

- Verify actual policies on `public.notifications` exist and match the chosen design (server-side dispatch preferred).
  - SQL check: `select policyname, cmd, qual, with_check from pg_policies where schemaname='public' and tablename='notifications' order by policyname;`
  - Minimum expected contract (server-side dispatch design): end-user `SELECT` and `UPDATE` limited to own rows (`user_id = auth.uid()`); direct `INSERT` either denied for normal clients or tightly constrained and unused by app paths.
  - Historical-only reference (not source of truth): `Sline_everything/Sline_Log.md:536-545`.

- Verify runtime RLS behavior with two users (manual/API check).
  - User A can read/update only own notifications.
  - User A cannot insert a notification for User B directly through client credentials if server-side dispatch design is implemented.
  - User-facing client filters in code are defense-in-depth only. File References: `lib/features/notifications/services/notification_service.dart:8-67`.

- Verify schema contract alignment for notification producers.
  - Check DB columns or compatibility view expose fields expected by app (`message`, `is_read`, `metadata`) or mapper aliases are implemented. File References (app expectation): `lib/features/notifications/models/notification_model.dart:31-43`; (mismatched SQL producer examples): `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416`.

## 9) Risks & Rollback Notes

- Risk: Tightening/rewiring notification writes (Phase 1) can break existing chat/task/booking notifications if producer callsites are migrated before server-side dispatch/RLS changes are deployed. File References (impacted callsites): `lib/features/chat/services/message_service.dart:300-309`, `lib/features/tasks/services/task_service.dart:217-226`, `lib/features/tasks/services/task_requests_service.dart:142-150`, `lib/features/tasks/services/task_requests_service.dart:248-257`, `lib/features/tasks/services/task_requests_service.dart:295-304`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:262-270`.
  - Rollback steps: restore compatibility dispatch path in `lib/features/notifications/services/notification_service.dart`; temporarily relax only the minimum necessary client path while server-side dispatch is repaired (RLS remains source-of-truth; document any temporary policy changes).

- Risk: Schema alignment changes can break parsing for existing rows or mixed producer versions. File References (current parser expectations vs SQL examples): `lib/features/notifications/models/notification_model.dart:31-43`, `supabase/migrations/20260226_tender_award_payment_flow.sql:107-150`, `supabase/migrations/20260226_tender_award_payment_flow.sql:247-268`, `supabase/migrations/20260226_tender_award_payment_flow.sql:405-416`.
  - Rollback steps: keep `notification_row_mapper.dart` compatibility aliases enabled; revert schema migration and preserve compatibility view/columns until all producers are aligned.

- Risk: Modal tap flow refactor may regress navigation UX if sheet return values or context ownership are mishandled. File References (current flow): `lib/features/notifications/view/notifications_modal.dart:54-58`, `lib/features/notifications/viewmodels/notification_view_model.dart:58-68`, `lib/core/services/deep_link_service.dart:33-126`.
  - Rollback steps: revert to previous sheet flow behind a feature flag or compatibility branch while keeping tests for disposed-context reproduction.

- Risk: ViewModel/service split and rename refactors can break provider wiring and tests. File References (current wiring): `lib/main.dart:156-166`, `lib/features/notifications/viewmodels/notification_view_model.dart:17-18`, `lib/features/notifications/services/notification_service.dart:5-7`.
  - Rollback steps: keep compatibility wrappers (`notification_view_model.dart`, `notification_service.dart`) exporting old APIs until all callsites/providers/tests are migrated.
