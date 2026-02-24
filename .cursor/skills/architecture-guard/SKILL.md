---
name: architecture-guard
description: Enforce strict MVVM boundaries in the SLine Flutter codebase. Use when reviewing, refactoring, or implementing feature code to prevent direct database/API access in views, keep layer responsibilities clean, and stop architecture drift before merge.
---

# Architecture Guard

## Run This Checklist
1. Verify `lib/features/*/view/` files do not call `Supabase.instance`, `SupabaseClient`, raw HTTP, or heavy business logic.
2. Verify dependency direction is `View -> ViewModel -> Service -> Supabase`.
3. Verify ViewModels extend `ChangeNotifier`, expose safe/immutable state, and call `notifyListeners()` only on real state changes.
4. Verify Services do not import UI files and only handle IO, mapping, and domain-specific persistence rules.

## Enforce On Violation
1. Move logic to ViewModel or Service immediately.
2. Block feature completion until boundaries are restored.
3. Track unresolved items in `.TODO/TECHNICAL_DEBT.md`.

## Report Format
```markdown
### Architecture Guard Report
- Status: pass | fail
- Violations:
  - [file:line] issue
- Applied fixes:
  - [file] summary
- Follow-ups:
  - debt item or "none"
```

## References
- `.cursor/rules/flutter-mvvm.mdc`
- `.cursor/rules/project-rules.mdc`
