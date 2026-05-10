# PLAN CRITIQUE: Open Design Amber Dusk Redesign
> Auditor: @PlanCritic  
> Date: 2026-05-10  
> Corrected phone plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
> Corrected web plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`

---

## Gate Status Table

| Gate | Status | Notes |
|---|---|---|
| Data / Contracts Gate | PASS | Redesign only. No schema/model contract change planned. |
| Security / RLS Gate | PASS | No RLS changes. Views remain blocked from direct Supabase access. |
| Backend / Supabase Gate | PASS | Backend out of scope. Any backend discovery requires separate `supabase-migration` plan. |
| UI / Integration Gate | PASS AFTER CORRECTION | Added dedicated MCP evidence and theme-control gates to every phase. |
| Release / QA Gate | PASS AFTER CORRECTION | Added per-phase gate checks, phone/web width matrices, and rollback conditions. |

---

## Critical Gaps Found

1. Original plans did not force Open Design MCP access in every phase.
2. Original plans did not prevent implementation from cached memory or old UI docs.
3. Original plans did not define screenshot authority.
4. Original plans did not force design-system control from `lib/core/theme/`.
5. Original web plan did not separate web responsive design files under the theme design folder.
6. Original web plan did not require phone regression after every web phase.
7. Original phase gates were broad enough to miss sub-UI states.

---

## Corrected Plan Reference

- Phone corrected plan: `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- Web corrected plan: `.TODO/PLAN_OpenDesign_AmberDusk_Web_Mohammed_2026-05-10.md`

---

## Risk Register Summary

| Risk | Prevention |
|---|---|
| MCP ignored | Every phase starts with MCP evidence refresh. |
| Screenshot details invented | Screenshot decisions must cite screenshot path and visible area. |
| Design constants scattered | All reusable design values live under `lib/core/theme/designs/amber_dusk/`. |
| Web breakpoints scattered | Web constants live under `lib/core/theme/designs/amber_dusk/web/`. |
| Phone/web drift | Mohammed starts from completed phone branch and verifies phone regression. |
| Payment return regression | Payment phases include return URL smoke checks. |
| Dashboard/profile partial completion | Phases list all sub-UI targets and states. |

---

## Change Report Summary

- Added PlanCritic A-I structure to both plan files.
- Added global MCP evidence rules.
- Added global theme folder rules.
- Added web-specific theme folder rules.
- Added per-phase MCP refresh sub-phases.
- Added screenshot evidence policy.
- Added gate checks to every phase.
- Added corrected risk registers, pre-mortems, invariants, and residual risks.

