# SLine Documentation Source Map

This file tells Planner, PlanCritic, Executor, Orchestrator, Sentinel, and DocsKeeper which documentation and diagrams must be read for each feature area. Use it with `Sline_everything/AppDiagram/README.md`.

## Global Sources

Read these for every non-trivial plan or review:

- `README.md`
- `AGENTS.md`
- `.cursor/PROJECT_CONTEXT.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/Sline_Log.md`
- `Sline_everything/UI_SURFACE_INVENTORY.md` for UI, navigation, redesign, modal, popup, tab, route, or reusable-widget work
- `Sline_everything/AppDiagram/README.md`

For backend, policy, storage, payment, or realtime work, also read:

- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/AppDiagram/All_Diagrams/15_rls-authorization-map.md`
- `Sline_everything/AppDiagram/All_Diagrams/18_realtime-subscription-topology.md` when realtime streams are involved

## Feature Source Map

| Feature area | Feature docs | Required diagrams |
| --- | --- | --- |
| Auth, profile, role switching | `Sline_everything/DEVELOPER_GUIDE/Auth Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Profile Feature.md` | `All_Diagrams/01_auth-profile-provisioning.md`, `All_Diagrams/02_role-switching-flow.md`, `UI_Sequence/02_auth_ui_sequence.md`, `UI_Sequence/08_profile_ui_sequence.md` |
| Home, discovery, search, categories | `Sline_everything/DEVELOPER_GUIDE/Home Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Categories Feature.md` | `UI_Sequence/03_home_discovery_ui_sequence.md`, `Client_Diagram.md`, `Freelancer_Diagram.md` |
| Tasks, tenders, requests, proposals | `Sline_everything/DEVELOPER_GUIDE/Task Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Proposals_Feature.md`, `Sline_everything/FEATURE_BID_FLOW.md`, `Sline_everything/TASK_TENDER_PAYMENT_PLAN.md` | `All_Diagrams/03_tender-task-lifecycle.md`, `All_Diagrams/04_task-request-bid-flow.md`, `UI_Sequence/04_task_tender_ui_sequence.md` |
| Booking and availability | `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md` | `All_Diagrams/05_booking-lifecycle.md`, `All_Diagrams/11_availability-overlap-guard.md`, `UI_Sequence/05_booking_ui_sequence.md` |
| Chat, attachments, direct messages | `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` | `All_Diagrams/07_chat-creation-matrix.md`, `All_Diagrams/08_chat-realtime-sync.md`, `All_Diagrams/17_storage-signed-urls-flow.md`, `All_Diagrams/18_realtime-subscription-topology.md`, `UI_Sequence/06_chat_ui_sequence.md` |
| Direct offers and work contracts | `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Order_Management_Feature.md` | `All_Diagrams/06_direct-chat-offer-flow.md`, `All_Diagrams/10_work-contract-revisions.md`, `All_Diagrams/12_unified-work-view.md`, `All_Diagrams/19_direct-offers-work-contract.md` |
| Wallet, escrow, payment, withdrawals | `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md`, `Sline_everything/Payment_Gateway/Qi_Service/documentation.md`, `Sline_everything/API_CONTRACT_HardenedPaymentGateway.md`, `Sline_everything/TENDER_PAYMENT_VERIFICATION_CHECKLIST.md` | `All_Diagrams/09_ledger-event-flow.md`, `All_Diagrams/16_escrow-invariants-idempotency.md`, `All_Diagrams/20_withdrawals-lifecycle.md`, `All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`, `All_Diagrams/22_Dynamic_Platform_Fee.md`, `All_Diagrams/24_hardened_paymentLinking_system.md`, `UI_Sequence/07_wallet_ui_sequence.md` |
| Notifications and realtime streams | `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md` | `All_Diagrams/13_notification-routing.md`, `All_Diagrams/18_realtime-subscription-topology.md` |
| Safety, reports, disputes | `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md` | `All_Diagrams/14_dispute-lifecycle.md`, `All_Diagrams/14a_dispute-entity-freeze-integration.md`, `All_Diagrams/15_rls-authorization-map.md` |
| Portfolio, favorites, saved tasks | `Sline_everything/DEVELOPER_GUIDE/Portfolio Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md`, `Sline_everything/DEVELOPER_GUIDE/Saved Feature.md` | `Client_Diagram.md`, `Freelancer_Diagram.md`, `All_Diagrams/17_storage-signed-urls-flow.md` |
| Admin, finance, platform controls | `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md` | `All_Diagrams/23_Admin_Dashboard_Wallet_Finance.md`, `All_Diagrams/15_rls-authorization-map.md` |
| UI redesign and theme work | `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/STRUCTURE.md`, `Sline_everything/CODE_REVIEW.md`, `Sline_everything/UI_SURFACE_INVENTORY.md`, active `.TODO/PLAN_OpenDesign_*.md` files | Relevant `UI_Sequence/*.md`, `Client_Diagram.md`, `Freelancer_Diagram.md`, and active Open Design screenshot manifests |

## Planning Rule

Every new plan must list the docs and diagrams read in `Documentation And Diagram Sources`. If a feature area is not listed here, Planner must add a new row before closing the plan, and DocsKeeper must keep this file current.

For UI work, every new plan must also list affected rows from `Sline_everything/UI_SURFACE_INVENTORY.md` and include an update step when new or missed UI surfaces are discovered.

## Review Rule

PlanCritic and Orchestrator must fail or flag any plan/review that skips the required source map or UI inventory for the touched feature area.
