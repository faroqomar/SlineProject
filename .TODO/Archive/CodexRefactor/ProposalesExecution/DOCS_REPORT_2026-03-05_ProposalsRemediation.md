# DocsKeeper Report: Proposals Remediation 2026-03-05

**Scope**: Proposals Remediation  
**Plan**: `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`  
**Evidence**: Scanned `Sline_everything/` for refs to proposals, requests_list_screen, RequestTile, TenderPaymentScreen, task_requests_service, ProposalDetailsModal; verified DEVELOPER_GUIDE TOC and links.

---

## 1. Documentation delta (already done in Phase 5)

| Doc | Change |
|-----|--------|
| DEVELOPER_GUIDE.md | TOC + Feature Map + Quick Link; version 2.17.3; Proposals entry. |
| DEVELOPER_GUIDE/Proposals_Feature.md | **Created**: human explanation, DB mapping, code inventory, testing, observability. |
| STRUCTURE.md | Proposals feature highlight; unit/widget proposals test paths. |
| MVP_ROADMAP.md | "Services/proposals surfacing" → Completed; ref to Proposals_Feature.md. |
| Sline_Log.md | Proposals Remediation entry (date, implemented, impact). |
| SUPABASE_SETUP.md | Last Updated + migration refs (20260304*). |

---

## 2. Reference integrity scan

| Reference | Target | Status |
|-----------|--------|--------|
| DEVELOPER_GUIDE.md → Proposals_Feature.md | `DEVELOPER_GUIDE/Proposals_Feature.md` | ✅ File exists |
| MVP_ROADMAP → DEVELOPER_GUIDE/Proposals_Feature.md | Same | ✅ |
| STRUCTURE proposals paths | `lib/features/proposals/`, test paths | ✅ Match repo |
| Proposals_Feature.md paths (models, data, routes, view) | Repo paths | ✅ Match |
| CODE_REVIEW.md RequestTile / requests_list_screen | Still accurate (FavoritesViewModel, path) | ✅ |
| Task Feature.md task_requests_service | Still accurate | ✅ |
| Sline_Log.md ProposalDetailsModal deprecated | Accurate | ✅ |

No broken internal links or missing files found.

---

## 3. Outdated statements (optional polish)

| Location | Statement | Recommendation |
|----------|-----------|----------------|
| DEVELOPER_GUIDE.md § Tender payment (long para) | Describes Inbox/Work creating coordinator + ViewModel and pushing; does not mention `openProposalPayment` | MED: Add one sentence: "All payment entry points (Inbox, Work, Next Actions, Work Details, Requests list after award) use `openProposalPayment(context, summary)` from `lib/features/proposals/routes/proposal_payment_route.dart`." |
| TASK_TENDER_PAYMENT_PLAN.md, TENDER_PAYMENT_VERIFICATION_CHECKLIST.md | Historical plan/checklist; reference RequestsListScreen, TenderPaymentScreen directly | LOW: Leave as-is (historical); or add note "Payment entry is now centralized via openProposalPayment (see Proposals_Feature.md)." |

---

## 4. Renamed / moved files (none)

- No renames; proposals view layer is re-exports. task_details_screen now imports from `proposals/view/proposals_list_screen.dart`; doc reflects proposals as entry.

---

## 5. Required doc updates (none blocking)

- All Phase 5 doc updates are done.
- Optional: DEVELOPER_GUIDE tender payment paragraph (add openProposalPayment sentence) for consistency.
- No BLOCKER; no broken refs.

---

## 6. Summary

- **Delta**: Completed in Phase 5; Proposals_Feature.md is the single deep-dive.
- **Integrity**: Refs and paths valid.
- **Optional**: One-sentence addition in DEVELOPER_GUIDE for payment entry point.
- **Decision**: APPROVED; no BLOCKER.
