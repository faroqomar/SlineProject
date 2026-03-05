# Live DB Baseline (AuthFix 2026-03-01)

Timestamp: 2026-03-05T22:36:00+03:00

## Row Counts

- `auth.users`: 6
- `public.profiles`: 4
- `auth_users_missing_profile`: 2

## Triggers

- `auth.users`: No custom triggers for profile creation exist yet.
- `public.profiles`: None.

## Policies on `public.profiles`

| Policy Name                          | Action | Roles         | Qual              | With Check        |
| ------------------------------------ | ------ | ------------- | ----------------- | ----------------- |
| Allow insert for authenticated users | INSERT | public        | null              | (auth.uid() = id) |
| Users can delete their own profile   | DELETE | public        | (auth.uid() = id) | null              |
| Users can insert their own profile   | INSERT | public        | null              | (auth.uid() = id) |
| Users can update their own profile   | UPDATE | public        | (auth.uid() = id) | null              |
| profiles_select_self                 | SELECT | authenticated | (id = auth.uid()) | null              |
| profiles_update_self                 | UPDATE | authenticated | (id = auth.uid()) | (id = auth.uid()) |

Findings:

- Duplicate INSERT policies.
- Duplicate UPDATE policies.
- Client-side inserts still supported.
