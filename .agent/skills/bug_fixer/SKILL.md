---
description: Systematic process to reproduce, isolate, fix, and verify bugs.
---

# Bug Triage + Fix Plan

**Goal**: Eliminate bugs systematically and prevent regression.

## Usage
When an issue is reported:

1.  **Reproduce & Log**:
    - Create a reproduction case (minimal steps).
    - Capture logs using `AppLogger` (Debug level).

2.  **Isolate**:
    - Is it Data Layer? (Check Supabase response).
    - Is it Logic Layer? (Check ViewModel state).
    - Is it UI Layer? (Check Widget constraints/rendering).

3.  **Propose Fix**:
    - Describe the fix in 1-2 sentences.
    - Check for side effects (What else uses this logic?).

4.  **Regression Test**:
    - Can we add a Unit Test for this?
    - Add test case to `test/features/[feature]_test.dart`.

5.  **Documentation**:
    - If the bug was an architectural misunderstanding, update `.agent/rules/`.
    - If it's a known limitation, add to `TROUBLESHOOTING.md`.

## Output Template
```markdown
### Bug Report: [Title]
**Severity**: High/Medium/Low
**Location**: [File/Class]
**Cause**: [Root Cause]
**Fix**: [Description of fix]
**Verification**: [How it was tested]
```
