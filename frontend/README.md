# Frontend

The HR Manager's app: React and TypeScript on Vite, with Ant Design, TanStack
Query and React Router. It talks to the Rails API in [`../backend`](../backend)
and has no state of its own beyond the URL.

```bash
npm install
npm run dev        # http://localhost:5173, proxying /api to http://localhost:3000
```

Sign in with the seeded HR Manager account; the root [README](../README.md) has
the credentials and how to seed.

## Layout

| Path | What lives there |
|---|---|
| `src/api/` | The typed fetch client, the response types, and the TanStack Query hooks. The only place that knows the API exists. |
| `src/app/` | The shell: the route guard, the sidebar layout, the 404 page. |
| `src/features/` | One folder per area of the app: `auth`, `employees`, `insights`. |

Routing is declarative in `src/App.tsx`, where everything except the login page
sits under one guarded route, so a page added later is protected by where it
sits rather than by remembering to protect it.

Salary figures are always shown with the currency the API sent alongside them
and are never converted; the reasoning is in
[docs/REQUIREMENTS.md](../docs/REQUIREMENTS.md).

## Checks

```bash
npm test           # Vitest
npm run typecheck  # tsc -b
npm run lint       # oxlint
npm run build      # production bundle into dist/
```
