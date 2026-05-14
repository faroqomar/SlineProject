# HANDOFF: OpenDesign Amber Dusk Phases 9-12 To Web

Date: 2026-05-13
Status: PHONE CODE COMPLETE; WEB ADAPTATION READY WITH VISUAL-QA CAVEATS
Audience: Mohammed and web redesign implementation agents

## Summary

Phone Phases 9-12 completed scoped Amber Dusk treatment for the profile ecosystem, portfolio/services surfaces, secondary screens, notification/helper states, final readiness checks, and handoff/docs closure. Step 5 gap scanning then tightened the profile/public-profile composition, portfolio proof tiles, notification/destructive-action contrast, sheet geometry, and interaction semantics against fresh Open Design MCP evidence.

Amber Dusk remains scoped token/widget consumption. No global `MaterialApp` theme flip occurred, and no backend/Supabase objects changed.

## Source Artifacts

- Plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
- Plan critique: `.TODO/PLAN_CRITIQUE_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness.md`
- Session log: `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases9_10_11_12_PhoneProfileSecondaryReadiness_2026-05-13.md`
- Master report: `.TODO/MASTER_REPORT_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md`
- Docs sync: `.TODO/DOCS_SYNC_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12.md`
- Web dependency plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`

## Open Design Evidence

Open Design MCP project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` was rechecked before implementation.

Files confirmed:

- `Sline V2 Amber Dusk.html`
- `amber-dusk-design-system.html`
- `sline-v2-amber-dusk-web.html`

Strong phone/web evidence exists for:

- Profile hero
- Profile photo
- Verified pill
- Profile metrics
- Availability card
- Service card/package rows
- Portfolio strip
- Settings groups and edit rows
- Sheet treatment and solid scrim pattern

Weak or missing exact evidence remains for:

- Favorites
- Saved tasks
- Categories
- Notification modal/list state variants
- Several loading, empty, error, and helper states

These weak-evidence surfaces were implemented as adaptation-only on phone and must remain adaptation-only on web unless Mohammed receives exact screenshots or a new Open Design artifact.

## Phone Implementation Truth

Profile ecosystem:

- Public profile now uses one Amber Dusk hero/header module with hero actions, proof metrics below the hero, compact portfolio proof tiles, reviews, tabs, and sticky action treatment.
- Edit profile, settings, avatar, and preview modal consume Amber Dusk tokens and preserve existing `ProfileViewModel`, logout, theme toggle, avatar upload, favorite, chat, report, and navigation contracts.

Portfolio and services:

- Profile and public-profile portfolio strips use compact proof tiles rather than image masonry where the Open Design evidence shows proof cards.
- Portfolio screen, add/edit/details sheets, portfolio tile, image placeholder, manage portfolio, my services, and service card consume Amber Dusk surfaces/status/media tokens.
- Portfolio CRUD and storage path/signed image behavior remain behind existing ViewModels/services/widgets.

Secondary surfaces:

- Categories, search, search result profile card, favorites, favorite card, saved tasks, and saved task tile received adaptation-only spacing, overflow, tap target, and token alignment.
- Search/category/saved/favorite navigation and privacy behavior remain unchanged.

Notifications and helpers:

- Notification modal/list/badge, loading overlay, status presenter, and unified CTA resolver now use Amber Dusk semantic colors/surfaces, including readable muted-danger fills for badge/destructive states.
- Notification stream authority and mark-read behavior remain with `NotificationViewModel`/service.

## Web Mapping

Map phone modules to web equivalents as follows:

- Profile hero -> web profile identity header with avatar, verified/trust proof, role/location, and concise bio.
- Profile metrics -> horizontal stat/proof row; keep semantic status colors, not generic teal/gold.
- Services -> package/service rows with title, description, price, delivery, and status pill.
- Portfolio -> proof gallery using signed/public media rules and solid media placeholders.
- Reviews/trust -> compact review cards with star treatment and muted metadata.
- Settings/edit -> grouped account rows and modal/sheet form hierarchy; preserve destructive action grouping.
- Notifications -> solid modal/panel list with unread tint, skeleton loading, empty state, error/retry, and `9+` badge behavior.
- Secondary screens -> use existing Amber Dusk card/list/state primitives; do not claim pixel parity without exact web evidence.

## Verification

Phone verification passed:

- `dart format --set-exit-if-changed .`
- `flutter analyze --no-fatal-infos`
- `flutter test test/core/theme/ test/core/widgets/ test/unit/core/status_presenter_test.dart test/unit/core/loading_utils_test.dart test/unit/core/unified_cta_resolver_test.dart`
- `flutter test test/unit/profile test/features/profile/services test/unit/portfolio test/unit/services`
- `flutter test test/features/favorites test/unit/categories test/unit/search test/unit/saved`
- `flutter test test/unit/notifications test/widget/notifications`
- `flutter test`
- `git diff --check`
- Direct Supabase guard scan over changed view/helper areas
- Raw visual constant scan over changed Dart files
- No-glass scan over changed Dart files
- Step 5 post-fix format/analyzer/focused/full test pass and static guard scans
- Step 6 Orchestrator review focused tests and full test pass

Final Step 6 `flutter test` result: passed with `1545` passing and `30` skipped. The skipped set includes Supabase/storage-gated tests plus the existing hardcoded `test/integration_test/favorites_cross_feature_flow_test.dart` skip.

## Web Blockers

- No Phase 9/10 user-provided screenshots were available during phone implementation.
- Runtime Flutter visual QA at 360, 390, 402, and 430 logical widths is still open.
- Secondary screens must stay adaptation-only unless exact Open Design or user screenshots are supplied.
- Font asset licensing/source evidence remains unresolved; keep using existing project font setup until a separate asset plan provides licenses.
- The current phone app keeps four visible bottom navigation destinations: Home, Dashboard, Messages, Profile. Do not implement a five-item web/phone shell from older design memory without a separate approved nav plan.
