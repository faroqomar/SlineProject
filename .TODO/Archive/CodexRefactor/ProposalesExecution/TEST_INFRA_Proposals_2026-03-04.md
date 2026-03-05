# Test Infrastructure: Proposals 2026-03-04

**Purpose**: Deterministic proposal test baseline before authoring proposal tests.

## Widget harness

- **Path**: `test/test_support/pump_app.dart`
- **Usage**: `pumpApp(tester, child, navigatorObservers: [...])` — wraps child in MaterialApp with AppTheme.light().
- Use for widget tests that need a single proposal screen or sheet (no full app).

## Integration harness

- **Path**: `test/integration_test/support/helpers.dart`, `test/integration_test/support/preflight.dart`
- **Usage**: `ensureIntegrationBinding()`, `launchAppForIntegration(tester, tag: '...', resetAuth: true/false)`, `pumpUntil`, `pumpUntilAnyFound`, `findByKey`, etc.
- **Preflight**: Logging and env checks; integration tests depend on Supabase init and optional env/secrets.
- **Note**: Staging-sensitive; document required env (e.g. test project URL) and do not hardcode secrets.

## Timeout budgets

- Widget tests: single-frame or short pump; default test timeout (e.g. 30s) per `flutter test`.
- Integration tests: use bounded waits (e.g. 15s for login/nav) as in existing `pumpUntilAnyFound`; avoid unbounded `pumpAndSettle` in loops.

## Rerun policy

- Flaky proposal tests: max 2 reruns per test file in CI; tag with `@retry` or document in CI config.
- On failure: capture failure artifact (see below) before rerun.

## Failure artifact path / tagging

- **Path**: `test/results/` or CI artifact directory; proposal failures tagged `proposals` or `proposal_*`.
- **Content**: Screenshot/serialized state if available; test name, phase (unit/widget/integration), and timestamp.
- **Convention**: Name files `proposals_<test_name>_<timestamp>.txt` (or .png if screenshot).

## Selector / key map (implement in code)

| Surface | Key / selector | Purpose |
|--------|----------------|--------|
| RequestsListScreen | `Key('proposals_list_screen')` or `Key('requests_list_screen')` | Root list |
| Submit proposal sheet | `Key('submit_proposal_sheet')` | Submit form |
| Request tile | `Key('request_tile_<id>')` or semantic | Per-proposal tile |
| Inbox tab (payment resume) | Key for "Pay" / resume CTA | Inbox launcher |
| Work tab (payment resume) | Key for resume CTA | Work launcher |
| Next actions list | Key for payment resume item | Next actions launcher |
| Work item details | Key for "Pay" / resume | Work details launcher |
| Tender payment screen | `Key('proposal_payment_screen')` or existing | Payment UI |

*(Keys to be implemented in respective widgets per step 0.0b.)*
