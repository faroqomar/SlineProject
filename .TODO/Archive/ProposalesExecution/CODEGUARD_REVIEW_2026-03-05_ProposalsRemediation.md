# CodeGuard Review: Proposals Remediation 2026-03-05

**Scope**: Proposals Remediation  
**Plan**: `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`  
**Evidence**: `flutter analyze` on proposals/tasks/dashboard/work/core; grep for print; review of repos and route for security/performance/compatibility.

---

## 1. Risk rating

| Area | Rating | Notes |
|------|--------|-------|
| Security | LOW | RPCs bound to auth.uid() (migrations applied via MCP). No caller-supplied actor IDs. Self-favorite guard in UI. |
| Data integrity | LOW | Single finalize path; server enforces deadline and owner. |
| Performance | LOW | List uses one optional RPC for bidder summaries (owner); no N+1 in payment summary lists. |
| Compatibility | LOW | Additive only; re-exports and route; existing TaskRequestsViewModel/TaskService still used. |

**Overall**: LOW risk.

---

## 2. Security

| Check | Result |
|-------|--------|
| Auth bound in RPCs | ✅ award_task_offer, pay_awarded_offer, cancel_awarded_offer, get_client_awarded_unpaid_offers, get_freelancer_awarded_unpaid_offers use auth.uid() (secure_proposal_rpc_contract applied). |
| get_proposal_bidder_summaries | ✅ SECURITY DEFINER, owner filter t.owner_id = auth.uid(). |
| finalize_awarded_offer_payment | ✅ Delegates to pay_awarded_offer (auth bound). |
| Client-side actor spoofing | ✅ App does not pass client_id/freelancer_id for auth; RPCs ignore params. |
| Self-favorite | ✅ RequestTile hides favorite when viewerUserId == request.bidderId. |
| No Supabase in UI | ✅ Verified; no .from()/.rpc() in view layer. |

No BLOCKER.

---

## 3. Performance

| Check | Result |
|-------|--------|
| ProposalRepository.listByTask | Single task_requests select + single get_proposal_bidder_summaries RPC when isOwner. No per-row RPC. ✅ |
| getClientAwardedUnpaid / getFreelancerAwardedUnpaid | Single RPC each; map in memory. ✅ |
| Payment route | Builds coordinator + VM once per navigation. ✅ |

No BLOCKER.

---

## 4. Compatibility / freshness

| Check | Result |
|-------|--------|
| Flutter analyze | ✅ No issues (lib/features/proposals, tasks, dashboard, work, core). |
| print() in proposals | ✅ None. |
| Existing callers | Task_details_screen imports proposals_list_screen; Inbox/Work/Next Actions/Work Details use openProposalPayment. TaskRequestsViewModel still used for list/submit/award in RequestsListScreen. No breaking change. |
| Dependencies | No new pub dependencies for proposals. ✅ |

No BLOCKER.

---

## 5. Verification commands

```bash
flutter analyze lib/features/proposals lib/features/tasks lib/features/dashboard lib/features/work lib/core
flutter test test/unit/proposals test/widget/proposals test/unit/models/task_request_model_test.dart test/widget/tasks/tender_payment_screen_test.dart test/unit/tasks/tender_payment_coordinator_test.dart
```

Both must pass before release (per RELEASE_CHECKLIST).

---

## 6. Blocker / decision

- **BLOCKERs**: None.
- **Decision**: **APPROVED ✅**

Proposals remediation is ready from a CodeGuard perspective subject to RELEASE_CHECKLIST (manual E2E, SQL/RLS verification).
