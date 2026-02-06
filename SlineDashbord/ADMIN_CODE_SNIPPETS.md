# Admin Code Snippets - Critical Boilerplate

These are the "hard parts" of the setup. Copy-paste these to save hours of debugging.

## 1. Supabase Server Client (Service Role)
**Path:** `core/lib/supabase/server.ts`

> [!WARNING]
> This creates a client with ADMIN privileges. Use only in Server Actions.

```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createServiceRoleClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!, // <--- THE SECRET KEY
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
           // Service Role client usually doesn't need to set cookies for auth, 
           // but we keep this standard if we mix contexts. 
           // Realistically, for pure admin actions, we don't need auth cookies, 
           // but we DO need them to verify WHO is making the request first.
           try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
```

## 2. Supabase Auth Client (For Login/Middleware)
**Path:** `core/lib/supabase/client.ts`

```typescript
// Standard "Anon" client for checking if the user is logged in
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createAuthClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, 
    {
      cookies: {
        getAll() { return cookieStore.getAll() },
        setAll(cookiesToSet) {
           try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {}
        },
      },
    }
  )
}
```

## 3. Middleware Guard (The Gatekeeper)
**Path:** `middleware.ts`

```typescript
import { type NextRequest, NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>  request.cookies.set(name, value))
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options))
        },
      },
    }
  )

  // 1. Check Auth (Refresh Session)
  const { data: { user } } = await supabase.auth.getUser()

  // 2. Protect Dashboard Routes
  if (request.nextUrl.pathname.startsWith('/') && request.nextUrl.pathname !== '/auth/login') {
    if (!user) {
      return NextResponse.redirect(new URL('/auth/login', request.url))
    }

    // 3. Admin Role Check (Ideally from User Metadata to save a DB call, or a quick DB check)
    // Assuming we store role in app_metadata
    const role = user.app_metadata?.role || 'user';
    if (role !== 'admin' && role !== 'super_admin') {
       // Optional: Allow them if they are in 'public.profiles' with role admin
       // For now, simple redirect
       // return NextResponse.redirect(new URL('/auth/unauthorized', request.url))
    }
  }

  return response
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

## 4. Base ViewModel Hook
**Path:** `core/hooks/use-view-model.ts`

```typescript
import { useState, useCallback } from 'react'

export function useViewModel<T>(initialState: T) {
  const [state, setState] = useState<T>(initialState)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const execute = useCallback(async <R>(action: () => Promise<R>) => {
    setIsLoading(true)
    setError(null)
    try {
      const result = await action()
      return result
    } catch (e: any) {
      setError(e.message || 'An error occurred')
      throw e
    } finally {
      setIsLoading(false)
    }
  }, [])

  return { state, setState, isLoading, error, execute }
}
```
