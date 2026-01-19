---
description: Helper for creating standardized semantic commit messages and changelogs.
---

# Conventional Commits + Changelog Helper

**Goal**: Semantic history that enables automated changelog generation.

## Commit Message Format
`type(scope): description`

**Types**:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Formatting, missing semi-colons, etc; no production code change
- `refactor`: Refactoring production code, e.g. renaming a variable
- `perf`: Code change that improves performance
- `test`: Adding missing tests, refactoring tests; no production code change
- `chore`: Updating grunt tasks etc; no production code change

## Examples
- `feat(auth): implement google sign-in`
- `fix(ui): resolve overflow in task card`
- `docs(readme): update setup instructions`
- `refactor(core): move logger to services`

## Changelog Updating
When a feature is complete, verify if it should be added to `Sline_everything/Sline_Log.md` under the current version.
