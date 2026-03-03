# Threat model: Favorites

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Threats and mitigations

| Threat | Mitigation | Phase 4 check |
|--------|------------|----------------|
| Unauthorized favorites CRUD (cross-user) | RLS: owner-only select/insert/delete on `favorites` | RLS negative test: other user cannot read/insert/delete |
| Duplicate-add abuse / race | Idempotent handling (e.g. 23505 → “Already in favorites”); pending-action guard to limit rapid taps | Unit/widget: duplicate add returns typed result; no double insert |
| Stale provider state leading to invalid actions | Single shared ViewModel; ensureLoaded where needed | Integration: add/remove in one screen reflected in another |
| Backend error disclosure | No raw exception in UI; AppLogger for details | Grep: no `$e` or PostgrestException in snackbar/text |
| Direct DM without favorites (under locked rule) | DB policy/trigger enforces favorites for client DM insert | SQL verify + manual or integration: DM without favorite fails |
| Cross-user favorites access | RLS only allows own rows | Negative test: select/delete as other user fails |
| Rapid repeated add/remove taps | Pending-action set; disable or ignore until completion | Widget/unit: pending state blocks duplicate requests |
| UI raw exception leakage | Sanitized messages only; log via AppLogger | Grep + widget test: error state shows safe copy |

## Negative checks (explicit)

- Cross-user favorites access: must fail (RLS).  
- Direct DM insert without favorites: must fail (policy/trigger).  
- Raw backend error in UI: must not appear (grep + manual).  
- Duplicate add: must return deterministic result (e.g. “Already in favorites”), not crash.
