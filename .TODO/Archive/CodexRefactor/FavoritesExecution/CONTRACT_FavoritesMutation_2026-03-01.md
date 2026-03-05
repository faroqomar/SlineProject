# Contract: Favorites mutation result (add / remove)

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Requirement

Replace `Future<void>` + side-channel `error` for `add` and `remove` with a **typed result** so UI and tests can decide behavior deterministically.

## Typed result (enum or sealed type)

Suggested: `FavoritesMutationResult` with variants:

- `success` — add or remove succeeded.
- `duplicate` — add failed because favorite already exists (e.g. 23505).
- `unauthenticated` — user not signed in.
- `forbidden` — RLS or policy denied (e.g. cross-user).
- `failure` — other error (network, server); optional message for logging; UI shows generic copy.

## Method signatures

- `Future<FavoritesMutationResult> add(String freelancerId)`
- `Future<FavoritesMutationResult> remove(String freelancerId)`

ViewModel must not set a side-channel `error` for these outcomes when using typed result; optional: keep `error` for load/refresh only, or clear it when using result.

## Caller behavior

- **UI**: Show success snackbar only when result == success. For duplicate, show “Already in favorites”. For unauthenticated/forbidden/failure, show sanitized message (no raw exception).
- **Tests**: Assert on returned value (e.g. `expect(await vm.add(id), FavoritesMutationResult.duplicate)`).

## Idempotency

- **Add**: Duplicate insert (23505) → return `duplicate`, do not treat as success.
- **Remove**: Delete by (client_id, freelancer_id); missing row can be success (idempotent) or not-found; document chosen behavior (e.g. notFound → success for remove).
