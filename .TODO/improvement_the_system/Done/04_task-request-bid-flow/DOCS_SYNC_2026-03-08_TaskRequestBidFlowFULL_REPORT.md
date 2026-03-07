# DOCS_SYNC: Task Request Bid Flow — FULL_REPORT Fixes

**Date:** 2026-03-08  
**Trigger:** SlineDocs workflow — ensure docs reflect Task Request Bid Flow fixes from FULL_REPORT Production Checklist

---

## 1. Doc Files Updated

| File | Changes |
|------|---------|
| `Sline_everything/SUPABASE_SETUP.md` | Header: Last Updated 2026-03-08, Version 2.20.1; §9.6 accept_task_request: Added "Rejects all other pending bids" to Side Effects; added Migration reference; §17 Changelog v2.20.1 |
| `Sline_everything/Sline_Log.md` | New entry: Task Request Bid Flow — FULL_REPORT Fixes (v2.20.1); Last Updated 2026-03-08 |
| `Sline_everything/DEVELOPER_GUIDE.md` | Version 2.20.1; DashboardViewModel.awardOffer with expectedPriceCents; Migration table: 20260308000000 |

---

## 2. Summary of Changes

### Code Changes (from prior session)
- **DashboardViewModel.awardOffer()** — Passes `expectedPriceCents: (offer.price * 100).round()` for Inbox tab awards (optimistic price lock)
- **Migration 20260308000000** — `accept_task_request` now atomically rejects all other pending bids on the same task (Single Winner Rule)

### Doc Updates
- **SUPABASE_SETUP**: accept_task_request Side Effects now explicitly list "Rejects all other pending bids"; Migration reference added; Changelog v2.20.1
- **Sline_Log**: New v2.20.1 entry with file paths, impact, references
- **DEVELOPER_GUIDE**: DashboardViewModel in Flutter Implementation; migration table; version bump

---

## 3. References Validated

- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — exists, awardOffer passes expectedPriceCents
- `supabase/migrations/20260308000000_accept_task_request_reject_remaining_bids.sql` — exists
- `.TODO/.../04_task-request-bid-flow/FULL_REPORT.md` — exists, checklist marked complete

---

## 4. Why Each Update Was Needed

| Doc | Reason |
|-----|--------|
| SUPABASE_SETUP | accept_task_request behavior changed; migration must be documented |
| Sline_Log | Every meaningful change must be logged with specifics |
| DEVELOPER_GUIDE | Inbox award flow now has same price validation as Requests list; developers need to know both entry points |
