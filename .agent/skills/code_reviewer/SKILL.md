---
name: code-reviewer
description: Perform structured code review focused on correctness, regressions, architecture, performance, and maintainability in the SLine Flutter project. Use before merge, after refactors, or when asked to audit changed files for risks and anti-patterns.
---

# Code Reviewer

## Review Priorities
1. Validate behavior and edge-case correctness first.
2. Flag architecture violations (MVVM leaks, wrong dependencies).
3. Identify performance risks in widget builds and data fetching.
4. Check error handling and user feedback paths.
5. Check naming, consistency, and project conventions.

## Inspection Checklist
- Business logic in UI callbacks instead of ViewModel methods.
- Over-scoped `Consumer` usage causing unnecessary rebuilds.
- Expensive work in `build()` methods.
- Silent catch blocks or unlogged failures.
- Missing loading/empty/error states in UI.
- Drift from established theme/components/patterns.

## Output Format
```markdown
### Findings
- [Critical|High|Medium|Low] <file:line> issue and impact

### Open Questions
- <assumption or missing context>

### Suggested Fixes
- <concrete action>
```
