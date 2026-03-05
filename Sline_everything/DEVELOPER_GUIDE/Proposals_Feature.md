# Proposals Feature Reference

**Last Updated:** 2026-03-05  
**Plan:** `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`

## 1. Human Explanation

The Proposals feature is the app-facing boundary for **tender offers** (task requests): listing offers for a task, submitting/replacing/rejecting offers, awarding an offer, and completing payment for an awarded offer. It consolidates:

- **Data**: `ProposalModel`, `ProposalPaymentSummary`; repositories under `lib/features/proposals/data/` (proposal list via RPC, submit/replace/reject via `TaskRequestsService`; award/payment via secure RPCs).
- **Routes**: `openProposalPayment(context, summary)` from `lib/features/proposals/routes/proposal_payment_route.dart` — used by Inbox, Work tab, Next Actions, Work item details, and the Requests list (after award).
- **UI entry points**: `lib/features/proposals/view/` re-exports the runtime screens from `lib/features/tasks/` (proposals_list_screen → RequestsListScreen, submit_proposal_sheet, proposal_tile → RequestTile, proposal_payment_screen → TenderPaymentScreen) so the public API is the proposals module.

Security: RPCs use `auth.uid()`; no caller-supplied actor IDs. Owner list uses `get_proposal_bidder_summaries` (minimal profile fields). Self-favorite is guarded in the request tile (viewer ≠ bidder for favorite button).

## 2. Database & Supabase Mapping

- **Tables**: `task_requests`, `tasks`, `profiles` (read via RPC only for bidder names).
- **RPCs**: `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`, `get_proposal_bidder_summaries`, `finalize_awarded_offer_payment` (wrapper for non-QiCard finalize).
- **Migrations**: `20260304060000_secure_proposal_rpc_contract.sql`, `20260304061000_proposal_profile_summary_contract.sql`, `20260304062000_finalize_awarded_offer_payment.sql`.

See `SUPABASE_SETUP.md` and `.TODO/Archive/ProposalesExecution/RLS_MATRIX_Proposals_2026-03-04.md` for RLS and verification steps.

## 3. Code Inventory

| Asset | Path | Purpose |
|-------|------|---------|
| Models | `lib/features/proposals/models/proposal_model.dart`, `proposal_payment_summary.dart` | Typed proposal and payment payload |
| Repositories | `lib/features/proposals/data/proposal_repository.dart`, `proposal_award_repository.dart` | List by task (RPC), submit/replace/reject; award, finalize, get client/freelancer awarded-unpaid |
| Route | `lib/features/proposals/routes/proposal_payment_route.dart` | Single entry to open payment screen with `ProposalPaymentSummary` |
| View (re-exports) | `lib/features/proposals/view/proposals_list_screen.dart`, `widgets/submit_proposal_sheet.dart`, `widgets/proposal_tile.dart`, `proposal_payment_screen.dart` | Public proposals UI; implementation in tasks |

## 4. Testing

- **Unit**: `test/unit/proposals/proposal_model_test.dart`, `proposal_payment_summary_test.dart`
- **Widget**: `test/widget/proposals/proposal_payment_screen_test.dart`
- **Integration**: `test/integration_test/proposals/proposal_flows_placeholder_test.dart` (placeholder; full E2E per FIXTURES and RELEASE_CHECKLIST)

## 5. Observability

AppLogger in proposal repository and award repository (submit, replace, reject, award, finalize, resume, auth rejection). No PII or payment payloads. See `.TODO/Archive/ProposalesExecution/OBSERVABILITY_Proposals_2026-03-04.md`.
