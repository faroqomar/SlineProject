# Chat Test Strategy (2026-03-01)

**Purpose:** Define test ownership, harnesses, and selector inventory so every ChatFix test task maps to an existing or explicitly planned harness. No implementation work starts until this and the decision pack exist.

---

## 1. Unit tests

| Area | Owner | Harness / file | Scope |
|------|--------|-----------------|--------|
| Message type codec (snake_case wire values) | Architect | `test/unit/models/message_model_test.dart` (extend) | Canonical write values; legacy camelCase read compatibility |
| Offer payload model | Architect | `test/unit/chat/chat_offer_payload_test.dart` (create) | `days` only on write; read compatibility for `delivery` |
| Realtime merge helper | Architect | `test/unit/chat/chat_realtime_merger_test.dart` (create) | Snapshot merge, dedupe, ordering; no loss to `rows.last` |
| Error mapping (user-safe) | Architect | `test/unit/chat/error_mapping_test.dart` (optional) | Chat errors → user-safe strings; no raw exception leakage |

**Test seams:** `MessageService` and `ChatRepository` remain testable via injected Supabase client / repository interfaces. Planned split viewmodels (`ChatConversationsViewModel`, `ChatThreadViewModel`) get unit tests with mocked service/repository.

---

## 2. Widget tests

| Screen / widget | Owner | Harness / file | States / selectors |
|-----------------|--------|-----------------|--------------------|
| MessagesScreen | Pixel / Sentinel | `test/widget/chat/messages_screen_test.dart` (create) | Load, empty, error, retry, archive-error; selector keys per inventory below |
| ChatScreen | Pixel / Sentinel | `test/widget/chat/chat_screen_test.dart` (extend) | Draft preservation on failed send; offer gating; in-flight send disable; send error state |

**Selector inventory (to be added during UI changes):**

- `message_list_error_state` — error state on conversation list
- `message_list_empty_state` — empty list state
- `message_list_retry_action` — retry button / action
- `archive_error_state` — archive/delete failure feedback
- `chat_send_error_state` — send failure feedback in thread
- `chat_in_flight_send_button` — send button disabled while sending
- `manual_refresh_hint` — hint when conversation realtime is disabled (fetch-refresh fallback)

---

## 3. Integration tests

| Flow | Owner | Harness / file | Scope |
|------|--------|----------------|--------|
| Open chat from list | Sentinel | `integration_test/chat_message_flow_test.dart` (extend) | List → thread navigation |
| Booking path to chat | Sentinel | `integration_test/chat_message_flow_test.dart` or booking flow test | Booking → start task conversation → chat screen |
| Deep-link path to chat | Sentinel | `integration_test/notification_deeplink_flow_test.dart` (extend) | Deep link → conversation resolve → chat screen |
| Send / fail / retry | Sentinel | `integration_test/chat_message_flow_test.dart` | Send failure and retry; draft preserved |
| Fallback refresh behavior | Sentinel | Integration or manual | Conversation list refresh without realtime (pull-to-refresh / screen open) |

**Preflight / helpers:** `integration_test/support/helpers.dart`, `integration_test/support/preflight.dart` — use existing; add Chat-specific helpers if needed (e.g. create test conversation).

---

## 4. RLS / manual SQL checks

| Check | Owner | How | Phase |
|-------|--------|-----|--------|
| Participant message read allowed | ThreatModeler / Sentinel | Run as participant; SELECT messages | Phase 5 |
| Non-participant message read denied | ThreatModeler / Sentinel | Run as foreign user; SELECT must fail | Phase 5 |
| Participant attachment select allowed | ThreatModeler / Sentinel | Signed URL / select for own conversation object | Phase 5 |
| Non-participant attachment select denied | ThreatModeler / Sentinel | Foreign user must not get access | Phase 5 |
| Direct DM create (favorites-gated) | ThreatModeler / Sentinel | Per CHAT_DECISIONS; allow/deny matrix | Phase 5 |
| Task-linked create (non-owner via RPC) | ThreatModeler / Sentinel | start_task_conversation_v1; owner denied | Phase 5 |

---

## 5. Commands

- `flutter analyze`
- `flutter test test/unit/models/message_model_test.dart`
- `flutter test test/unit/chat/` (once created)
- `flutter test test/widget/chat/`
- `flutter test integration_test/chat_message_flow_test.dart`
- `flutter test integration_test/notification_deeplink_flow_test.dart`

---

## 6. Gate

**Verify (@Sentinel):** No implementation work (SQL or Flutter feature code) starts until every planned test above maps to an existing or explicitly planned harness. This document is that mapping.
