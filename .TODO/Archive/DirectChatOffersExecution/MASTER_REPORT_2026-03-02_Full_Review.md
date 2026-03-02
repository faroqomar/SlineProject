# Master Report: Full_Review

**Date:** 2026-03-02  
**Scope:** Full_Review (entire codebase: lib/, direct_offers, dashboard, wallet, migrations)  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard  
**Final Decision:** BLOCKED (fix BLOCKERs first, then APPROVED)

---

## A) Executive Summary

### What Was Reviewed
Full codebase review: `lib/` (all features), `Sline_everything/` docs, Supabase migrations and functions. Focus areas: direct_offers, dashboard, wallet, booking, auth, chat, observability, documentation integrity, performance, security.

### Overall Risk Level: **MEDIUM–HIGH**
- Two BLOCKERs (MVVM violation in View; analyzer issues in web utils) must be fixed before merge.
- Documentation and observability gaps are non-blocking but should be addressed.

### Final Decision: **BLOCKED**
CodeGuard reported BLOCKERs. Pipeline proceeds to produce this report and a fix plan; execution of Step 1 (fix BLOCKERs) unblocks the gate. After Step 1, re-run `flutter analyze` and `flutter test` and re-evaluate for APPROVED.

---

## B) Consolidated Findings (Deduplicated)

### Security
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| RLS and ledger/auth usage | PASS | CodeGuard | direct_offers RLS, process_payment_event_ledger | None. |
| No service_role in client | PASS | CodeGuard | supabase_config.dart | None. |
| PII in auth log | MED | Observability | auth_view_model.dart – full_name in log | Use event only; do not log full_name. |

### Data Integrity / Architecture
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| **MVVM: View uses Supabase** | **BLOCKER** | Architect, CodeGuard | `lib/features/direct_offers/view/direct_offer_details_screen.dart` line 40 | Obtain `currentUserId` from `context.read<AuthViewModel>().currentUserId`; remove `Supabase.instance.client` from View. |
| Single source of truth, no N+1 | PASS | Architect | dashboard_repository, wallet, ledger | None. |
| direct_offers missing from STRUCTURE | LOW | Architect, SlineDocs | Sline_everything/STRUCTURE.md | Add direct_offers to feature list. |

### Performance
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| Dashboard batch profile fetch, Future.wait | PASS | CodeGuard | dashboard_view_model.dart | None. |
| Format drift | MED | CodeGuard | 47 files | Run `dart format .` and commit. |
| Dependency freshness | MED | CodeGuard | supabase_flutter 1.x, js discontinued | Plan supabase_flutter 2.x and package:web migration. |

### Observability
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| No event taxonomy / correlation_id | MED | Observability | auth, wallet, booking, direct_offers, dashboard | Adopt event names and correlation_id per OBSERVABILITY_REPORT. |
| SignedImage catch block no log | MED | Observability | lib/core/widgets/signed_image.dart | Add AppLogger in catch. |
| Wallet balance/activity fetch not logged | LOW | Observability | wallet_service.dart | Add success/failure events. |

### Docs / Reference Integrity
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| SUPABASE_SETUP Last Updated, migrations 20260303–20260307 | HIGH | SlineDocs | SUPABASE_SETUP.md | Update date and changelog. |
| STRUCTURE: direct_offers + edge functions list | HIGH | SlineDocs | STRUCTURE.md | Add direct_offers; add qicard_payment_*_direct_offer. |
| DEVELOPER_GUIDE: DM/favorites, message_type_enum, trigger names | HIGH | SlineDocs | DEVELOPER_GUIDE.md | Align with SUPABASE_SETUP v2.1; add system; fix trigger names. |
| MVP_ROADMAP: Direct Chat Offers row | LOW | SlineDocs | MVP_ROADMAP.md | Add row. |
| Inventory Feature.md (Planned) | LOW | SlineDocs | DEVELOPER_GUIDE quick links | Keep as planned or add placeholder. |

