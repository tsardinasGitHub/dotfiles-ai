---
name: react-advanced
description: >
  Advanced React/Next.js patterns: adapter pattern, React Query advanced usage,
  hook architecture, error UI, cross-layer coordination.
  Trigger: When working in any React/Next.js project.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load alongside `react-python-stack`. Apply silently.

---

## Adapter Pattern — DTO Mapping

Transform DTOs **only** in `adapters/` directory. Never in components or `queryFn`.

```
Backend Pydantic Model
  ↓
BackendXDTO interface (exact API shape, TypeScript)
  ↓
Domain Type (semantic names, UI-ready)
  ↓
adaptX(dto) → domain
```

```typescript
// adapters/user.adapter.ts

// Exact backend shape — never change without backend changing first
interface BackendUserDTO {
  id: number
  email: string
  is_active: boolean
  role: string
  created_at: string
}

// Domain type — semantic, UI-ready
interface User {
  id: number
  email: string
  isBanned: boolean       // semantic: !is_active
  role: 'admin' | 'student' | 'parent'
  createdAt: Date
}

export function adaptUser(dto: BackendUserDTO): User {
  return {
    id: dto.id,
    email: dto.email.toLowerCase(),
    isBanned: !dto.is_active,
    role: dto.role.toLowerCase() as User['role'],
    createdAt: new Date(dto.created_at),
  }
}
```

**Cross-layer coordination rule**: When a backend Pydantic DTO changes, update in the SAME response:
1. `BackendXDTO` interface (TypeScript)
2. `adaptX()` function
3. Zod schema

Never leave frontend and backend out of sync.

---

## Hook Architecture

Hooks are the application layer. They manage state and actions — not the component.

```typescript
// hooks/useStudentProfile.ts

export function useStudentProfile(studentId: number) {
  const queryClient = useQueryClient()

  // Server state — React Query
  const { data, isLoading, error, isError } = useQuery({
    queryKey: studentKeys.detail(studentId),
    queryFn: () => studentService.getById(studentId).then(adaptStudent),
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 2,
  })

  // UI state only — not data fetching state
  const [showEditDialog, setShowEditDialog] = useState(false)
  const [selected, setSelected] = useState<Goal | null>(null)

  // ALL actions use useCallback
  const handleSelect = useCallback((goal: Goal) => {
    setSelected(goal)
    setShowEditDialog(true)
  }, [])

  const handleClose = useCallback(() => {
    setShowEditDialog(false)
    setSelected(null)
  }, [])

  // Return contract — always this shape
  return {
    data,
    isLoading,
    error,
    isError,
    showEditDialog,
    selected,
    actions: {
      select: handleSelect,
      close: handleClose,
    },
  }
}
```

**Rules:**
- Naming: `use[Feature][Entity]` — e.g., `useStudentProfile`, `useCurriculumUpload`
- Return contract: `{ data, isLoading, error, isError, [uiState], actions }`
- `useCallback` on **all** actions and handlers — no exceptions
- `useMemo` only for costly computations (≥ O(n) over large arrays)
- `useState` in hooks: ✅ UI state (modals, dialogs, tabs, selected item) — ❌ never for data fetching state
- ≤ 3 `useState` per component/hook — more than 3 → extract to custom hook

---

## React Query — Advanced Patterns

### Default configuration
```typescript
// Apply to QueryClient provider
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,   // 5 min — don't refetch if data is fresh
      gcTime: 10 * 60 * 1000,     // 10 min — keep inactive data in cache
      retry: 2,
    },
  },
})
```

### Polling with refetchInterval
```typescript
// Use refetchInterval — NEVER setInterval in useEffect
const { data } = useQuery({
  queryKey: ['job-status', jobId],
  queryFn: () => jobService.getStatus(jobId),
  enabled: !!jobId,
  staleTime: 0,  // always fresh for real-time data
  refetchInterval: (data) => {
    // stop polling on terminal state
    if (!data || data.status === 'completed' || data.status === 'failed') {
      return false
    }
    return 2000  // poll every 2s while processing
  },
})
```

### Dependent queries
```typescript
const { data: program } = useQuery({
  queryKey: programKeys.detail(programId),
  queryFn: () => programService.getById(programId),
})

const { data: sections } = useQuery({
  queryKey: sectionKeys.byProgram(program?.id),
  queryFn: () => sectionService.getByProgram(program!.id),
  enabled: !!program,   // only fetch when parent exists
})
```

