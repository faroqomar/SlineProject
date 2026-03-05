# Proposals Remediation — App Verification Checklist & Summary

Use this to **check the real app** and to understand **what changed and why**.

---

## Part 1: What to check on the actual app

Run through these on a device/emulator with at least one **tender task**, one **freelancer** that can submit offers, and one **client** that can award and pay.

### As freelancer

| # | What to do | What you should see |
|---|------------|---------------------|
| 1 | Open a **tender task** (not booking) → tap **View offers** or open the offers list. | Offers list opens (Offers screen). |
| 2 | Tap **New offer** (FAB) → submit price + days + note. | Offer appears in the list; no crash. |
| 3 | On **your own** offer row. | **No heart (favorite)** button on your row (self-favorite guard). |
| 4 | On **another** freelancer’s offer row (if any). | Heart (Add to favorites) is visible. |
| 5 | If you already have a pending offer, tap **New offer** again and change price/days (replace). | Replace flow works; list updates. |

### As client (task owner)

| # | What to do | What you should see |
|---|------------|---------------------|
| 6 | Open the same tender task → **Offers** list. | List loads with **bidder names** (RLS-safe from proposal RPC). |
| 7 | Tap **Reject** on an offer. | Offer disappears or shows rejected. |
| 8 | Tap **Award** on an offer → confirm in dialog. | **Payment screen** opens with correct **task title**, **freelancer name**, **amount**, and **deadline** (not a UUID as title). |
| 9 | From **Inbox** tab → find “awarded, waiting payment” → tap **Pay**. | Same payment screen opens (launcher: Inbox). |
| 10 | From **Work** tab → find “Waiting payment” → tap **Pay**. | Same payment screen opens (launcher: Work). |
| 11 | From **Next actions** (if you have a pay-escrow item) → tap **Pay**. | Same payment screen opens. |
| 12 | From **Work** → open a work item that has “Pay” → tap **Pay**. | Same payment screen opens. |
| 13 | On payment screen → complete or cancel. | No crash; back to previous screen; state refreshes (e.g. Work/Inbox) after return. |

### Role guard

| # | What to do | What you should see |
|---|------------|---------------------|
| 14 | As **client** (profile role = client), open a tender and try to submit an offer. | Message like “You must be in freelancer mode to submit a proposal. Switch your role in profile settings.” (no silent failure, no DB role change from app). |

### Quick smoke

| # | What to do | What you should see |
|---|------------|---------------------|
| 15 | Open **task details** → tap to open **Offers** (proposals list). | Screen opens from proposals module (same UI as before). |
| 16 | Pull to refresh on Offers list (as owner). | List reloads; bidder names still show. |

### Reject-offer fix (DB migrations required)

Rejecting an offer failed due to two guards: **"task owner cannot start a task-linked conversation"** and **"initiated_by must equal current user"**. Apply the newer migration to fix both.

| Step | Action |
|------|--------|
| 1 | Apply **`20260305071000_conversations_guard_allow_owner_reject.sql`** (adds GUC exception to conversations guard; `reject_task_request` sets GUC and uses `initiated_by = v_owner`). Skip `20260305070000_...`; 071000 is the correct fix. |
| 2 | Re-test **Reject** from Inbox (Offer card) and from task **Offers** list (step 7 above). | Reject succeeds; offer shows rejected. |

The guard allows the task owner to create a task-linked conversation only when `app.allow_owner_task_conversation = 'true'` (set by `reject_task_request`). So `initiated_by = v_owner` satisfies "initiated_by must equal current user" and the GUC satisfies the non-owner rule.

---

## Part 2: What was done — short summary

### Why we did it

- **Security**: Proposal RPCs now use the **logged-in user** only (no spoofing client/freelancer IDs).
- **Single payment entry**: One place opens the payment screen from Inbox, Work, Next Actions, Work details, and after award.
- **RLS-safe owner list**: When you’re the task owner, offer list and bidder names come from a **proposal RPC**, not a direct profiles join.
- **Observability**: Payment screen opens and “resume” paths are **logged** (with launcher name, no PII).
- **Docs and tests**: Docs and tests were updated so the app and DB behavior are clear and repeatable.

---

## Part 3: What was added

