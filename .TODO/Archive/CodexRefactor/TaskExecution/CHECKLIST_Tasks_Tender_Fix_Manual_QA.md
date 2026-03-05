# Checklist: Tasks Tender Fix — Manual QA on the App

Use this list to verify the implemented changes on a running build (device or emulator).  
**Plan/scope:** Tasks Tender Fix (fail-closed payment, replace_task_request, active_role removal).

---

## Prerequisites

- [ ] App builds and runs: `flutter run`
- [ ] You can sign in as at least two users: one **client**, one **freelancer** (or one user who can switch role).
- [ ] Supabase: migration `20260311000000_replace_task_request.sql` has been applied to your project (so replace offer works).

---

## 1. Tender payment — fail-closed (Demo / QiCard)

**Goal:** Tender “Complete Payment” must not advance state when payment is demo or QiCard fallback; user sees an error and no ledger/pay RPC runs.

| # | Step | Expected result | ✓ |
|---|------|------------------|---|
| 1.1 | Sign in as **client**. Create a **tender** task (or use an existing open tender). | Task exists and is open. | |
| 1.2 | As **freelancer**, submit an offer on that task. | Offer appears in request list. | |
| 1.3 | As **client**, open the task → Requests → **Award** the freelancer’s offer. | Offer is awarded (pending payment). | |
| 1.4 | As **client**, tap **Pay** / **Complete Payment** (from task Requests or from Dashboard Inbox). | **TenderPaymentScreen** (or payment flow) opens. | |
| 1.5 | On the payment screen, tap **Complete Payment** (or equivalent). | **Error message** appears, e.g. “Tender payment requires real payment…” or “Tender payment is not yet available…”. **No** success toast and **no** navigation to “Payment successful”. | |
| 1.6 | Confirm the task/offer is still in “awarded, unpaid” state (e.g. still in Inbox as “Pay now” or similar). | State did **not** change to paid/held. | |

**Notes:**  
- If the app is built with `USE_QICARD_PAYMENT=false`, you get the Demo message.  
- If built with default (QiCard), you get the QiCard fallback message.  
- In both cases, payment must **fail closed** (no ledger, no `pay_awarded_offer`).

---

## 2. Offer submission — no active_role mutation (RLS message)

**Goal:** Submitting an offer no longer mutates `profiles.active_role`. If the user is not in freelancer role, insert is denied by RLS and the app shows the new message.

| # | Step | Expected result | ✓ |
|---|------|------------------|---|
| 2.1 | Sign in and switch to **client** role (profile/settings → role = Client). | Current role is client. | |
| 2.2 | Open an **open tender** task (not your own) and tap to **submit an offer** (or open the submit-offer sheet). | Submit offer UI is available. | |
| 2.3 | Enter price, days, optional note and tap **Submit** (or **Send offer**). | **Error message** appears: “You must be in freelancer mode to submit an offer. Switch your role in profile settings.” (or equivalent). **No** silent success. | |
| 2.4 | Switch role to **Freelancer** (profile/settings). | Role is now freelancer. | |
| 2.5 | Submit an offer again on the same (or another) open tender. | Offer submits **successfully**; it appears in the request list. | |

**Notes:**  
- If your RLS already allows insert for this user (e.g. role is freelancer), you only see success in 2.5; use 2.1–2.3 to force the “must be freelancer” path.  
- Confirms the app no longer updates `profiles.active_role` before insert and relies on RLS + the new UX message.

---

## 3. Replace offer — RPC works (after migration)

**Goal:** Freelancer can replace their pending offer; `replace_task_request` is called and the new offer is visible.

| # | Step | Expected result | ✓ |
|---|------|------------------|---|
| 3.1 | Sign in as **freelancer**. Open a tender task where **you already have a pending offer**. | You see your offer (e.g. in request list or in submit sheet). | |
| 3.2 | Open the **replace / edit offer** flow (e.g. “Replace offer” or “Edit offer” in the submit sheet or request list). | Replace UI opens with current price/days/note. | |
| 3.3 | Change **price** and/or **days** and/or **note**, then confirm **Replace** (or **Update offer**). | Request completes **without** error (no “RPC not found” or 500). | |
| 3.4 | Confirm the list/sheet shows the **new** price/days (and note if shown). | Data reflects the replacement; old offer is replaced, not duplicated. | |

**Notes:**  
- If migration `20260311000000_replace_task_request.sql` is **not** applied, step 3.3 will fail (e.g. function does not exist). Apply the migration first.  
- If you are not in freelancer role, the RPC may raise “only freelancers can replace offers”; that’s expected after the security fix.

---

## 4. Quick smoke (no regressions)

**Goal:** Core task and discovery flows still work.

| # | Step | Expected result | ✓ |
|---|------|------------------|---|
| 4.1 | Open **Home** / Tenders tab. | Tender tasks load; no crash. | |
| 4.2 | Open a **task detail** (tender or booking). | Detail loads; actions (e.g. Book, Submit offer) are available as before. | |
| 4.3 | As client, **award** an offer (without completing payment). | Award succeeds; “Pay now” or similar appears in Inbox/task. | |
| 4.4 | Open **Dashboard** → Inbox. | Awarded/unpaid offers appear; no crash. | |

---

## 5. Summary

| Area | What was checked |
|------|-------------------|
| **Tender payment** | Fail-closed: error shown, no state advance when using Demo/QiCard. |
| **Offer submit** | No active_role mutation; “must be freelancer” message when RLS denies. |
| **Replace offer** | Replace succeeds when migration applied and user is freelancer. |
| **Smoke** | Home, task detail, award, dashboard Inbox work without regression. |

---

**Sign-off:**  
Date: ___________  
Build: ___________  
Tester: ___________
