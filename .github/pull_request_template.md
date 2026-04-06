## What changed

<!-- Brief description of the changes -->

## Why

<!-- Motivation, ticket link, or context -->

## General checklist

- [ ] Tests pass (`flutter test`)
- [ ] Analysis clean (`flutter analyze`)
- [ ] Architecture guard passes
- [ ] No hardcoded colors (`Color(0xFF...)`) -- use `AppColors.*`
- [ ] No `print()` or `debugPrint()` -- use `AppLogger`
- [ ] No hardcoded secrets or credentials

## If payment / wallet / booking is touched

- [ ] Edge cases tested (zero amount, negative, overflow)
- [ ] RLS policies verified for owner / participant / other
- [ ] No PII in logs
- [ ] Escrow state transitions are server-side enforced

## If migration files are included

- [ ] Follow [MIGRATION_REVIEW_CHECKLIST.md](MIGRATION_REVIEW_CHECKLIST.md) (7-point checklist)

## If Supabase / Edge Functions are touched

- [ ] CORS headers present (`ALLOWED_ORIGIN`)
- [ ] Auth verification in place
- [ ] No `service_role` key in client code
- [ ] `supabase/functions/.env.example` updated if new env vars added