| Area | What was added |
|------|----------------|
| **Feature module** | `lib/features/proposals/`: **models** (ProposalModel, ProposalPaymentSummary), **data** (ProposalRepository, ProposalAwardRepository), **routes** (proposal_payment_route.dart with `openProposalPayment`), **view** (re-exports for list/sheet/tile/payment screen). |
| **DB (Supabase)** | Three migrations (via MCP): RPCs fixed to use `auth.uid()`; `get_proposal_bidder_summaries` for owner bidder names; `finalize_awarded_offer_payment` wrapper. **Plus** `20260305071000_conversations_guard_allow_owner_reject`: conversations guard allows owner-created task convo when `app.allow_owner_task_conversation=true`; `reject_task_request` sets that GUC and uses `initiated_by = v_owner` so reject-from-Inbox works. |
| **App entry** | **main.dart**: Providers for `ProposalRepository` and `ProposalAwardRepository`. |
| **Owner list path** | **TaskRequestsViewModel** can take an optional `ProposalRepository`; when **owner**, list loads via `ProposalRepository.listByTask(isOwner: true)` and maps to `TaskRequest` (RLS-safe names). |
| **Payment route** | **openProposalPayment(context, summary, launcherSource?)** in `lib/features/proposals/routes/proposal_payment_route.dart`; all “Pay” entry points call it with a `ProposalPaymentSummary`. |
| **Logging** | **AppLogger** in proposal repos and in **openProposalPayment** (payment screen opened + optional launcher source). |
| **Self-favorite guard** | **RequestTile** gets optional `viewerUserId`; favorite button **hidden** when the viewer is the bidder (no self-favorite). |
| **Model mapping** | **TaskRequest.fromProposal(ProposalModel)** for owner list that uses ProposalRepository. |
| **Tests** | Unit: proposal_model, proposal_payment_summary, TaskRequest.fromProposal. Widget: proposal_payment_screen. Integration: placeholder under `test/integration_test/proposals/`. |
| **Docs** | DEVELOPER_GUIDE (Proposals + tender payment sentence), STRUCTURE, MVP_ROADMAP, Sline_Log, SUPABASE_SETUP, **Proposals_Feature.md**; notes in TASK_TENDER_PAYMENT_PLAN and TENDER_PAYMENT_VERIFICATION_CHECKLIST. |

---

## Part 4: What was removed

| Area | What was removed |
|------|------------------|
| **Client role mutation** | App **no longer** updates `profiles.active_role` when submitting an offer; submit fails with a clear message if not in freelancer mode. |
| **Direct payment pushes** | Inbox, Work, Next Actions, Work details, and Requests list **no longer** build `TenderPaymentCoordinator` / `TenderPaymentViewModel` / `TenderPaymentScreen` themselves; they all call **openProposalPayment** instead. |
| **Unused imports** | Removed **PaymentService**, **TaskService**, **TenderPaymentCoordinator**, **TenderPaymentScreen**, **TenderPaymentViewModel** imports from requests_list_screen, work_tab, next_actions_list, work_item_details_screen where they were only used for the old payment push. |
| **Deprecated UI** | **ProposalDetailsModal** marked `@Deprecated` (no call sites; replaced by list + tile). |

---

## Part 5: What was modified

| Area | What was modified |
|------|--------------------|
| **RequestsListScreen** | Award success now builds **ProposalPaymentSummary** and calls **openProposalPayment** (with launcherSource `requests_list`); **task title** comes from the request (not taskId); injects **ProposalRepository** when owner and passes it into **TaskRequestsViewModel**. |
| **TaskRequestsViewModel** | Optional **ProposalRepository**; when owner, **loadInitial** / **loadMore** use it and map **ProposalModel → TaskRequest**; **award** / **payForAwardedOffer** / **accept** refresh list via **_refreshListAfterMutation** (same source as load). |
| **RequestTile** | New optional **viewerUserId**; favorite button only shown when `viewerUserId != request.bidderId`. |
| **Inbox / Work / Next Actions / Work details** | Pay-escrow actions build **ProposalPaymentSummary** and call **openProposalPayment(context, summary, launcherSource: '…')**; unused payment/task service imports removed. |
| **Task details screen** | Imports **RequestsListScreen** from **proposals** view (proposals_list_screen re-export) instead of from tasks. |
| **TaskRequest (model)** | New **fromProposal(ProposalModel)** factory for owner-list mapping. |
| **Docs** | DEVELOPER_GUIDE tender payment paragraph, TASK_TENDER_PAYMENT_PLAN, TENDER_PAYMENT_VERIFICATION_CHECKLIST updated to mention **openProposalPayment** and Proposals_Feature. |

---

## Part 6: One-line summary

**Proposals remediation**: secure RPCs and single payment route; owner list uses proposal RPC for RLS-safe names; payment entry only via **openProposalPayment**; no client role mutation; self-favorite hidden; logging and docs updated.
