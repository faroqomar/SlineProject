# SLINE UI REDESIGN — PHASE INDEX
> Sequential execution. One phase at a time. Each phase is self-contained.
> Updated: 2026-04-06

---

## HOW THIS WORKS

```
For each phase:

  1. READ the PHASE_X_EXECUTION.md file
  2. EXPLORE — run listed skills to analyze current state
  3. DESIGN — make design decisions (code tokens + Figma components)
  4. CODE — implement changes in Flutter
  5. VERIFY — flutter analyze + visual check + test
  6. FIGMA SYNC — push design to Figma (tokens, components, screens)
  7. MARK COMPLETE — check off items in the execution file
  8. CREATE next phase file — each phase plans the next when complete
```

**Key principle:** Each phase gives you freedom to run ANY skill (`audit`, `polish`, `bolder`, `quieter`, etc.) on the work done in that phase. The execution files list the PRIMARY skills, but you can explore freely.

---

## PHASE MAP

| Phase | Name | Files | Status | Execution File | Depends On |
|-------|------|-------|--------|----------------|------------|
| **0** | Design System Foundation | 6 | NOT STARTED | `PHASE_0_EXECUTION.md` | None |
| **1** | Core Widget Redesign | 14 | BLOCKED | Created when Phase 0 done | Phase 0 |
| **2** | App Shell & Navigation | 3 | BLOCKED | Created when Phase 1 done | Phase 1 |
| **3** | Authentication Screens | 7 | BLOCKED | Created when Phase 2 done | Phase 1 |
| **4** | Cards (All Types) | 8 | BLOCKED | Created when Phase 2 done | Phase 1 |
| **5** | Home & Discovery | 2 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **6** | Chat & Messaging | 7 | BLOCKED | Created when Phase 1 done | Phase 1, 4 |
| **7** | Dashboard | 10 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **8** | Booking & Payments | 10 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **9** | Profile | 12 | BLOCKED | Created when Phase 1 done | Phase 1 |
| **10** | Portfolio | 6 | BLOCKED | Created when Phase 9 done | Phase 9 |
| **11** | Proposals & Direct Offers | 6 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **12** | Wallet | 6 | BLOCKED | Created when Phase 1 done | Phase 1 |
| **13** | Work Management | 10 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **14** | Notifications | 3 | BLOCKED | Created when Phase 1 done | Phase 1 |
| **15** | Secondary Screens | 10 | BLOCKED | Created when Phase 4 done | Phase 4 |
| **16** | Cross-Cutting Quality | ALL | BLOCKED | Created last | All |

**Total: 134 files across 17 phases**

---

## DEPENDENCY GRAPH

```
Phase 0: Design System Foundation
    │
    ▼
Phase 1: Core Widgets ◄── Everything depends on this
    │
    ├──► Phase 2: Navigation Shell
    │        │
    │        ├──► Phase 3: Auth Screens
    │        └──► Phase 4: Cards ◄── Most features depend on this
    │                 │
    │                 ├──► Phase 5: Home & Discovery
    │                 ├──► Phase 7: Dashboard
    │                 ├──► Phase 8: Booking & Payments
    │                 ├──► Phase 11: Proposals
    │                 ├──► Phase 13: Work Management
    │                 └──► Phase 15: Secondary Screens
    │
    ├──► Phase 6: Chat & Messaging
    ├──► Phase 9: Profile
    │        └──► Phase 10: Portfolio
    ├──► Phase 12: Wallet
    └──► Phase 14: Notifications

    All ──► Phase 16: Cross-Cutting Quality (final audit)
```

---

## FIGMA STRATEGY

### Code-First, Design-Second (Efficient for Existing Apps)

Since this is a **redesign** of an existing codebase (not greenfield), the most efficient approach is:

1. **Phase 0:** Define design tokens in code → export to Figma as variables
2. **Phase 1:** Redesign core widgets in code → screenshot/preview → build Figma components
3. **Phases 2-15:** For each screen:
   - Sketch layout direction in Figma (quick wireframe)
   - Implement in code using redesigned widgets + tokens
   - Preview with `mcp__Claude_Preview__preview_start` (if Flutter web)
   - Screenshot final result → import to Figma as reference
   - Use `mcp__Figma__add_code_connect_map` to link Figma → Code

### Alternative: Design-First (For Major Visual Decisions)

For phases where you want more creative exploration BEFORE coding:
1. Sketch 2-3 options in Figma
2. Use `mcp__Figma__get_screenshot` to share with team
3. Pick direction
4. Then implement in code

### Figma File Structure (Grows with Each Phase)

