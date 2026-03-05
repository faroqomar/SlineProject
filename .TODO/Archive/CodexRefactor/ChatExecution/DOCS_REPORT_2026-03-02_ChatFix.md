# Docs Report: ChatFix

**Scope:** ChatFix  
**Date:** 2026-03-02

---

## 1. Documentation delta list

- **DEVELOPER_GUIDE/Chat Feature.md:** Updated during Phase 5 to reflect DM favorites-gated, task-linked non-owner starts, offer payload `days`, archive RPC. RLS summary and triggers/functions section updated.
- **SUPABASE_SETUP.md:** Not updated in this execution. Chat RPC `archive_conversation_v1` and helper `can_access_chat_attachment` are new; they are documented in the migration file and in CHAT_CONTRACT / Chat Feature.md. Optional: add a short subsection under Chat or RPCs in SUPABASE_SETUP.md for the new RPC and helper.
- **.TODO artifacts:** CHAT_DECISIONS, CHAT_CONTRACT, CHAT_RLS_MATRIX, CHAT_TEST_STRATEGY, CHAT_THREAT_MODEL, CHAT_ROLLOUT_MATRIX, CHAT_OBSERVABILITY, CHAT_DATA_AUDIT, CHAT_LIVE_SQL_BASELINE exist and are referenced by the execution log.

---

## 2. Reference integrity scan

- Plan reference in execution log: `.TODO/PLAN_ChatFix_v2_2026-03-01.md` — exists.
- Doc paths cited in plan (DEVELOPER_GUIDE.md, Chat Feature.md, SUPABASE_SETUP.md, etc.) — exist.
- Code paths (lib/features/chat/**, main.dart, etc.) — exist.
- No broken internal refs found.

---

## 3. Required doc updates

- **LOW:** Add `archive_conversation_v1` and `can_access_chat_attachment` to SUPABASE_SETUP.md (e.g. under Chat or Functions) so the schema doc matches deployed objects after migration is applied.
- **LOW:** If STRUCTURE.md or MVP_ROADMAP.md list Chat files, ensure `chat_offer_payload.dart` and `chat_realtime_merger.dart` are mentioned (or that STRUCTURE describes feature/model/service layout generically).

---

## 4. Conclusion

- No BLOCKER. One optional doc update (SUPABASE_SETUP) for post-migration consistency.
