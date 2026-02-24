---
name: docs-sync
description: Keep project documentation aligned with real code changes. Use when features, schema, architecture, or folder structure changes are introduced so developer docs, setup docs, and project context stay accurate in the same session.
---

# Docs Sync

## Trigger Conditions
- New feature or behavior change.
- Database schema, SQL, or RLS update.
- Refactor that changes structure or conventions.

## Update Targets
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/STRUCTURE.md`
- `.cursor/PROJECT_CONTEXT.md`

## Workflow
1. Read changed code and summarize what changed and why.
2. Update only affected sections in the target docs.
3. Keep file paths and examples accurate.
4. Note breaking changes and migration steps when relevant.

## Completion Rule
Do not close implementation work while related docs remain stale.

## References
- `.cursor/Agents/Sline_Docs.md`