### Compatibility / Analyzer
| Finding | Severity | Owner | File/Ref | Fix |
|---------|----------|-------|----------|-----|
| **dart:html in web_url_utils_web** | **BLOCKER** | CodeGuard | `lib/core/utils/web_url_utils_web.dart` | Replace `dart:html` with `package:web` / dart:js_interop or use conditional/implementation that passes analyze. |

---

## C) Fix Plan (Ordered)

### Step 1: Resolve BLOCKERs (must complete first)
**Owner:** Implementer (Architect-style changes)

1. **MVVM fix – direct_offer_details_screen.dart**
   - Remove `Supabase.instance.client.auth.currentUser?.id` from the View.
   - Use `currentUserId: context.read<AuthViewModel>().currentUserId` when creating `DirectOfferDetailsViewModel`.
   - Ensure `AuthViewModel` is in the widget tree (it is provided in main.dart).
   - **Verification:** `flutter analyze`; grep for `Supabase.instance` in `lib/features/direct_offers/view/` → no matches.

2. **Analyzer fix – web_url_utils_web.dart**
   - Remove `import 'dart:html'` and usage of `html.window`.
   - Use `package:web` (add if needed) or `dart:ui_web` / `dart:html` replacement that satisfies `avoid_web_libraries_in_flutter` and deprecation. If adding `package:web` is a large change, use a no-op or stub implementation for web that does not use `dart:html` (e.g. conditional import with empty implementation that still clears URL via a supported API).
   - **Verification:** `flutter analyze` → 0 issues.

**Checklist:** Run `flutter analyze` and `flutter test` after Step 1. If both pass, pipeline gate moves to APPROVED for code.

### Step 2: Format and minor hygiene
**Owner:** Implementer
- Run `dart format .` and commit (fixes 47-file format drift).
- **Verification:** `dart format --set-exit-if-changed .` passes.

### Step 3: Documentation updates
**Owner:** @SlineDocs (or implementer per DOCS_REPORT)
- Update SUPABASE_SETUP.md: Last Updated, changelog for 20260303–20260307.
- Update STRUCTURE.md: add direct_offers to feature list; add qicard_payment_create_direct_offer, qicard_payment_recovery_direct_offer to functions list.
- Update DEVELOPER_GUIDE.md: DM/favorites v2.1, message_type_enum (add system), trigger names (trg_conversations_before_insert_guard, trg_messages_before_insert_validate), direct_offers inventory (view/viewmodels).
- Update MVP_ROADMAP.md: add Direct Chat Offers row.
- **Verification:** Doc references match code and migrations.

### Step 4: Observability (recommended)
**Owner:** @Observability (or implementer per OBSERVABILITY_REPORT)
- Add logging in SignedImage catch block (lib/core/widgets/signed_image.dart).
- Remove PII from auth success log (auth_view_model – do not log full_name).
- Introduce correlation_id and event taxonomy for direct_offers and wallet flows as per OBSERVABILITY_REPORT.
- **Verification:** No PII in logs; critical flows have structured events.

### Step 5: CodeGuard re-run (after Step 1)
**Owner:** @CodeGuard
- Re-run review on changed files after BLOCKERs and format.
- Confirm APPROVED and no BLOCKERs.

---

## D) Regression Checklist

- **Auth:** Login, register, logout, session expiry.
- **Dashboard:** Role switch, work items load, direct offer tiles, open offer details.
- **Direct offer:** Open from dashboard; open from deep link; Pay with card (WebView/browser); payment return and recovery.
- **Wallet:** Balance and activity load; ledger submit.
- **Booking:** List, payment draft, return URL handling.
- **Quick test:** `flutter analyze` && `flutter test` after any change.

---

## E) Rollback Notes

- **direct_offer_details_screen:** Revert to passing `Supabase.instance.client.auth.currentUser?.id` only if AuthViewModel is not in tree (then fix provider order instead).
- **web_url_utils_web:** Revert to dart:html only temporarily; track analyzer/CI and re-apply package:web or stub.
- **Docs:** Revert doc edits if they conflict with actual schema; sync with migrations again.
- **Format:** Revert formatting commit if it causes noisy diff; re-apply with scope limited to touched files if needed.
