---
name: bug-fixer
description: Run a structured bug triage and repair workflow for Flutter and Supabase features. Use when a defect is reported or reproduced and you need root-cause isolation, safe fixes, regression checks, and concise verification notes.
---

# Bug Fixer

## Workflow
1. Reproduce with minimal deterministic steps.
2. Capture evidence with `AppLogger` and relevant error traces.
3. Isolate failing layer: UI, ViewModel, Service, or database/RLS.
4. Implement the smallest safe fix.
5. Add or update tests to prevent regression.
6. Re-run checks (`flutter analyze`, targeted tests).
7. Update docs/rules only if behavior or constraints changed.

## Isolation Heuristics
- Data mismatch: inspect service queries, joins, RLS, and model mapping.
- State mismatch: inspect ViewModel mutations and `notifyListeners()` timing.
- UI issue: inspect widget constraints, render paths, and state subscriptions.

## Output Template
```markdown
### Bug Report: <title>
- Severity: High | Medium | Low
- Location: <file/class>
- Reproduction: <short steps>
- Root cause: <why it failed>
- Fix: <what changed>
- Verification: <tests/manual checks>
- Residual risk: <none or note>
```

## References
- `.cursor/rules/error-handling.mdc`
- `.cursor/Agents/QA.md`
