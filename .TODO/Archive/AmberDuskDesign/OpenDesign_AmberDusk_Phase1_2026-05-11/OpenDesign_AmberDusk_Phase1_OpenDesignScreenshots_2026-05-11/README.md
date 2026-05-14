# OpenDesign Amber Dusk Phase 1 Screenshot Pack

Date: 2026-05-11
Status: PROVISIONAL REFERENCE ONLY

This folder contains the Phase 1 Open Design reference screenshot pack for
360, 390, 402, and 430 logical-pixel widths.

Step 5 gap scan found that the route-specific screenshots are not reliable
runtime visual QA evidence:

- The 360px route files have identical hashes.
- The 390px route files have identical hashes.
- The 402px route files have identical hashes.
- At 430px, `opendesign-430-messages.png` and
  `opendesign-430-profile.png` have identical hashes.

Use these images only as provisional Open Design width references. Do not treat
them as proof that each route state was separately captured or that the Flutter
runtime matched the design. Step 6 must recapture or verify runtime visual
evidence before publishing a final test checklist.
