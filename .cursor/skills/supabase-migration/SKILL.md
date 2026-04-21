---
name: supabase-migration
description: Design and validate Supabase/Postgres migrations with secure RLS and performance-aware indexing. Use when adding or changing tables, policies, constraints, or data-access behavior in SLine.
---

# Supabase Migration

## Workflow
1. Draft schema SQL with explicit types, constraints, defaults, and FK actions.
2. Enable RLS and define least-privilege policies for `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
3. Add indexes for foreign keys and high-frequency filters/sorts.
4. Validate policy behavior with representative user roles and ownership cases.
5. Confirm UTC-safe timestamps and consistent naming.
6. Record finalized SQL changes in `Sline_everything/SUPABASE_SETUP.md`.

## RLS Baseline
- Ownership tables: guard by `auth.uid() = <owner_id_column>`.
- Shared/public reads: explicitly scope records and avoid broad `true` policies.
- Mutations: enforce ownership in `WITH CHECK` and `USING`.

## Verification Checklist
- Intended users can read/write expected records.
- Non-owners are denied for restricted operations.
- FK relationships and cascade behavior are correct.
- Query performance is acceptable on expected dataset sizes.

## Reference
- `.cursor/rules/supabase-database.mdc`
- `.cursor/Agents/BackendOps.md`
