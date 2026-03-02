# Docs Sync — Direct Chat Offers & SlineDocs Alignment

**Date:** 2026-03-02  
**Scope:** Ensure all recent Direct Chat Offers (accept-then-pay, QiCard, dashboard, recovery, webview, ledger) and related fixes are documented per `.cursor/Agents/Sline_Docs.md`.

---

## 1. Docs Updated

| Document | Changes |
|----------|--------|
| `Sline_everything/Sline_Log.md` | Added **Version 2.17.0 — Direct Chat Offers (Accept-then-Pay, QiCard, Dashboard)** with implemented items (flow, app paths, chat/dashboard/payment/web, DB migrations, observability), impact, verification, technical notes. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Updated Direct Chat Offers (v2.17) summary and §2.6: **Accept first, Pay from Dashboard** flow (4 steps); `acceptOfferWithoutPayment`, `payNow`, `recoverPaymentAfterCallback`; `DirectOfferDetailsScreen`; dashboard payEscrow; web (browser/url_launcher) vs mobile (WebView); guard/ledger and migration 20260307. Added File Inventory row for `lib/features/direct_offers/`. Updated standalone "Direct Chat Offers" paragraph to match. |
| `Sline_everything/MVP_ROADMAP.md` | Added **Direct Chat Offers** row under Collaboration and Communication: ✅ Completed; accept in chat → Pending Payment in dashboard → Pay from dashboard (QiCard); `lib/features/direct_offers/`; edge functions. |
| `Sline_everything/SUPABASE_SETUP.md` | Bumped Last Updated to 2026-03-02, Version to 2.17. §5.14 `direct_offers`: lifecycle text updated to **sent → accepted (unpaid) → client pays from Dashboard → active (held) → delivered → completed**. |

---

## 2. References Validated

- **Paths:** `lib/features/direct_offers/` (service, view, viewmodel), `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/features/chat/view/widgets/offer_message_bubble.dart`, `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart`, `lib/features/booking/view/payment_webview_screen.dart`, `lib/core/utils/web_url_utils_web.dart` — all exist.
- **DB:** `direct_offers`, `fn_direct_offer_guard`, `process_payment_event_ledger`, `payment_event_type_enum`, migrations 20260303–20260307 — documented in SUPABASE_SETUP and DEVELOPER_GUIDE.
- **Edge functions:** `qicard_payment_create_direct_offer`, `qicard_payment_recovery_direct_offer` — referenced in STRUCTURE.md and Sline_Log.

---

## 3. Reason for Each Update

- **Sline_Log:** New feature release (v2.17.0) required a full version entry per Sline_Docs timeline discipline.
- **DEVELOPER_GUIDE:** Flow had changed from "Accept & Pay" in chat to "Accept in chat, Pay from Dashboard"; docs now describe the actual implementation and key files.
- **MVP_ROADMAP:** Direct Chat Offers was implemented but not listed; added as Completed under Collaboration and Communication.
- **SUPABASE_SETUP:** Version and last-updated metadata refreshed; direct_offers lifecycle wording aligned with accept-then-pay behavior.

---

## 4. No Changes Made To

- `STRUCTURE.md` — already listed direct_offers table, RLS, triggers, ledger RPC, migrations 20260303–20260307, and `lib/features/direct_offers/`; edge functions already present.
- `ARCHITECTURE_ANALYSIS.md`, `CODE_REVIEW.md` — no structural or pattern changes required for this sync.
- `Sline_everything/DEVELOPER_GUIDE/` — no new `Direct_Offers_Feature.md` added; Direct Chat Offers remain covered in main DEVELOPER_GUIDE §2.6 and the "Direct Chat Offers" block.

---

**Completed per:** `.cursor/Agents/Sline_Docs.md` (context capture, single source of truth, versioning, reference integrity).
