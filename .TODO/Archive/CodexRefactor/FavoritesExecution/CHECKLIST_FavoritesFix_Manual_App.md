# Favorites Fix — Manual App Checklist

Use this checklist on a **running app** (device or emulator) to verify the implementation. Prerequisites: at least one client account, one or more freelancer profiles, and (optional) a task with an offer so you can test the request tile.

---

## 1. Favorites screen (single ViewModel, no crash)

- [ ] **1.1** Open the app and sign in as a **client**.
- [ ] **1.2** Navigate to **Favorites** (from main nav / drawer).
- [ ] **1.3** Screen shows either:
  - Loading → then **empty** (“No favorites yet.”), or  
  - Loading → then **list** of favorites (cards with name, “Added: …” date, Start Chat, Remove).
- [ ] **1.4** No crash when opening the screen. If you have a favorite whose profile is missing in DB, the list still loads (placeholder “Freelancer” and date).
- [ ] **1.5** Pull-to-refresh works (loading indicator, then list/empty again).

---

## 2. Add favorite from Public Profile

- [ ] **2.1** From home or search, open a **freelancer’s public profile** (not yet in favorites).
- [ ] **2.2** Tap the **heart** (favorite toggle). It should fill (red) and (if the app shows snackbars) you may see “Added to favorites” or similar.
- [ ] **2.3** Navigate to **Favorites**. That freelancer appears in the list (same state as in step 1 — **one shared list**).
- [ ] **2.4** Go back to the **same** public profile. Heart is still **filled** (no duplicate add; state is consistent).
- [ ] **2.5** Tap heart again to **remove**. Heart becomes outline. Go to Favorites again — that freelancer is **no longer** in the list.

---

## 3. Add favorite from Request Tile (offers list)

- [ ] **3.1** As a **client**, open a **task you own** that has at least one **offer** (pending request).
- [ ] **3.2** In the offers list, find a tile that shows the **heart-outline** “Add to favorites” (for a bidder not yet favorited).
- [ ] **3.3** Tap **Add to favorites**. You should see a snackbar like “Added to favorites” (no raw error or exception text).
- [ ] **3.4** Open **Favorites**. That freelancer appears in the list (same shared state).
- [ ] **3.5** If you tap “Add to favorites” again for the same bidder (e.g. from another task’s offer), you should see “Already in favorites” (no crash, no duplicate row).

---

## 4. Remove from Favorites screen (success vs error)

- [ ] **4.1** In **Favorites**, tap **Remove** (trash icon) on one card.
- [ ] **4.2** Card disappears from the list and you see a snackbar like “Removed from favorites” (**only** when remove actually succeeded).
- [ ] **4.3** Open that freelancer’s **public profile**. Heart is **outline** (not filled) — state is consistent.
- [ ] *(Optional)* Simulate failure (e.g. turn off network, remove, then retry). You should see an **error** snackbar, **not** “Removed from favorites”.

---

## 5. Start chat from Favorites (sanitized error)

- [ ] **5.1** In **Favorites**, tap **Start Chat** on a card.
- [ ] **5.2** If everything is valid: chat screen opens with that conversation.
- [ ] **5.3** If something fails (e.g. policy, network): you see a **generic** message like “Could not start chat. Please try again.”  
  - You must **not** see raw exception text (e.g. `PostgrestException`, `$e`, or SQL/DB messages) in the snackbar.

---

## 6. No raw backend errors in UI

- [ ] **6.1** While using Favorites and public profile and request tile, confirm you **never** see:
  - `PostgrestException`, `23505`, RLS/code strings, or `$e` in any snackbar or error text.
- [ ] **6.2** Errors are short, user-facing phrases (e.g. “Already in favorites.”, “Could not start chat. Please try again.”).

---

## 7. Quick regression (critical flows)

- [ ] **7.1** Add from profile → appears in Favorites → remove from Favorites → profile heart is outline.
- [ ] **7.2** Add from request tile → appears in Favorites; Favorites and profile show same state.
- [ ] **7.3** Date on favorite cards shows in a readable format (e.g. “Added: 2026-03-02  14:30”), not raw `DateTime` dump.
- [ ] **7.4** After any add/remove, no duplicate favorites for the same freelancer; list and profile/tile stay in sync.

---

## Sign-off

| Date | Tester | Pass (all checked) | Notes |
|------|--------|--------------------|-------|
|        |        | [ ]                |       |

---

*Reference: PLAN_FavoritesFix_2026-03-01, EXECUTION_LOG_PLAN_FavoritesFix_2026-03-01, DONE_CRITERIA_Favorites.*
