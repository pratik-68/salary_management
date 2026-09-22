# Salary Management

[![CI](https://github.com/pratik-68/salary_management/actions/workflows/ci.yml/badge.svg)](https://github.com/pratik-68/salary_management/actions/workflows/ci.yml)

Web app for an HR Manager to maintain salary data for ~10,000 employees across
several countries, and to answer questions about how the organisation pays
people.

Salaries are **never converted between currencies**. Every figure belongs to
one country and is shown in that country's currency, because a converted number
would move on a day when nobody's pay had. Across countries, only headcount is
totalled.

## Stack

| Part | Choice |
|---|---|
| `backend/` | Ruby on Rails 8 (API-only), SQLite, RSpec |
| `frontend/` | React + TypeScript on Vite, Ant Design, TanStack Query, Recharts, Vitest |

## Getting started

Requires Ruby 3.2, Node 22 (or 20.19+), and SQLite 3.

```bash
# Backend, on http://localhost:3000
cd backend
bundle install
bin/rails db:prepare
bin/rails db:seed        # 10,000 employees, the same ones every run
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

## What it does

- **Employees.** Search by name, email or code; filter by country, department,
  level and job title; sort and page through the results, all served from the
  server. Create and edit in a drawer, with validation on both sides and server
  messages landing on the field that caused them. The view lives in the URL, so
  it can be bookmarked and shared.
- **Insights.** *Pay by country* — one row per country with headcount, total
  payroll and min, median, average and max, each in its own currency. *Pay
  within a country* — pick a country, group by department, job title or level,
  narrow it further if you like, and read the result as a table and a chart of
  the medians.

## Docs

| Document | What's in it |
|---|---|
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Goal, scope, the currency rule, and what is deliberately left out |
| [docs/PLAN.md](docs/PLAN.md) | The plan this was built to: architecture, data model, API, milestones |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How it works, the decisions and their costs, and **measured** endpoint timings |
| [docs/AI_USAGE.md](docs/AI_USAGE.md) | How an AI assistant was used, and what it was not allowed to do |
| [CLAUDE.md](CLAUDE.md) | The conventions the assistant was held to |

## Checks

```bash
cd backend  && bundle exec rspec && bundle exec rubocop
cd frontend && npm test && npm run typecheck && npm run lint
```

CI runs all of these, plus the production build, on every push and pull
request.
