---
name: evidence-first-reading
description: Read code and explain behavior only from direct evidence. Use when reviewing unfamiliar code, triaging bugs, validating claims, tracing data flow, answering "where does this happen?", or any time Codex must avoid guesses and attach every observation to a file path, enclosing function/class name, and snippet or line reference.
---

# Evidence First Reading

## Overview

Use this skill to force evidence-backed analysis before summarizing, reviewing, or editing code. Treat unsupported statements as invalid until a file, symbol, and snippet or line reference proves them.

## Follow This Workflow

1. Define the exact question in one sentence.
2. Read the smallest relevant set of files before forming conclusions.
3. Extract proof for each claim: file path, enclosing symbol, and snippet or line reference.
4. Write observations first, then separate any inference or uncertainty.
5. Refuse to present an unsupported conclusion as fact.

## Evidence Standard

Every observation must include all of these fields:

- `file`: repo-relative or absolute path
- `symbol`: enclosing function, method, class, widget, provider, or `top-level`
- `proof`: short snippet or precise line reference

If any field is missing, the observation is incomplete and must not be stated as a fact.

## Make Only These Claim Types

### Observation

Use for statements directly proven by inspected code.

Required format:

```markdown
- Observation: <fact>
  File: `<path>`
  Symbol: `<function/class>`
  Proof: `<snippet>` or `<path:line>`
```

### Inference

Use only when the user needs a conclusion that is not fully explicit in the code.

Required format:

```markdown
- Inference: <reasoned conclusion>
  Based on:
  - `<path>` / `<symbol>` / `<snippet or line>`
  Confidence: low | medium | high
```

Never present an inference as a confirmed fact.

### Unknown

Use when inspected files do not prove the answer.

Required format:

```markdown
- Unknown: not established from inspected files
  Missing evidence: <what would need to be checked next>
```

## Enforce These Reading Rules

1. Do not infer runtime behavior from filenames, folder names, or naming conventions alone.
2. Do not claim a bug cause until the control flow or state mutation is located in code.
3. Do not describe architecture, permissions, queries, or side effects without proof in the inspected files.
4. When the evidence is partial, say exactly what is proven and exactly what is still unproven.
5. Quote the smallest useful snippet. Prefer line references when a larger snippet adds noise.
6. If multiple files are involved, cite the handoff points between them.
7. Before editing, verify the target code path from source rather than relying on memory.

## Report Contract

For reviews, bug triage, or explanations, keep each finding tied to evidence:

```markdown
- Finding: <issue or answer>
  File: `<path>`
  Symbol: `<function/class>`
  Proof: `<snippet>` or `<path:line>`
  Impact: <why it matters>
```

If the user asks for a summary, provide the summary after the evidence-backed findings, not before.

## Good and Bad Examples

Bad:

```markdown
- The screen probably calls Supabase directly.
```

Good:

```markdown
- Observation: the view performs a direct Supabase read inside `build`.
  File: `lib/features/bookings/view/booking_view.dart`
  Symbol: `BookingView.build`
  Proof: `final client = Supabase.instance.client;` or `booking_view.dart:42`
```

Bad:

```markdown
- This class is responsible for validation.
```

Good:

```markdown
- Observation: input validation happens in `BookingFormViewModel.submit`.
  File: `lib/features/bookings/viewmodel/booking_form_viewmodel.dart`
  Symbol: `BookingFormViewModel.submit`
  Proof: `if (title.trim().isEmpty) { return false; }`
```

## Escalate Carefully

If you cannot produce evidence for an important claim:

1. State that the claim is unproven.
2. Name the next file, symbol, or test that should be checked.
3. Avoid broad architectural conclusions until the evidence exists.
