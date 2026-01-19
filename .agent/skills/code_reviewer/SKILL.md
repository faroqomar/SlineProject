---
description: Automated anti-pattern hunter and code quality auditor.
---

# Code Review Skill (Anti-pattern Hunter)

**Goal**: Maintain high code quality by catching issues before they merge.

## Inspection Points

1.  **Logic Leakage**:
    - `setState` in simple screens? (Prefer ViewModel).
    - `Business Logic` in `onPressed`? (Move to ViewModel).

2.  **Performance Killers**:
    - `build()` method too large? (Extract Widgets).
    - Unnecessary `Consumer` wrapping entire screen? (Scope it down).
    - Hardcoded heavy computations in `build`?

3.  **Error Handling**:
    - Empty `catch (e) {}` blocks? (MUST log with `AppLogger`).
    - UI ignoring error states? (Must show Feedback/Snackbar).

4.  **Naming & Style**:
    - Variable names specifically descriptive? (`data` vs `tasksList`).
    - File names snake_case matching class PascalCase?

5.  **Architecture Drift**:
    - "Copy-paste" code that ignores the project's specific `Glassmorphism` or `BaseService` patterns?

## Output
Produce a list of improvements similar to:
- `[Critical] Moved logic from View to ViewModel on line 45.`
- `[Style] Renamed controller to adhere to conventions.`
- `[Perf] Extracted ListItem to separate widget.`
