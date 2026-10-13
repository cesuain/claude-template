# Assertion replacement cheat sheet

| You wrote | Replace with |
|---|---|
| `const data = (await res.json()) as User` | `const data = UserSchema.parse(await res.json())`, or `fetchJson(url, UserSchema, tags)` |
| `JSON.parse(text) as Config` | `ConfigSchema.parse(JSON.parse(text))` / `parseJson(ConfigSchema, text)` |
| `process.env.API_URL!` | `env.API_URL` from the Zod-validated `env.ts` |
| `map.get(k)!` | `const v = map.get(k); if (v === undefined) throw new NotFoundError(k);` |
| `arr[0]!` / `arr.find(...)!` | `const [first] = arr; if (!first) return …;` (with `noUncheckedIndexedAccess`) |
| `ref.current!.focus()` | `ref.current?.focus()` |
| `document.getElementById('x') as HTMLInputElement` | `const el = document.getElementById('x'); if (!(el instanceof HTMLInputElement)) return;` |
| `e.target as HTMLInputElement` | Use `e.currentTarget` with typed handler `ChangeEvent<HTMLInputElement>` |
| `err as Error` | `err instanceof Error ? err.message : String(err)` |
| `obj as Record<string, unknown>` | `function isRecord(v: unknown): v is Record<string, unknown> { return typeof v === 'object' && v !== null; }` |
| `value as 'a' \| 'b'` | `z.enum(['a','b']).parse(value)`, or `const OPTIONS = ['a','b'] as const; OPTIONS.includes(v)` with a type guard |
| `{} as State` (initial value) | Build a complete initial value, or type it `State \| null` and handle null |
| `x as unknown as T` | A schema or type guard. A double cast is always a design bug |
| `private client!: Client` | Initialize in the constructor, or make it `Client \| undefined` and guard |
| `searchParams.page as string` | `PageQuery.safeParse(searchParams)` |
| `prisma.order.findFirst(...) as OrderWithItems` | Pass `include` and type it with `Prisma.OrderGetPayload<{ include: … }>` |
| `const x: any = …` | `unknown` + narrow, or the real derived type |
| `// @ts-ignore` on a library mismatch | Module augmentation (`declare module 'lib' { … }`) in a `.d.ts`, or a typed wrapper |
| `Object.keys(o) as (keyof T)[]` | A typed helper: `function keys<T extends object>(o: T) { return Object.keys(o).filter((k): k is Extract<keyof T,string> => k in o); }` |
| `JSON.parse(localStorage.getItem('k')!)` | `const raw = localStorage.getItem('k'); const parsed = raw ? Schema.safeParse(JSON.parse(raw)) : null;` |

## User-defined type guard template
```ts
export function hasCode(e: unknown): e is { code: string } {
  return typeof e === 'object' && e !== null && 'code' in e && typeof e.code === 'string';
}
```
