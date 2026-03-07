# Docs Sync: Realtime Subscription Topology (18) — Everything Up to Date

**Date:** 2026-03-08  
**Workflow:** `.agents/workflows/slinedocs.md`  
**Scope:** Ensure all docs reflect plan 18 (Inbox from messages stream; no conversations in realtime publication).

---

## 1) Doc Files Updated

| Doc | Change | Why |
|-----|--------|-----|
| `Sline_everything/DEVELOPER_GUIDE.md` | Chat File Inventory: message_service description → "messages (active chat + Inbox)", note that conversations is not in realtime; link to diagram 18. | Match current topology; remove outdated "conversations/messages" wording. |
| `Sline_everything/DEVELOPER_GUIDE.md` | §7 Extra Notes (Chat): Realtime bullet → "messages stream only" (active chat by conversation_id, Inbox by receiver_id); conversations not in publication; link to diagram 18. | Remove incorrect "Subscribe to messages and conversations streams". |
| `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` | §7 Extra Notes: Same Realtime bullet fix (messages only; link to diagram 18). | Align with DEVELOPER_GUIDE and diagram 18. |
| `Sline_everything/MVP_ROADMAP.md` | Realtime chat row: added "18_topology"; wording → "Messages-only realtime", "Inbox subscribeToInboxMessages(userId)", "conversations not in publication"; added PLAN_RealtimeSubscriptionTopology and diagram 18 refs. | Roadmap must reflect that Inbox is messages-driven and topology 18 is done. |
| `Sline_everything/STRUCTURE.md` | Chat bullet: added "Inbox realtime: subscribeToInboxMessages(userId) (messages stream, not conversations); see diagram 18 and PLAN_RealtimeSubscriptionTopology." | Structure doc must point to current realtime design. |

**Already up to date (no change this pass):**

- `Sline_everything/Sline_Log.md` — Realtime Subscription Topology entry already present (2026-03-07).
- `Sline_everything/SUPABASE_SETUP.md` — Realtime §12 already states messages/notifications/conversation_presence only; do NOT add conversations; migration 20260307230000.
- `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md` — Already updated for Inbox from messages, conversations NOT in publication.

---

## 2) Reference Validation

All references checked; paths exist:

- `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md` ✅
- `.TODO/EXECUTION_LOG_PLAN_RealtimeSubscriptionTopology_2026-03-07.md` ✅
- `.TODO/MASTER_REPORT_2026-03-07_RealtimeSubscriptionTopology.md` ✅
- `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md` ✅
- `supabase/migrations/20260307230000_realtime_topology_no_conversations.sql` ✅
- `.TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/MANUAL_E2E_INBOX_REALTIME.md` ✅
- `.TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/CHECKLIST_AND_SUMMARY_RealtimeTopology.md` ✅
- `lib/features/chat/services/message_service.dart` (subscribeToInboxMessages) ✅
- `lib/features/chat/data/chat_repository.dart` (subscribeToInboxMessages, getConversationById) ✅

No dead paths. No outdated "conversations stream" references left in core docs.

---

## 3) Summary

- **Outdated statements removed:** "Subscribe to messages and conversations streams" in DEVELOPER_GUIDE and Chat Feature; "conversations/messages" in message_service description.
- **Single source of truth:** Diagram 18 + SUPABASE_SETUP + DEVELOPER_GUIDE + Chat Feature + MVP_ROADMAP + STRUCTURE now all state: Inbox realtime = messages stream (receiver_id); conversations table not in realtime publication.
- **Cross-links:** Plan, execution log, master report, diagram 18, migration, and checklist are linked from Sline_Log and/or the updated docs.

---

## 4) Verification

- `Sline_everything/` scanned for "conversations" + "stream" / "realtime" — no remaining claim that conversations is subscribed to for realtime.
- MVP_ROADMAP status for Realtime chat remains ✅ Completed; scope text updated to include topology 18.
- STRUCTURE and DEVELOPER_GUIDE Chat section point to diagram 18 and plan 18 for Inbox realtime.

**Docs are up to date with the Realtime Subscription Topology implementation.**
