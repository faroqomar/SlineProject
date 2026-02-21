---
name: commit-helper
description: Create high-signal conventional commit messages and keep project changelog updates consistent. Use when preparing commits after feature work, fixes, refactors, or documentation changes in SLine.
---

# Commit Helper

## Commit Format
Use `type(scope): subject`.

## Allowed Types
- `feat`: new user-facing behavior.
- `fix`: bug resolution.
- `docs`: documentation-only change.
- `style`: formatting/style-only change.
- `refactor`: structure change with no behavior change.
- `perf`: performance improvement.
- `test`: test-only change.
- `chore`: maintenance and tooling.

## Rules
1. Keep subject imperative and specific.
2. Use smallest meaningful scope (feature/module).
3. Split unrelated changes into separate commits.

## Examples
- `feat(auth): implement google sign-in`
- `fix(tasks): prevent empty title submission`
- `refactor(chat): extract message mapper`

## Changelog Rule
When behavior changes, evaluate whether to add an entry to `Sline_everything/Sline_Log.md` under the active version.
