# Master Report: Realtime Subscription Topology (Orchestrator)

**Scope:** RealtimeSubscriptionTopology (Plan 18)  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Date:** 2026-03-07  
**Pipeline:** @Architect → @Observability → @SlineDocs → @CodeGuard

---

## A) Executive Summary

- **What was reviewed:** All code and docs for the Realtime Subscription Topology implementation (subscribeToInboxMessages, removal of conversations stream, ViewModel merge, getConversationById guard, migration, diagram and docs).
- **Overall risk level:** MEDIUM (realtime + state; no wallet/payment). Security LOW, performance LOW post-N+1 fix.
- **Final decision:** **Ready ✅** (CodeGuard APPROVED; no blocker. One correctness fix applied during review.)

---

## B) Consolidated Findings (Deduplicated)

### Security
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| — | — | No security findings. RLS unchanged; filter by receiver_id; no PII in logs. | — |

### Data Integrity
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| MED (fixed) | @Architect | conversation_model.dart copyWith | copyWith now preserves otherUserTyping and presenceUpdatedAt so typing indicator is not lost on Inbox merge. **Applied.** |

### Architecture / MVVM
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| — | — | MVVM boundaries respected; single source of truth for conversations list; no UI → Supabase. | — |

### Performance
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| — | — | N+1 removed; no asyncMap/select in stream; guarded single fetch per new conversation_id. | — |

### Observability
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| — | — | AppLogger used throughout; no print; stream errors and merge/fetch failures logged; no PII. | — |

### Docs / Reference Integrity
| Severity | Owner | Path / Object | Fix |
|----------|--------|----------------|-----|
| — | — | Diagram 18, SUPABASE_SETUP, Chat Feature, EXECUTION_LOG, E2E script aligned; refs validated. | — |

---

## C) Fix Plan (Ordered)

- **Step 1 (Done):** @Architect — Conversation.copyWith preserves otherUserTyping and presenceUpdatedAt.  
  **Verification:** conversation_model.dart copyWith includes `otherUserTyping: otherUserTyping, presenceUpdatedAt: presenceUpdatedAt` in the returned Conversation.
- **No further steps.** CodeGuard gate passed; no blocker.

---

## D) Regression Checklist

- **Inbox:** User on Inbox receives message → conversation moves to top, preview updates, no full refetch. (Manual E2E: MANUAL_E2E_INBOX_REALTIME.md)
- **Active chat:** User in a conversation receives message → message appears in thread (subscribeToMessages unchanged).
- **Notifications:** Badge/stream unchanged (notification_service unchanged).
- **No N+1:** Logs do not show bulk `SELECT ... conversations ... IN` on message events. (E2E step 6.)
- **Publication:** `pg_publication_tables` for supabase_realtime does not include conversations. (Verified via MCP.)

**Quick test:** Two devices; B sends to A; A on Inbox sees update without refresh; run `flutter analyze lib/features/chat/` (expect no issues).

---

## E) Rollback Notes

- **App:** Revert commits for subscribeToInboxMessages, removal of subscribeToConversations, ViewModel merge, copyWith. Re-deploy previous build.
- **DB:** Migration 20260307230000 only drops conversations from publication if present. To re-add (not recommended): `ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;`
- **Emergency:** Comment out `subscribeToUserConversations()` in messages_screen initState for pull-to-refresh-only behavior.

---

## F) Next Actions

1. ~~**Optional:** Add Sline_Log.md entry~~ **Done:** Entry added to `Sline_everything/Sline_Log.md` (Realtime Subscription Topology — Inbox from messages stream, 2026-03-07).
2. **Optional:** Run manual E2E (MANUAL_E2E_INBOX_REALTIME.md) and sign off before release.
3. No blocking actions. Pipeline complete; **Ready ✅**. All report fixes applied.
