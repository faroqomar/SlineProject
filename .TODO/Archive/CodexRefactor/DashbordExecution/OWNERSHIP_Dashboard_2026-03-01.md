# Dashboard Remediation – State Ownership

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

One owner per live surface; Manage excluded from target architecture.

## Live Owners

| Owner | Scope | Notes |
|-------|--------|-------|
| dashboard_shell | Tab bar, active tab, navigation | DashboardScreen; mounts Overview, Bookings, Work, Inbox only. |
| dashboard_role | Current role (client/freelancer), sync from backend | Role state and switcher; may be separate ViewModel or part of shell. |
| dashboard_overview | Counters, next actions, activity feed, wallet snapshot | OverviewTab; wallet snapshot reads from wallet owner. |
| dashboard_bookings | Bookings list and card actions | BookingsTab; uses BookingService via ViewModel. |
| dashboard_work | Work items, bucketing, start/review/pay CTAs | WorkTab; uses TaskService and work item data. |
| dashboard_inbox | Inbox offers, award/pay/reject/refund/withdraw | InboxTab; uses TaskService and tender coordinator. |
| wallet | Balances, load, snapshot contract | WalletViewModel; dashboard overview consumes, must load on first entry. |
| services/my_services | MyServicesScreen data | Owned by services feature; MyServicesViewModel (new); no DashboardViewModel. |
| dashboard_cache | SWR/cache for dashboard data | DashboardCacheService; must be wired in DI to DashboardViewModel or removed. |

## Out of Scope (No New Owner)

- **Manage tab**: Dead runtime; do not create dashboard_management_view_model. Remove manage_tab.dart, manage_service_list.dart, manage_task_list.dart and related dead state.
- **Finance metrics**: Not owned by standard dashboard; remove or admin-only RPC.

## Contract

- Each live dashboard surface has exactly one state owner (ViewModel or equivalent).
- Widgets in dashboard that display booking/task/wallet data consume feature-owned widgets or shared presenters; data still provided by dashboard ViewModels/repos until widget move is done, then by feature owners.
