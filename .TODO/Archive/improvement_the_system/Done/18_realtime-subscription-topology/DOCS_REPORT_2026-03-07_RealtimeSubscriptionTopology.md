# Docs Report: Realtime Subscription Topology

**Scope:** RealtimeSubscriptionTopology (Plan 18)  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @DocsKeeper

---

## 1) Documentation Delta List

| Doc | Change | Status |
|-----|--------|--------|
| Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md | Inbox from messages (receiver_id); conversations NOT in publication; evidence table updated | ✅ Done |
| Sline_everything/SUPABASE_SETUP.md | Realtime section: only messages + notifications; do NOT add conversations; migration 20260307230000 referenced | ✅ Done |
| Sline_everything/DEVELOPER_GUIDE/Chat Feature.md | §2.6 Realtime (Inbox + active chat); subscribeToInboxMessages, merge, getConversationById guard | ✅ Done |
| .TODO/EXECUTION_LOG_PLAN_RealtimeSubscriptionTopology_2026-03-07.md | Phases, code changes, SQL via MCP, observability, rollback | ✅ Done |
| .TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/MANUAL_E2E_INBOX_REALTIME.md | Manual E2E steps + N+1 check | ✅ Done |

---

## 2) Reference Integrity Scan

- **18_realtime-subscription-topology.md:** References message_service.dart (subscribeToMessages, subscribeToInboxMessages), notification_service.dart, supabase_realtime, messages_select, notifications_select_own. All exist.
- **SUPABASE_SETUP.md:** References migration `20260307230000_realtime_topology_no_conversations.sql`. File exists in supabase/migrations/.
- **Chat Feature.md:** References subscribeToInboxMessages, getConversationById, ChatViewModel, diagram 18. All exist.
- **EXECUTION_LOG:** References plan path, file paths (message_service, chat_repository, chat_view_model, conversation_model). All exist.
- **MANUAL_E2E:** References plan and checklist. No broken refs.

---

## 3) Outdated Statements

- **None.** Diagram and SUPABASE_SETUP no longer claim conversations is in the publication. Chat Feature describes current Inbox realtime flow.

---

## 4) Required Doc Updates (Remaining)

- ~~**Optional:** Add a short entry to `Sline_everything/Sline_Log.md`~~ **Done:** Entry added (Realtime Subscription Topology — Inbox from messages stream, 2026-03-07).

---

## 5) Cross-Links

- Plan ↔ EXECUTION_LOG: plan path in log. ✅
- Diagram 18 ↔ SUPABASE_SETUP ↔ Chat Feature: mutual references. ✅
- E2E script lives under 18_realtime-subscription-topology folder. ✅

**Verdict:** Docs and references consistent. No blocker.
