---
description: Handles all database changes with generated SQL, RLS policies, and validation.
---

# Supabase RLS + Migration Builder

**Goal**: Safe, secure, and documented database evolution.

## Workflow

1.  **Draft SQL**:
    - Define table schema (Types, Constraints, Defaults).
    - Define specific Enums if needed.

2.  **Security Layer (RLS)**:
    - **Enable RLS**: `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`
    - **Policy Generation**:
      - `SELECT`: typically `auth.uid() = user_id` or public/shared logic.
      - `INSERT`: `auth.uid() = user_id`.
      - `UPDATE`: `auth.uid() = user_id`.
      - `DELETE`: `auth.uid() = user_id`.

3.  **Performance Layer (Indexes)**:
    - Index foreign keys.
    - Index frequently filtered columns (`status`, `created_at`, `type`).

4.  **Verification Checklist**:
    - [ ] Does the policy allow the intended user? (Test with `@Supabase_Ops`)
    - [ ] Are Foreign Keys valid?
    - [ ] Is `created_at` set to `timezone('utc', now())`?

5.  **Execution & Logging**:
    - Execute via `@mcp:supabase-mcp-server`.
    - Append SQL to `Sline_everything/SUPABASE_SETUP.md`.

## Reference
- `.agent/rules/supabase-database.md`
