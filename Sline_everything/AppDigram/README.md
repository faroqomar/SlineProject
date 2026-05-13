# SLine Diagram Index

This folder is the routing index for SLine architecture, lifecycle, UI sequence, security, realtime, payment, wallet, storage, and notification diagrams. Planner and PlanCritic must use this index with `Sline_everything/DOC_SOURCE_MAP.md` and `Sline_everything/UI_SURFACE_INVENTORY.md` before creating or approving UI plans.

## Entry Diagrams

| Area | Diagram |
| --- | --- |
| Client experience overview | `Client_Diagram.md` |
| Freelancer experience overview | `Freelancer_Digram.md` |
| App UI sequence overview | `UI_Sequence/01_app_ui_diagram.md` |

## UI Sequence Diagrams

| Feature area | Diagram |
| --- | --- |
| Auth | `UI_Sequence/02_auth_ui_sequence.md` |
| Home and discovery | `UI_Sequence/03_home_discovery_ui_sequence.md` |
| Tasks and tenders | `UI_Sequence/04_task_tender_ui_sequence.md` |
| Bookings | `UI_Sequence/05_booking_ui_sequence.md` |
| Chat | `UI_Sequence/06_chat_ui_sequence.md` |
| Wallet | `UI_Sequence/07_wallet_ui_sequence.md` |
| Profile | `UI_Sequence/08_profile_ui_sequence.md` |

## System And Lifecycle Diagrams

| Feature area | Required diagrams |
| --- | --- |
| Auth and profile | `All_Diagrams/01_auth-profile-provisioning.md`, `All_Diagrams/02_role-switching-flow.md` |
| Tender tasks and requests | `All_Diagrams/03_tender-task-lifecycle.md`, `All_Diagrams/04_task-request-bid-flow.md` |
| Booking and availability | `All_Diagrams/05_booking-lifecycle.md`, `All_Diagrams/11_availability-overlap-guard.md` |
| Direct offers and work contracts | `All_Diagrams/06_direct-chat-offer-flow.md`, `All_Diagrams/19_direct-offers-work-contract.md`, `All_Diagrams/10_work-contract-revisions.md`, `All_Diagrams/12_unified-work-view.md` |
| Chat and realtime | `All_Diagrams/07_chat-creation-matrix.md`, `All_Diagrams/08_chat-realtime-sync.md`, `All_Diagrams/18_realtime-subscription-topology.md` |
| Notifications | `All_Diagrams/13_notification-routing.md`, `All_Diagrams/18_realtime-subscription-topology.md` |
| Safety and disputes | `All_Diagrams/14_dispute-lifecycle.md`, `All_Diagrams/14a_dispute-entity-freeze-integration.md` |
| Authorization and storage | `All_Diagrams/15_rls-authorization-map.md`, `All_Diagrams/17_storage-signed-urls-flow.md` |
| Payment, escrow, wallet, withdrawals | `All_Diagrams/09_ledger-event-flow.md`, `All_Diagrams/16_escrow-invariants-idempotency.md`, `All_Diagrams/20_withdrawals-lifecycle.md`, `All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`, `All_Diagrams/22_Dynamic_Platform_Fee.md`, `All_Diagrams/24_hardened_paymentLinking_system.md` |
| Admin finance | `All_Diagrams/23_Admin_Dashboard_Wallet_Finance.md` |

## Maintenance Rule

When a feature flow changes, update the matching diagram and this index in the same DocsKeeper pass. If a plan changes schema, lifecycle, payment, wallet, booking, chat, realtime, storage, notification, dispute, or admin behavior and no matching diagram exists, create one before marking docs complete. If a UI surface changes, update `Sline_everything/UI_SURFACE_INVENTORY.md` in the same docs pass.
