# VERDICT: Realtime Subscription Topology

## 1. Score & Assessment

- **OLD Score (Implicit from Notion MCP):** 3/10. Reassures developers about a feature that silently fails, while harbouring a massive N+1 scaling risk if it ever connected.
- **NEW Score (Proposed Folder):** 9/10. Correctly identifies the silent failure, isolates the N+1 `asyncMap` query bomb, and proposes a scalably filtered, push-driven architecture `messages` -> `InboxViewModel` that bypasses the broken `conversations` stream.

**Is the NEW design truly better, safer, and more scalable?**
**YES.**
The New design eliminates global un-filtered subscriptions (which starve CPU on RLS) and replaces unbounded `select()` scaling bombs with O(1) local-state merges.

## 2. Production Blockers Found

Yes, there is a production blocker. While the _NEW Documentation_ correctly redesigns the flow, the _existing Dart codebase_ currently implements the _OLD, broken flow_.

1. **Silent Failure & Wasted Connection Issue:** `message_service.dart:340` initiates a `.stream()` on `conversations`. Because `conversations` is NOT in the `supabase_realtime` publication (per `SUPABASE_SETUP.md`), this socket sits idle and yields nothing. New chats do not appear in the inbox automatically.
2. **N+1 Ticking Time Bomb:** If a developer "fixes" the silent failure by simply adding `conversations` to the DB publication, it will trigger the code at `message_service.dart:352`. This code maps every stream yield to a bulk `SELECT * FROM conversations WHERE id IN (...)`. At 100+ active users messaging rapidly, this unbounded query loop will exhaust the PostgreSQL connection pool.

## 3. Decision

We must execute the **Minimal Patch Plan** to bring the codebase in line with the **NEW** diagram. We will explicitly adopt **Option 2: Do NOT publish conversations; use messages stream to drive inbox resorting.**

_Option 2 Justification:_ Supabase Flutter SDK `.stream()` does not support OR filters (`receiver_id=eq.uid OR sender_id=eq.uid`). However, we can use the lower-level `.channel('...').on('postgres_changes', filter: '....')` if needed, or rely on a simpler push model where we simply listen to messages where the user is the receiver.
Because `messages` are already published and heavily used, pivoting Inbox to react to `messages` avoids doubling the WAL footprint on the DB.
