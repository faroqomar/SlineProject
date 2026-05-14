# OpenDesign Amber Dusk Phases 2-4 Screenshot Export

Date: 2026-05-11  
Status: OPEN DESIGN REFERENCE EVIDENCE ONLY  
Source project: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`  
Source entry: `Sline V2 Amber Dusk.html`  
Design system file: `amber-dusk-design-system.html`  
Export method: Open Design MCP re-check, then Playwright render of the current Open Design project file under the Open Design data store.

These screenshots are pre-implementation design references. They are not Flutter runtime QA evidence and must not be used to close emulator visual QA by themselves.

## Exported Screenshots

| Phase | Screenshot | Evidence Use | SHA-256 |
|---|---|---|---|
| 2 | `phase2-home-shell-fab-nav.png` | Home shell, four-item bottom nav, amber FAB | `630883a8c811b53a7e71dc0dcdf80992d1da0e147251ef6035bfcd65e3a4b46e` |
| 2 | `phase2-dashboard-nav-active.png` | Dashboard nav active state and shell | `f2ee4e9f4e81c1ecbdcc79f586a645740a10ff3d0b84107b9bbdfd2d75e878e8` |
| 2 | `phase2-messages-nav-active.png` | Messages nav active state and shell | `a8a42cca5661bf71fd908c0e4a881268ba5a647085d432e110357af77274fc3c` |
| 2 | `phase2-profile-nav-active.png` | Profile nav active state and shell | `9360c952839845f8b683672759700c6c4d7ba1415eedd41e82ea41ccb27f7628` |
| 2 | `phase2-create-type-tender-selected.png` | Create sheet type step with Tender selected | `ed75e32fa325b43d61546a5e4d452225a48b321e4dabd465002b7f2ebdd112de` |
| 2 | `phase2-create-type-booking-selected.png` | Create sheet type step with Booking selected | `5e89c4f7c0e8fbf10a1bd5c86e4ce6139a326e00ed4aebcad0f19917cb88d12e` |
| 2 | `phase2-create-tender-details.png` | Tender details form step | `892332f75d061759c99eb009de0e20831359e9cd8a98a30a612e4c17bed88ddb` |
| 2 | `phase2-create-tender-review.png` | Tender review card preview step | `b2f72f1fd6aefb7322fa5b5bf51a28811e9290390c88350106ca9e1c5a36c249` |
| 2 | `phase2-create-booking-details.png` | Booking details form step | `2cbf40a0d0262b955628d2136e94848ae0c1e65494fdc31d1cfc4d62ff7c73c3` |
| 2 | `phase2-create-booking-review.png` | Booking review card preview step | `5b282c5f2c4887de101bfdae83ff65ec3efa8bc9f6c6aa77daa20b927e8ac813` |
| 3 | `phase3-home-all-feed.png` | Home All feed with mixed posts | `630883a8c811b53a7e71dc0dcdf80992d1da0e147251ef6035bfcd65e3a4b46e` |
| 3 | `phase3-home-bookings-filter.png` | Home Bookings segment | `6f0d6f0e7a59fe376541a98888b1a7a12fd2546647721114f676000b89775ed4` |
| 3 | `phase3-home-tasks-filter.png` | Home Tasks/Tenders segment | `b548847d476051f2114395de9c084ea910f8bb9e724351f4f9e8004608b6b3b5` |
| 4 | `phase4-dashboard-overview.png` | Dashboard Overview tab | `f2ee4e9f4e81c1ecbdcc79f586a645740a10ff3d0b84107b9bbdfd2d75e878e8` |
| 4 | `phase4-dashboard-bookings.png` | Dashboard Bookings tab | `74b47fc560055427510da41e85dcdff26b27b1b587284ea4aaec9c9cc3dbdf26` |
| 4 | `phase4-dashboard-work-active.png` | Dashboard Work Active bucket | `123b6203b49d02f63be7e8e4cc04b11db71033198e113d7440de365688148383` |
| 4 | `phase4-dashboard-work-done.png` | Dashboard Work Done bucket | `5c871c48b7ec3507796db53622df0f069ad2a0fcb73ab6949dd2676a4aa20cd8` |
| 4 | `phase4-dashboard-work-cancelled.png` | Dashboard Work Cancelled bucket | `213e179d7bc30122e4fdf6a3dcdb99d2693a0ddf75861853ce409617072b7da2` |
| 4 | `phase4-dashboard-wallet.png` | Dashboard Wallet tab | `11e58617c629547afb882713ec89feeb8be5bcb329fa75f5edb965ab13d93287` |
| 4 | `phase4-dashboard-inbox.png` | Dashboard Inbox tab | `dd642ec4dd2d683c9a9bbfdcc0cc0e47443e1058136bf01eb543b5d1ff471309` |

Duplicate hashes are intentional where the same visible state is reused by two evidence labels:

- `phase2-home-shell-fab-nav.png` and `phase3-home-all-feed.png`
- `phase2-dashboard-nav-active.png` and `phase4-dashboard-overview.png`

## Visual Notes

### Phase 2 Shell And Create

- Home is the only route with the floating amber create action.
- Bottom nav has exactly four destinations: Home, Dashboard, Messages, Profile.
- Active nav state uses a compact amber icon capsule; inactive items stay muted.
- Create post is a bottom sheet with three steps: type selection, details, review.
- Tender and Booking are type choices, not nav destinations.
- Tender review uses the quieter task/tender card material.
- Booking review uses the hero booking-card material.

### Phase 3 Discovery

- Home has one mixed feed with `All`, `Bookings`, and `Tasks` chips.
- Booking cards are the visual hero and use the rust/hero gradient material.
- Task/Tender cards are quieter raised panels with compact title, copy, price, tags, and action treatment.
- The current MCP artifact only shows search input/placeholder behavior, not a full Search results screen.
- The current MCP artifact does not provide full Categories, Saved, or Favorites phone screens.

### Phase 4 Dashboard

- Dashboard tab model is `Overview`, `Bookings`, `Work`, `Wallet`, `Inbox`.
- Work tab bucket model is `Active`, `Done`, `Cancelled`.
- Work cards are dark raised panels with compact source/status/money/progress hierarchy.
- Wallet uses the hero surface treatment but remains a dashboard tab, not a separate redesign scope here.
- Inbox uses compact message/offer-style rows and must preserve action routing in Flutter.

## Not Exported From Current MCP Artifact

These states were searched for in the current Open Design MCP project and were not available as full phone screens:

- Search results screen.
- Categories screen.
- Saved list screen.
- Favorites list screen.
- Loading states.
- Empty states.
- Error states.
- Create validation failure, create loading, create success, and create failure states.
- Dashboard role-specific variants beyond the visible prototype state.
- Dashboard empty/loading/error states.
- Dashboard-launched work, booking, and payment detail screens.

Implementation rule: exact visual matching is blocked for the missing states above until the user provides screenshots or Open Design is updated. Token-normalization and state hardening are still allowed where the phase plan permits them.

