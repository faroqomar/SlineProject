# Notes on Role Switching Flow

Skills Appled:

- Evidence-First Reading
- Threat Modeling (Security)
- State Machine & Lifecycle
- RLS & Privilege Boundaries
- Diagram Crafting (Mermaid)

Observations:

1. UI switch is done via `ProfileRepository.changeRole({userId, newRole})` connecting to `profiles` table.
2. The current diagram is a simple 2-state graph. It lacks boundary enforcement details.
3. If a user switches roles, what happens to their active session/streams? Flutter Provider needs to teardown old streams.
4. At the DB level, RLS must actively block 'client' from writing to 'task_requests' even if they bypass the UI.
5. The `replace_task_request` RPC enforces `profiles.active_role = 'freelancer'`. Standard INSERT RLS policies need similar enforcement.
