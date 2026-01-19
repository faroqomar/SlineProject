---
description: Automatically updates documentation to reflect the latest codebase state.
---

# Docs Sync Skill

**Goal**: Keep documentation as the "Living Truth" of the project.

## Sync Triggers
- **New Feature Added**: Update `MVP_ROADMAP.md` and `DEVELOPER_GUIDE.md`.
- **Database Change**: Update `SUPABASE_SETUP.md`.
- **Refactor**: Update `STRUCTURE.md` if folder structure changes.

## Sync Process

1.  **Scrape**: Read the new files or changes.
2.  **Summarize**: Extract the "What", "Why", and "How".
3.  **Update**:
    - **Developer Guide**: Add new section for the feature, link to key files.
    - **Structure**: Add new directories/files to the tree.
    - **Project Context**: Update `.cursor/PROJECT_CONTEXT.md` with new capabilities.

## Rule
**Never** leave docs outdated. If code changes, docs change in the same "session".
