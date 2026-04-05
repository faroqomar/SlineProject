# Lint Debt Tracking — Phase E very_good_analysis Migration

**Date:** 2026-04-04
**Migration:** flutter_lints ^5.0.0 → very_good_analysis ^7.0.0

## Rules Disabled (Phase F Candidates)

### Cosmetic / Noisy (low value, high churn)
| Rule | Issue Count (pre-disable) | Reason |
|------|--------------------------|--------|
| sort_constructors_first | 239 | Cosmetic ordering preference |
| always_put_required_named_parameters_first | 220 | Cosmetic ordering preference |
| cascade_invocations | 87 | Often makes code less readable |
| avoid_redundant_argument_values | 331 | Noisy — explicit values improve readability |
| prefer_int_literals | 85 | Minor preference |
| comment_references | 14 | False positives on non-API comments |
| document_ignores | 10 | Low value for existing ignore directives |
| no_default_cases | 7 | Exhaustive switches not always appropriate |
| avoid_positional_boolean_parameters | 6 | Common Flutter pattern |
| avoid_equals_and_hash_code_on_mutable_classes | 4 | Too strict for data models |
| avoid_dynamic_calls | 117 | Supabase returns heavily dynamic types |
| avoid_catching_errors | 5 | Some test/init code needs Error catch |

### Strict Inference (analyzer-level, too noisy for Supabase codebase)
| Rule | Issue Count (pre-disable) | Reason |
|------|--------------------------|--------|
| strict-inference | 179 combined | Supabase client methods return dynamic/generic types |
| strict-raw-types | 8 | Too strict for existing type patterns |

### Project Convention Conflicts
| Rule | Reason |
|------|--------|
| public_member_api_docs | No mandatory docs on every public member |
| lines_longer_than_80_chars | Flutter widget trees frequently exceed 80 |
| flutter_style_todos | Allow plain TODO comments |
| one_member_abstracts | Single-method interfaces are fine for DI |
| sort_pub_dependencies | Preserve semantic grouping |

## Net Impact
- Total rules from very_good_analysis: ~100+
- Rules actively enforced: ~70+
- Rules disabled: ~27
- Auto-fixes applied: 862 in 219 files
- Manual fixes: 12
- Final: 0 issues
