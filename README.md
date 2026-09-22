# Salary Management

Web app for an HR Manager to maintain salary data for ~10,000 employees across several
countries, and to answer questions about how the organisation pays people.

- [Requirements](docs/REQUIREMENTS.md) — goal, scope, and what is deliberately left out
- [Implementation plan](docs/PLAN.md) — architecture, data model, API, and milestones

## Stack

| Part | Choice |
|---|---|
| `backend/` | Ruby on Rails 8 (API-only), SQLite, RSpec |
| `frontend/` | React + TypeScript on Vite, Ant Design, TanStack Query, Vitest |

Salaries are always shown in the local currency of one country and are never converted
between currencies. The reasoning is in the requirements doc.

## Getting started

Requires Ruby 3.2, Node 20+, and SQLite 3.

```bash
# Backend, on http://localhost:3000
cd backend
bundle install
bin/rails db:prepare
bin/rails db:seed        # 10,000 employees
bin/rails server

# Frontend, on http://localhost:5173
cd frontend
npm install
npm run dev
```

The dev server proxies `/api` to the backend, so both run on one origin.

Open http://localhost:5173 and sign in as the seeded HR Manager:
`hr@example.com` / `password123`. Both come from `HR_MANAGER_EMAIL` and
`HR_MANAGER_PASSWORD`, which is how a deployment would set its own.

## Checks

```bash
cd backend  && bundle exec rspec && bundle exec rubocop
cd frontend && npm test && npm run typecheck && npm run lint
```
