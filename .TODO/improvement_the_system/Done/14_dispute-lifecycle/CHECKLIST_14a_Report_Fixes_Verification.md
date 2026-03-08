# Checklist — Verify 14a Report Fixes in the App

Use this list to confirm the fixes from the Master Report work correctly on a real device/emulator.

---

## 1. Work item details (task)

- [ ] Open a **task** work item whose status is **active** or **delivered**.
- [ ] If there is **no open dispute**: you see a **Report Issue** button (red text).
- [ ] Tap **Report Issue** → dialog with reason field → Submit: dispute is submitted and you see “Dispute submitted.” (or error message).
- [ ] If there **is** an open dispute for that task: **Report Issue** is **hidden** (not shown).

---

## 2. Work item details (direct offer)

- [ ] Open a **direct offer** work item (from unified work list) whose status is **active** or **delivered**.
- [ ] If there is **no open dispute**: you see **Report Issue**.
- [ ] Tap **Report Issue** → same dialog → Submit: dispute is submitted for the **direct offer** (not the task).
- [ ] If there **is** an open dispute for that direct offer: **Report Issue** is **hidden**.

---

## 3. Booking details

- [ ] Open **Booking details** for a booking with status **active** (in progress).
- [ ] As **client**: you see **Report Issue** (if no open dispute). Previously it only showed when status was **delivered**.
- [ ] Open **Booking details** for a booking with status **delivered**.
- [ ] As **client**: you still see **Report Issue** when there is no open dispute.
- [ ] When there **is** an open dispute for that booking: **Report Issue** is **hidden** (guard hides the button).

---

## 4. Direct offer details (existing behavior)

- [ ] Open **Direct offer details** for an offer that is active or delivered.
- [ ] Report Issue still works as before (no regression).

---

## 5. Docs / code (no app interaction)

- [ ] **MVP_ROADMAP.md**: “Booking dispute submission” row mentions Plan 14a, migration 20260308160000, Report Issue on task/direct_offer, banners.
- [ ] **STRUCTURE.md**: Recent migrations include `20260308160000_14a_dispute_extension_frozen_guards.sql`.
- [ ] **Sline_Log.md**: Top section is “14a Dispute Extension” with migration, app, and docs bullets.
- [ ] **SUPABASE_SETUP.md**: Changelog says §9.1, §9.2, §9.2a refer to the Functions (RPCs) section.

---

*After running through the checklist, you can tick items and note any failures or edge cases.*
