# UI state matrix: Favorites

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

Entry points: **Favorites screen**, **Public Profile toggle**, **Request Tile (add to favorites)**.

## Favorites screen

| State | Condition | Render / behavior |
|-------|-----------|-------------------|
| loading | `vm.isLoading == true` | Center CircularProgressIndicator |
| empty | `!loading && itemsWithProfile.isEmpty` | "No favorites yet." |
| recoverable error | `vm.error != null` | Error text (mapped); retry via refresh |
| list | items non-empty | ListView of FavoriteCards; Start Chat, Remove |
| remove success | after remove() returns success | Snackbar "Removed from favorites" |
| remove failure | after remove() returns failure/forbidden/etc. | Snackbar with sanitized error |
| chat-start failure | createOrGetConversation throws | Snackbar sanitized copy (no $e) |
| pending-action | add/remove in progress for an id | Optional: disable that row/button |

## Public profile toggle

| State | Condition | Render / behavior |
|-------|-----------|-------------------|
| loading / unknown | favorites not loaded | Show neutral or loading icon; ensureLoaded() |
| is favorite | freelancerId in vm.items | Filled heart; tap → remove |
| not favorite | not in vm.items | Outline heart; tap → add |
| pending | add/remove in progress | Disable or show loading on toggle |
| success | add/remove returns success | Update icon; optional snackbar |
| error (duplicate/forbidden/etc.) | typed result | Snackbar sanitized message |

## Request tile (add to favorites)

| State | Condition | Render / behavior |
|-------|-----------|-------------------|
| already favorite | bidderId in vm.items | Hide or disable "Add to favorites" |
| not favorite | not in vm.items | Show "Add to favorites"; tap → add via VM/callback |
| pending | add in progress | Disable button |
| success | add returns success | Snackbar "Added to favorites" |
| duplicate | add returns duplicate | Snackbar "Already in favorites" |
| error | add returns unauthenticated/forbidden/failure | Snackbar sanitized message |

## Shared

- **Sanitized copy only**: No raw exception or backend text in any snackbar or label.
- **Single source of truth**: All three entry points use the same FavoritesViewModel (app-level provider).
