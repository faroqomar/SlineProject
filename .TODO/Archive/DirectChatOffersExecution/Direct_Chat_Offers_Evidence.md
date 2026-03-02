# Direct Chat Offers – Live Supabase Evidence (Phase 0.5)

**Date:** 2026-03-02  
**MCP:** plugin-supabase-supabase `list_tables`  
**Project ID:** isddrknbjsgaantjojhm  
**Schemas:** public  

## Findings

- **direct_offers:** Table does **not** exist. Safe to add.
- **related_entity_type_enum:** From `journal_entries` schema in list_tables output: values `booking`, `task_request`, `withdrawal_request`, `admin_adjustment`. No `direct_offer`. Add via migration.
- **work_logs:** Exists; columns include `related_entity_type` (text), `related_entity_id` (uuid). No enum on this column; use `'direct_offer'` as text.
- **conversations, messages:** Present; messages have `message_type_enum` (includes `offer`, `offer_accepted`, `offer_rejected`) and `payload` (jsonb).

## Conclusion

Additive-only approach: create `direct_offers`, add enum value `direct_offer`, extend RPC and work_logs participant helper. No conflicts.
