# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in SLine, please report it responsibly.

**Contact:** security@faroqomar.dev

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Do NOT open a public GitHub issue for security vulnerabilities.**

## Response Timeline

- **Acknowledgment:** Within 48 hours
- **Triage:** Within 7 days
- **Fix or mitigation:** Timeline communicated during triage

## What to Report

- Authentication bypass or session hijacking
- Data exposure (accessing another user's data)
- RLS policy circumvention
- Payment manipulation or escrow bypass
- Unauthorized access to admin functionality
- Storage access control bypass
- SQL injection or RPC abuse

## What NOT to Report

- **Supabase anon key** in client code: This is public by design and protected by Row Level Security (RLS) policies. It cannot access data without proper authentication.
- Known cosmetic issues or UI bugs (use a regular bug report instead)

## Security Architecture

SLine uses a defense-in-depth approach:

- **Row Level Security (RLS)** enabled on all database tables
- **Server-side payment processing** via Edge Functions (no client-side payment logic)
- **Signed URLs** for private storage access (short-lived, generated at render time)
- **Auth-gated Edge Functions** for all privileged operations
- **MVVM architecture** prevents direct database access from UI layer
