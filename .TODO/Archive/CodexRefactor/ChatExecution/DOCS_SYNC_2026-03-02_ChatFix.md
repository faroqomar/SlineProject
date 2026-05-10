# Docs Sync: ChatFix (2026-03-02)

**Scope:** Align `Sline_everything/` and cross-references with ChatFix implementation per DocsKeeper workflow.

---

## Doc files updated

| File | Changes |
|------|--------|
| `Sline_everything/Sline_Log.md` | **Last Updated** → 2026-03-02. Added **Version 2.16.9 — ChatFix** entry: migration path, chat feature paths (message_model, chat_offer_payload, chat_realtime_merger, message_service, chat_repository, chat_screen), docs/.TODO refs, verification (plan, execution log, CodeGuard, Master Report, tests), technical notes (migration, rollback). |
| `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` | Removed stray `?` at top. In §2.2 `message_type_enum`: noted app model includes `MessageType.system` for parity (`message_model.dart`). |
| `Sline_everything/DEVELOPER_GUIDE.md` | Chat section: added **Archive** to Triggers/Functions (RPC `archive_conversation_v1`, ref to SUPABASE_SETUP). File inventory: added `chat_realtime_merger.dart`, `chat_offer_payload.dart`; updated `message_model.dart` (snake_case, MessageType.system) and `message_service.dart` (archive RPC). |
| `Sline_everything/MVP_ROADMAP.md` | **Last Updated** → 2026-03-02. Realtime chat row: added archive RPC, offer payload, realtime merger. Attachments row: added participant-scoped `can_access_chat_attachment`. |
| `Sline_everything/STRUCTURE.md` | Already updated earlier: Recent Structure-Sensitive Updates mention Chat `chat_offer_payload.dart`, `chat_realtime_merger.dart`, archive RPC. |
| `Sline_everything/SUPABASE_SETUP.md` | No change this pass; already documents `archive_conversation_v1` and `can_access_chat_attachment`. |

---

## Summary of changes

- **Versioning:** ChatFix recorded as 2.16.9 in Sline_Log with full implementation list and verification links.
- **Reference integrity:** All linked paths verified: plan (PLAN_ChatFix_v2), execution log (EXECUTION_LOG_PLAN_ChatFix_v2), CodeGuard review, Master Report, migration file, chat feature paths.
- **Single source of truth:** Chat canonical doc remains `DEVELOPER_GUIDE/Chat Feature.md`; main DEVELOPER_GUIDE.md Chat section and MVP_ROADMAP now match (archive RPC, new files, message type note).

---

## References validated

- `.TODO/PLAN_ChatFix_v2_2026-03-01.md` — exists
- `.TODO/EXECUTION_LOG_PLAN_ChatFix_v2_2026-03-01.md` — exists
- `.TODO/CODEGUARD_REVIEW_2026-03-02_ChatFix.md` — exists
- `.TODO/MASTER_REPORT_2026-03-02_ChatFix.md` — exists
- `supabase/migrations/20260302_chat_archive_rpc_and_storage_helper.sql` — exists
- `lib/features/chat/models/message_model.dart`, `chat_offer_payload.dart`, `chat_realtime_merger.dart`, `message_service.dart`, `chat_repository.dart`, `view/chat_screen.dart` — exist

---

## Why each update was needed

1. **Sline_Log:** DocsKeeper §3 – any plan executed must have execution log and release entry; §6.1 template used for traceability.
2. **Chat Feature.md:** Fix errant character; document MessageType.system for contract/DB parity.
3. **DEVELOPER_GUIDE.md:** §2 – feature completion and DB changes; archive RPC and new Chat files must appear in the main guide’s Chat section for discoverability.
4. **MVP_ROADMAP.md:** §3 – feature completion; Realtime chat and Attachments statuses updated to reflect archive RPC and storage helper.
5. **STRUCTURE/SUPABASE_SETUP:** Already updated in prior pass; no further delta.
