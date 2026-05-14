# Open Design Screenshot Export: Amber Dusk Phases 5-8

**Date:** 2026-05-12  
**Open Design project:** `1674a1db-7a74-4c80-8e2c-196a0385a8f7`  
**Primary entry:** `Sline V2 Amber Dusk.html`  
**Supplemental entry:** `sline-v2-amber-dusk-web.html`  
**Purpose:** Pre-implementation reference captures for the Phase 5-8 phone plan.

These screenshots were exported from the local Open Design artifact after re-checking the Open Design MCP project state. Phone screenshots are implementation reference evidence where the design contains a matching phone surface. Web screenshots are supplemental only and must not be treated as phone pixel-parity targets.

## Exported Phone References

| Phase | Screenshot | Evidence use |
|---|---|---|
| 5 | `phase5-phone-profile-account-settings.png` | Profile/account settings density and edit-row pattern for trust-adjacent surfaces. |
| 5 | `phase5-phone-profile-security-sheet.png` | Security sheet pattern; auth screens remain adaptation-only. |
| 5 | `phase5-phone-profile-payout-sheet.png` | Payout/account sheet pattern; no payment authority change. |
| 5 | `phase5-phone-profile-privacy-sheet.png` | Privacy/data sheet pattern for restricted/gate copy density. |
| 6 | `phase6-phone-messages-received-source-copy-conflict.png` | Messages received-mode visual pattern; source tab still says `Responses`. |
| 6 | `phase6-phone-messages-sent-source-copy-conflict.png` | Messages sent-mode visual pattern; source tab still says `Requests`. |
| 6 | `phase6-phone-dashboard-inbox-received-sent.png` | Dashboard inbox source for `Received` and `Sent` copy. |
| 7 | `phase7-phone-tenders-list.png` | Tender card list density, search, and status card pattern. |
| 7 | `phase7-phone-dashboard-work-active.png` | Work dashboard active bucket pattern. |
| 7 | `phase7-phone-dashboard-work-done.png` | Work dashboard done bucket pattern. |
| 7 | `phase7-phone-dashboard-work-cancelled.png` | Work dashboard cancelled bucket pattern. |
| 8 | `phase8-phone-bookings-browse.png` | Booking discovery/list card pattern. |
| 8 | `phase8-phone-dashboard-bookings.png` | Dashboard bookings summary pattern. |
| 8 | `phase8-phone-dashboard-wallet.png` | Dashboard wallet visual pattern; no active withdrawal authority. |

## Supplemental Web References

| Phase | Screenshot | Evidence use |
|---|---|---|
| 5 | `supplemental-web-profile-settings.png` | Supplemental settings density for security, payout, and privacy rows. |
| 6 | `supplemental-web-messages-received.png` | Supplemental `Received` message mode and work-context layout. |
| 6 | `supplemental-web-messages-sent.png` | Supplemental `Sent` message mode and work-context layout. |
| 7 | `supplemental-web-dashboard-work-active.png` | Supplemental work status taxonomy for active states. |
| 7 | `supplemental-web-dashboard-work-done.png` | Supplemental work status taxonomy for done states. |
| 7 | `supplemental-web-dashboard-work-cancelled.png` | Supplemental work status taxonomy for cancelled states. |
| 8 | `supplemental-web-dashboard-bookings.png` | Supplemental bookings dashboard structure. |
| 8 | `supplemental-web-dashboard-wallet.png` | Supplemental wallet dashboard structure; visual reference only. |

## Missing Exact Phone Evidence

- Phase 5 exact login, signup, forgot-password, reset-password, account-restricted, maintenance, and update-required artboards are still missing.
- Phase 6 exact attachment tile, notification modal, direct-offer-detail, and chat-composer edge-state artboards are still missing.
- Phase 7 exact proposal-detail and direct-offer-detail phone artboards are still missing.
- Phase 8 exact payment method, checkout, return, trusted callback, WebView, and standalone wallet-flow artboards are still missing.

Missing exact evidence means adaptation-only styling. Do not claim pixel parity for those surfaces unless Open Design or user-provided screenshots are added later.

## Implementation Notes

- The Open Design bottom sheets use a blurred backdrop. The Flutter implementation must keep the no-glass/no-backdrop rule from the corrected plan; use approved dimming/elevation tokens instead of importing blur behavior.
- The phone Messages artifact still renders `Responses` and `Requests`, but the corrected plan keeps `Received` and `Sent` because the dashboard inbox, web artifact, and design-system rule all support that direction.
- These screenshots are reference evidence only. Runtime Flutter screenshots remain required before any visual-completion claim.
