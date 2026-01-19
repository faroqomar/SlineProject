---
description: Enforces strict MVVM patterns and prevents architectural consistency drift.
---

# Architecture Enforcer (MVVM Guardrail)

**Goal**: Prevent UI code from directly accessing the database and ensure strict layer separation.

## Inspection Checklist

When running this skill, verify the following in the target files:

1.  **UI Purity Check (`lib/features/*/view/`)**:
    *   [ ] **NO** `Supabase.instance`, `SupabaseClient`, or `supabase` variable usage.
    *   [ ] **NO** `http` calls or direct API fetching.
    *   [ ] **NO** complex logic (if/else chains > 3 levels).
    *   [ ] **MUST** use `Consumer<ViewModel>` or `context.watch<ViewModel>`.

2.  **Layer Integrity**:
    *   **Flow**: View ➔ ViewModel ➔ Service ➔ Supabase.
    *   [ ] ViewModel must NOT depend on UI widgets (no `BuildContext` in methods if possible).
    *   [ ] Service must NOT depend on ViewModels.

3.  **State Management**:
    *   [ ] ViewModels must extend `ChangeNotifier`.
    *   [ ] ViewModels must expose `UnmodifiableListView` for lists.
    *   [ ] `notifyListeners()` must be called only when state actually changes.

## Enforcement Action

If violations are found:
1.  **Refactor**: Move logic to ViewModel or Service IMMEDIATELY.
2.  **Block**: Do not proceed with feature implementation until strict MVVM is restored.
3.  **Log**: Note the violation in `.TODO/TECHNICAL_DEBT.md`.

## Reference Rules
- `.agent/rules/flutter-mvvm.md`
- `.agent/rules/project-rules.md`
