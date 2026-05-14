# Visual QA: OpenDesign Amber Dusk Phases 2-4 Runtime Comparison

Date: 2026-05-12 01:30:27 +0300  
Device: iPhone 16e Simulator, iOS 26.2  
Runtime screenshot size: 1170 x 2532 PNG, equivalent to the simulator's physical capture scale.  
Open Design source: `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, `Sline V2 Amber Dusk.html`  
Reference screenshot pack: `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/`  
Inspector: Computer Use against the already-open Simulator, with Open Design MCP re-check.

## Runtime Screenshots Captured

- `runtime-home-all.png`
- `runtime-home-bookings.png`
- `runtime-home-tasks.png`
- `runtime-create-type-tender.png`
- `runtime-create-type-booking.png`
- `runtime-create-tender-details.png`
- `runtime-create-tender-review.png`
- `runtime-create-booking-details.png`
- `runtime-create-booking-review.png`
- `runtime-dashboard-overview.png`
- `runtime-dashboard-bookings.png`
- `runtime-dashboard-work-active.png`
- `runtime-dashboard-work-done.png`
- `runtime-dashboard-work-cancelled.png`
- `runtime-dashboard-wallet.png`
- `runtime-dashboard-inbox-received.png`
- `runtime-dashboard-inbox-sent.png`
- `runtime-messages-nav-active.png`
- `runtime-profile-nav-active.png`

## Comparison Summary

| Area | Runtime Match | Notes |
|---|---|---|
| Home shell and bottom nav | Partial pass | Four-item nav, active amber capsule, dark shell, Home-owned create FAB, search row, and All/Bookings/Tasks chips match the design direction. Runtime is less dense than the 430 x 930 Open Design references and uses live data/counts, so it is not pixel-identical. |
| Home mixed feed | Partial pass | Tender/task and booking card hierarchy is present. Booking cards use hero rust material; task cards use quieter dark panels. Runtime cards are larger and show fewer items per viewport than the reference. |
| Create type step | Partial | Tender/Booking selection and progress steps exist. Runtime is a full-height create surface titled `Create a post`; Open Design references show a bottom-sheet/modal treatment with stronger background context. |
| Create details steps | Partial | Required tender and booking fields are present. Runtime shows blank placeholders and a category grid high in the viewport; Open Design references show compact prefilled form fields in a lower sheet. |
| Create review steps | Partial | Tender and booking previews exist and use correct material families. Runtime review uses fallback/default text when fields are blank, so the screenshot does not visually match populated Open Design previews. |
| Dashboard overview | Partial | Dashboard tabs, large title, hero wallet card, counters, next actions, and active Dashboard nav are present. Runtime typography/cards are larger; overview lacks the Open Design overview's visible wallet action buttons. |
| Dashboard bookings | Partial | Booking list cards, status treatment, and active tab styling are present. Runtime live state shows `Past` items first; Open Design reference emphasizes upcoming booking cards with action buttons before past history. |
| Dashboard work | Partial pass | Active/Done/Cancelled buckets, progress bars, status coloring, and empty cancelled state are present. Runtime cards are much taller than reference lifecycle cards, reducing viewport density. |
| Dashboard wallet | Partial | Wallet hero, balance chips, and wallet flow sections are present. Runtime uses a larger wallet dashboard composition than the Open Design wallet tab reference. |
| Dashboard inbox | Partial | Received/Sent segmented control is present. Runtime has empty Received and intentional Sent placeholder because `DashboardViewModel` does not expose sent offers; Open Design reference shows received proposal cards. |
| Messages nav active | Nav pass, content mismatch | Bottom nav active state matches the shell direction. Message list content is still legacy/teal and does not match the Open Design Messages screen. This may be acceptable only if Phase 2 treats Messages as nav-shell-only. |
| Profile nav active | Nav pass, content mismatch | Bottom nav active state matches the shell direction. Profile content is still existing app UI and does not match the Open Design Profile screen. This aligns with the corrected plan only if Profile content remains out of scope. |

## Confirmed Matches

- Bottom navigation has exactly four destinations: Home, Dashboard, Messages, Profile.
- Home owns the create FAB; Dashboard/Messages/Profile do not show it.
- Home discovery modes are All, Bookings, and Tasks.
- Dashboard tabs are Overview, Bookings, Work, Wallet, Inbox.
- Work tab buckets are Active, Done, and Cancelled.
- Runtime captures prove the Flutter UI renders without blank screens on the inspected states.

## Visual Gaps To Decide Before Closure

- Create flow presentation is not the same pattern as the Open Design bottom-sheet references.
- Runtime density is consistently larger than the Open Design screenshots, especially Dashboard and Work cards.
- Dashboard overview does not show the reference wallet actions in the same way as Open Design.
- Dashboard inbox cannot prove proposal-card parity without received proposal fixture data.
- Messages and Profile content do not match their Open Design screens; decide whether they are shell-only for Phase 2 or must become redesign targets later.
- Search, Categories, Saved, Favorites, loading, empty, error, and role-specific dashboard variants still have no exact Open Design reference screenshots in the current pack.

## No Code Changes

This pass captured and compared runtime screenshots only. No app code was changed.
