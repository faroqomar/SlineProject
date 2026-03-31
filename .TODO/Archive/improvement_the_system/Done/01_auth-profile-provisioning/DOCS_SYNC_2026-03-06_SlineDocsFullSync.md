# Docs Sync Note: SlineDocs Full Sync

**Date:** 2026-03-06  
**Workflow:** `.agents/workflows/slinedocs.md`  
**Scope:** Align all docs with current code and Auth Profile Provisioning (plan, execution, Master Report fixes).

---

## 1. Doc Files Updated

| Document | Changes |
|----------|--------|
| `Sline_everything/Sline_Log.md` | Last Updated → 2026-03-06; added post–Master Report fixes (logging, clearError on logout); added References block (plan, execution log, CodeGuard review, Master report, checklist, this DOCS_SYNC). |
| `Sline_everything/MVP_ROADMAP.md` | Last Updated → 2026-03-06; Identity row "Session-aware logout and auth listener" now references `AuthSessionViewModel` + `AuthFormViewModel` (was `AuthViewModel`). |
| `Sline_everything/STRUCTURE.md` | Last Updated → 2026-03-06; `lib/core/config/` now mentions `auth_config.dart` and `lib/core/constants/auth_messages.dart`. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Last Updated → 2026-03-06. (Auth subsection "4.3 Profile provisioning retry" was already added in implementation.) |
| `Sline_everything/SUPABASE_SETUP.md` | Last Updated → 2026-03-06; changelog note for auth migrations. |
| `Sline_everything/DEVELOPER_GUIDE/Auth Feature.md` | Aligned with main DEVELOPER_GUIDE: all `AuthViewModel` → `AuthSessionViewModel` / `AuthFormViewModel`; file inventory updated; flows updated (retry, trigger, logout/clearError); added note that main DEVELOPER_GUIDE.md is canonical. |
| `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md` | `AuthViewModel.currentUserId` → `AuthSessionViewModel.currentUserId`. |
| `Sline_everything/AppDigram/All_Diagrams/01_auth-profile-provisioning.md` | Sources updated to `auth_session_view_model.dart`, `auth_form_view_model.dart`, `auth_repository.dart`, `view/login_screen.dart`; service layer list updated; last_verified → 2026-03-06. |
| `Sline_everything/CODE_REVIEW.md` | Section 6 and FILES MODIFIED: Auth references updated to AuthSessionViewModel + AuthFormViewModel; Profile screen note uses AuthSessionViewModel. |

---

## 2. Summary of Changes

- **Reference integrity:** Replaced every outdated `AuthViewModel` reference with the current split (`AuthSessionViewModel` for session/logout/profile, `AuthFormViewModel` for form state). Verified that `lib/features/auth/view/login_screen.dart`, `auth_session_view_model.dart`, `auth_form_view_model.dart`, and `auth_repository.dart` exist.
- **Single source of truth:** Auth Feature Reference in main DEVELOPER_GUIDE.md remains canonical; `DEVELOPER_GUIDE/Auth Feature.md` is now a consistent mirror with retry and trigger behavior.
- **Versioning:** All "Last Updated" dates set to 2026-03-06 where applicable. Sline_Log 2026-03-06 entry now includes verification links and post-report fixes.

---

## 3. References Validated

- `lib/core/config/auth_config.dart` — exists  
- `lib/core/constants/auth_messages.dart` — exists  
- `lib/features/auth/data/auth_repository.dart` — exists  
- `lib/features/auth/viewmodels/auth_session_view_model.dart` — exists  
- `lib/features/auth/viewmodels/auth_form_view_model.dart` — exists  
- `lib/features/auth/view/login_screen.dart` — exists  
- `lib/features/direct_offers/view/direct_offer_details_screen.dart` — uses `AuthSessionViewModel` (confirmed)  
- DB: `vw_orphaned_auth_users`, `sweep_orphaned_auth_users()`, pg_cron job — documented in SUPABASE_SETUP.md  

---

## 4. Why Each Update Was Needed

- **Sline_Log / MVP / STRUCTURE / DEVELOPER_GUIDE / SUPABASE:** Keep timeline and roadmap accurate and reflect Auth Profile Provisioning and Master Report fixes; ensure STRUCTURE lists auth config and constants.
- **Auth Feature.md:** Had stale AuthViewModel and old file names; now matches implementation and main guide.
- **Direct_Offers_Feature.md:** Code uses `AuthSessionViewModel`; doc referenced `AuthViewModel`.
- **01_auth-profile-provisioning.md:** Diagram sources referred to old paths and single AuthViewModel; updated to current viewmodels and repository.
- **CODE_REVIEW.md:** Historical "FIXED" items referred to AuthViewModel; added current pattern (AuthSessionViewModel + AuthFormViewModel) so readers know the current state.

---

## 5. Cross-Links

- Plan: `.TODO/PLAN_AuthProfileProvisioning_CRITIC_2026-03-06.md`  
- Execution log: `.TODO/EXECUTION_LOG_AuthProfileProvisioning_CRITIC.md`  
- CodeGuard: `.TODO/CODEGUARD_REVIEW_2026-03-06_AuthProfileProvisioning.md`  
- Master report: `.TODO/MASTER_REPORT_2026-03-06_AuthProfileProvisioning.md`  
- Checklist: `.TODO/CHECKLIST_AuthProfileProvisioning_Verification.md`  

Pipeline: full scan → reference validation → doc deltas applied → this sync note produced.

**Note:** Older Sline_Log and CODE_REVIEW entries that mention `auth_view_model.dart` refer to the pre–2026-03-05 state. That file was split into `auth_session_view_model.dart` and `auth_form_view_model.dart`; all current references in docs now point to the split ViewModels.