```
SLine Design System
├── Cover Page                    ← Brand, links, status
├── Design Decisions              ← Phase 0: .impeccable.md content
├── Tokens                        ← Phase 0: Colors, Type, Space, Motion, States
├── Component Library             ← Phase 1: Buttons, Fields, Cards, Nav, etc.
├── Screen Library
│   ├── Auth Screens              ← Phase 3
│   ├── Home & Discovery          ← Phase 5
│   ├── Tasks & Tenders           ← Phase 4
│   ├── Chat & Messaging          ← Phase 6
│   ├── Dashboard                 ← Phase 7
│   ├── Booking & Payments        ← Phase 8
│   ├── Profile                   ← Phase 9-10
│   ├── Proposals                 ← Phase 11
│   ├── Wallet                    ← Phase 12
│   ├── Work Management           ← Phase 13
│   ├── Notifications             ← Phase 14
│   └── Secondary                 ← Phase 15
└── Prototypes                    ← Key user flows
```

---

## SKILL EXPLORATION MAP

Each phase has PRIMARY skills (listed in execution file) but you can freely explore any skill.

### Skills Available & When They Shine

| Skill | Best For | Recommended Phase(s) |
|-------|----------|---------------------|
| **teach-impeccable** | One-time design context | Phase 0 ONLY |
| **audit** | Quality scoring (0-4) | End of every phase |
| **normalize** | Align to design tokens | Phase 0, 1, and any inconsistency |
| **typeset** | Typography fixes | Phase 0, then spot fixes |
| **colorize** | Color decisions | Phase 0, then per-screen |
| **animate** | Motion & transitions | Phase 1, 2, 3, 5, 6, 7 |
| **delight** | Micro-interactions | Phase 1, 6, 7, 12, 14 |
| **clarify** | UX writing & labels | Phase 3, 6, 8, 16 |
| **harden** | Edge cases & a11y | Phase 1, 3, 6, 8, 16 |
| **arrange** | Layout & spacing | Phase 4, 5, 7, 8, 9 |
| **polish** | Final quality pass | End of every phase |
| **distill** | Simplify clutter | Phase 4, 5, 9 |
| **onboard** | Empty states & first-run | Phase 3, 5, 6, 7, 16 |
| **adapt** | Responsive/tablet | Phase 2, 5, 7, 16 |
| **optimize** | Performance | Phase 1 (GlassContainer), 16 |
| **extract** | Find reusable patterns | Phase 1, 4, 16 |
| **bolder** | Add visual impact | When something feels flat |
| **quieter** | Tone down excess | When something feels noisy |
| **critique** | Full design evaluation | Phase 16 (final audit) |
| **overdrive** | Advanced effects | Sparingly — hero sections only |

### Skill Chaining (Recommended Combos)

```
New screen:      arrange → colorize → animate → clarify → polish
Card redesign:   arrange → normalize → animate → harden
Form screen:     clarify → harden → animate → polish
Empty state:     onboard → clarify → delight
Final check:     audit → critique → polish
```

---

## PROGRESS TRACKING

Update this section as phases complete:

```
[ ] Phase 0  — Design System Foundation      — Started: ____  Completed: ____
[ ] Phase 1  — Core Widget Redesign           — Started: ____  Completed: ____
[ ] Phase 2  — App Shell & Navigation         — Started: ____  Completed: ____
[ ] Phase 3  — Authentication Screens         — Started: ____  Completed: ____
[ ] Phase 4  — Cards (All Types)              — Started: ____  Completed: ____
[ ] Phase 5  — Home & Discovery               — Started: ____  Completed: ____
[ ] Phase 6  — Chat & Messaging               — Started: ____  Completed: ____
[ ] Phase 7  — Dashboard                      — Started: ____  Completed: ____
[ ] Phase 8  — Booking & Payments             — Started: ____  Completed: ____
[ ] Phase 9  — Profile                        — Started: ____  Completed: ____
[ ] Phase 10 — Portfolio                      — Started: ____  Completed: ____
[ ] Phase 11 — Proposals & Direct Offers      — Started: ____  Completed: ____
[ ] Phase 12 — Wallet                         — Started: ____  Completed: ____
[ ] Phase 13 — Work Management                — Started: ____  Completed: ____
[ ] Phase 14 — Notifications                  — Started: ____  Completed: ____
[ ] Phase 15 — Secondary Screens              — Started: ____  Completed: ____
[ ] Phase 16 — Cross-Cutting Quality          — Started: ____  Completed: ____
```

---

## REFERENCE FILES

| Document | Location | Purpose |
|----------|----------|---------|
| Master Plan (detailed specs) | `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` | Every before→after spec for every file |
| Phase 0 Execution | `.TODO/PHASE_0_EXECUTION.md` | Step-by-step for design system |
| Phase N Execution | `.TODO/PHASE_N_EXECUTION.md` | Created as each phase begins |
| Design Context | `.impeccable.md` | Aesthetic decisions (created in Phase 0) |
| UI Inventory | `SLINE_UI_INVENTORY_V2.md` | Current state documentation |
| Skill Reference | `.cursor/skills/` | All available design skills |
| Agent Reference | `.cursor/Agents/` | @Pixel, @Architect, @Sentinel |
