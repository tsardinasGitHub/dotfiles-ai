---
name: react-python-stack
description: >
  Conventions, patterns, and anti-patterns for Next.js (App Router) + Python FastAPI projects.
  Trigger: When working in a React, Next.js, TypeScript, or Python FastAPI project.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load when working in any React/Next.js or Python/FastAPI project. Apply silently.

## Legacy Thresholds (stack-specific)

| File type | PIPELINE threshold | Notes |
|-----------|-------------------|-------|
| React / TypeScript | < 500 lines | Components should be much smaller |
| Python | < 500 lines | DDD modules can be larger but Python is verbose — 500L is the ceiling |
| Config (.json, .yml, .env) | < 300 lines | |
| Documentation (.md) | < 800 lines | |

Files exceeding threshold → LEGACY mode (block direct modification, suggest extraction).

---

## Next.js — App Router Patterns

### Server vs Client Components — the most important rule
```typescript
// Default: Server Component (no directive needed)
// async, fetch data, no browser APIs, no event handlers

// 'use client' ONLY at leaves — interactive, browser-dependent pieces
'use client'
// use for: onClick, useState, useEffect, browser APIs, animations
```

**Anti-pattern**: putting `'use client'` at a parent container that wraps server-fetchable data.
**Rule**: push client boundary as far down the tree as possible.

### Data fetching hierarchy
| Need | Use | Never use |
|------|-----|-----------|
| Server data (initial load) | `async` Server Component + `fetch` | `useEffect` for fetching |
| Client-side data / refetch | TanStack Query (`useQuery`) | `useEffect` + `useState` for async data |
| Mutations | Server Actions | Direct API calls from client with secrets |
| Global UI state | Zustand | Context for global state, Redux |
| Derived state | Calculate during render | `useState` to mirror another state |

### Next.js 16+ specifics
```typescript
// params and searchParams are Promises in Next.js 16+
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ q: string }>
}) {
  const { id } = await params
  const { q } = await searchParams
}
```

---

## React Anti-Patterns — PROHIBITED

### useEffect for state syncing
```typescript
// NO — derive state during render, never sync with useEffect
const [fullName, setFullName] = useState('')
useEffect(() => setFullName(`${firstName} ${lastName}`), [firstName, lastName])

// YES — computed during render
const fullName = `${firstName} ${lastName}`
```

### Client component pollution
```typescript
// NO — 'use client' on parent forces entire subtree to be client
'use client'
export function PageLayout({ children }) { ... }  // now everything is client

// YES — 'use client' only on the interactive leaf
export function PageLayout({ children }) {  // stays server
  return <div>{children}<InteractiveButton /></div>
}
'use client'
function InteractiveButton() { ... }  // only this is client
```

### Prop drilling > 3 levels
Use Composition Pattern or Zustand. Passing props through 4+ components is a design smell.

### Fat components
- UI logic > 20 lines → extract to **custom hook**
- Component > 100 lines → split into sub-components
- Component doing both data-fetching AND rendering → split into container + presentation

### Hydration mismatches
```typescript
// NO — non-deterministic in SSR
<div id={Math.random().toString()}>
<span>{Date.now()}</span>

// YES — use useEffect for client-only values
const [id, setId] = useState('')
useEffect(() => setId(Math.random().toString()), [])
```

### Direct DOM manipulation
```typescript
// NO
document.getElementById('btn').focus()

// YES
const ref = useRef<HTMLButtonElement>(null)
ref.current?.focus()
```

---

## TypeScript & Validation

```typescript
// NO — type casting
const user = response as User

// YES — runtime validation
const user = UserSchema.parse(response)
const result = UserSchema.safeParse(response)

// NO — any
function process(data: any) { ... }

// YES — strict typing
function process(data: UserInput): ProcessResult { ... }
```

**Zod schemas**: single source of truth, shared between client and server. Never duplicate schema definitions.

```typescript
// Shared schema (lib/schemas/user.ts) — imported by both client and server
export const UserSchema = z.object({ ... })
export type User = z.infer<typeof UserSchema>
```

Use Enums or const objects for roles and status — never hardcoded strings.

---

## Python FastAPI — Return Pattern

All service functions return `{ data, error }` (Railway-Oriented Programming):

```python
# YES — explicit result, no exceptions for business errors
from returns.result import Result, Success, Failure

def create_user(data: UserInput) -> Result[User, str]:
    if not valid(data):
        return Failure("validation_error")
    user = repo.save(data)
    return Success(user)

# In FastAPI handler — unwrap at the boundary
@router.post("/users")
async def create(data: UserInput):
    match create_user(data):
        case Success(user): return {"data": user, "error": None}
        case Failure(err):  raise HTTPException(400, detail=err)
```

---

## Security

### ZERO SECRETS ON CLIENT
```typescript
// NO — NEXT_PUBLIC_ is exposed to browser
NEXT_PUBLIC_OPENAI_KEY=sk-...
NEXT_PUBLIC_DB_PASSWORD=...

// YES — server-only env vars (no NEXT_PUBLIC_ prefix)
OPENAI_API_KEY=sk-...

// All external API calls (OpenAI, Python services) go through Server Actions or Route Handlers
```

### RBAC
```typescript
// Client-side role checks: UX only (show/hide buttons)
// NEVER for security decisions

// NO — client role check for security
if (user.role === 'admin') deleteResource(id)

// YES — verify on server
// Server Action or Route Handler:
const session = await getServerSession()
if (session.user.role !== 'admin') throw new Error('Unauthorized')
await deleteResource(id)
```

### XSS
```typescript
// NO
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// YES — use react-markdown or sanitize first
<ReactMarkdown>{userContent}</ReactMarkdown>
```

---

## Testing

| Layer | Tool | What to test |
|-------|------|-------------|
| Logic, utilities, hooks | **Vitest** | Pure functions, custom hooks, business logic |
| Components | **React Testing Library** | User interactions, rendering, behavior |
| Critical flows | **Playwright** | Auth, checkout, key user journeys |

- Co-locate tests: `Button.tsx` → `Button.test.tsx` in same folder
- Coverage target: > 80% on business logic, > 60% on UI components
- Test **what** the component does, not **how** it does it
- TDD cycle: failing test → minimum implementation → refactor

---

## Styling

```typescript
// Tailwind + shadcn/ui + cn() for conditional classes
import { cn } from '@/lib/utils'  // clsx + tailwind-merge

<button className={cn(
  "base-classes",
  isActive && "active-classes",
  disabled && "disabled-classes"
)} />
```

Add missing shadcn components: `npx shadcn-ui@latest add [component]`