### Query keys factory
```typescript
// Always use a factory — never inline string arrays
export const studentKeys = {
  all: () => ['students'] as const,
  list: () => [...studentKeys.all(), 'list'] as const,
  detail: (id: number) => [...studentKeys.all(), 'detail', id] as const,
}

// Invalidation targets the right scope
queryClient.invalidateQueries({ queryKey: studentKeys.list() })
queryClient.invalidateQueries({ queryKey: studentKeys.detail(id) })
```

### Mutation with invalidation
```typescript
const mutation = useMutation({
  mutationFn: (data: UpdateStudentInput) => studentService.update(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: studentKeys.all() })
    toast({ title: 'Updated', variant: 'default' })
  },
  onError: (error: ApiError) => {
    toast({ title: 'Error', description: error.message, variant: 'destructive' })
  },
})
```

---

## Error UI — Mandatory

Every component that fetches data must handle all three states: loading, error, empty.

```typescript
// NO — silent failure
function StudentList() {
  const { data } = useStudentList()
  return <ul>{data?.map(s => <li key={s.id}>{s.name}</li>)}</ul>
}

// YES — all states handled
function StudentList() {
  const { data, isLoading, isError, error, actions } = useStudentList()

  if (isLoading) return <StudentListSkeleton />          // Skeleton, not spinner
  if (isError)   return <ErrorFallback error={error} onRetry={actions.refetch} />
  if (!data?.length) return <EmptyState message="No students yet" />

  return <ul>{data.map(s => <li key={s.id}>{s.name}</li>)}</ul>
}
```

**Rules:**
- Loading state → **Skeleton UI**, never a spinner
- Error state → **ErrorFallback** with a retry action, never a blank screen
- Empty data → **EmptyState** component, never an empty table/list
- Wrap complex pages with `<ErrorBoundary>` (catches render/effect throws)
- `ErrorBoundary` is for uncaught errors only — API errors handled inline

---

## Guards — Layout Level Only

Auth and role guards go in `layout.tsx`. Never repeat them in child components.

```typescript
// app/(protected)/layout.tsx
export default function ProtectedLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthGuard>
      <RoleGuard allowedRoles={['admin', 'teacher']}>
        {children}
      </RoleGuard>
    </AuthGuard>
  )
}

// NO — guard repeated in every child component
function AdminPanel() {
  const { user } = useAuth()
  if (user.role !== 'admin') return null  // wrong: guard already in layout
  return <div>...</div>
}
```

---

## Performance Anti-Patterns

```typescript
// NO — inline object creates new reference on every render
<Component config={{ debounce: 300 }} />

// YES — stable reference
const config = useMemo(() => ({ debounce: 300 }), [])
<Component config={config} />

// NO — inline function in props
<Button onClick={() => handleClick(item.id)} />

// YES — useCallback
const handleClick = useCallback((id: number) => { ... }, [])
<Button onClick={() => handleClick(item.id)} />

// Use React.memo for heavy leaf components
export const HeavyChart = React.memo(function HeavyChart({ data }: Props) { ... })

// Client-only heavy libraries
const RichEditor = dynamic(() => import('./RichEditor'), { ssr: false })
```

---

## Frontend Testing Priority

Test in this order: **hooks first, then adapters, then components**.

```typescript
// 1. Hook tests (most value — tests all logic)
test('useStudentProfile returns normalized role', async () => {
  mockStudentService.getById.mockResolvedValue(mockDTO)

  const { result } = renderHook(() => useStudentProfile(1), { wrapper })

  await waitFor(() => expect(result.current.isLoading).toBe(false))

  expect(result.current.data?.role).toBe('student')  // lowercase from adapter
})

// 2. Adapter tests (pure in/out — easiest to write)
test('adaptUser maps is_active to isBanned', () => {
  const dto: BackendUserDTO = { id: 1, email: 'A@B.COM', is_active: false, role: 'ADMIN', created_at: '2024-01-01T00:00Z' }
  const user = adaptUser(dto)

  expect(user.isBanned).toBe(true)
  expect(user.email).toBe('a@b.com')
  expect(user.role).toBe('admin')
})

// 3. Component tests (only for non-trivial UI logic — else test the hook)
test('shows skeleton while loading', () => {
  mockUseStudentList.mockReturnValue({ isLoading: true, data: undefined })
  render(<StudentList />)
  expect(screen.getByTestId('skeleton')).toBeInTheDocument()
})
```

Rules:
- `renderHook` + `waitFor(() => !isLoading)` for async hooks
- Mock service layer, not React Query internals
- Presentational components → test the hook instead
- Never test just "text exists" without behavioral assertion
