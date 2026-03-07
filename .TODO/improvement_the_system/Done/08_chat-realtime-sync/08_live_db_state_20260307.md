# Live DB State — Chat Realtime Sync (2026-03-07)

**Project ID:** isddrknbjsgaantjojhm (Sline Project)  
**Source:** Supabase MCP `list_tables` (verbose)

## Findings

### public.messages
- **Exists:** yes  
- **RLS enabled:** true  
- **Rows:** 6  
- **Columns:** id, conversation_id, sender_id, receiver_id, content, created_at, attachment_url, attachment_type, attachment_name, attachment_size, delivered_at, seen_at, message_type, payload  
- **Note:** delivered_at and seen_at present. RLS policies not listed by MCP; migration must add/ensure participant SELECT/INSERT and receiver UPDATE.

### public.conversation_presence
- **Exists:** yes  
- **RLS enabled:** true  
- **Rows:** 0  
- **Columns:** conversation_id, user_id, is_typing, updated_at (PK: conversation_id, user_id)  
- **FKs:** conversation_id → conversations(id), user_id → profiles(id)  
- **Note:** Table already created (likely from earlier migration or dashboard). Migration must NOT create table again; only ensure RLS and realtime.

### Realtime publication
- Not listed in list_tables output. Migration should add messages and conversation_presence to supabase_realtime if not already present (idempotent: ALTER PUBLICATION ... ADD TABLE only if not in publication).

## Migration strategy
- Do **not** CREATE TABLE conversation_presence (already exists).  
- Add RLS policies for messages (participant SELECT/INSERT, receiver UPDATE for delivered_at/seen_at) with unique names; drop if exists then create to be idempotent.  
- Add RLS policies for conversation_presence (participant SELECT, self INSERT/UPDATE) same way.  
- ALTER PUBLICATION supabase_realtime ADD TABLE messages; ADD TABLE conversation_presence; (will error if already in publication — use safe block or document manual step).
