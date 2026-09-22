# Working in this repo

Conventions for an AI assistant working on this codebase. Committed on purpose:
it is part of how the work was steered, and it is what keeps a new session
building the same system as the last one.

Read [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) for what the app is for,
[`docs/PLAN.md`](docs/PLAN.md) for how it was built, and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how it works and why.

## The rules that are not up for renegotiation

1. **Salaries are never converted between currencies.** Every figure belongs to
   one country and is labelled with that country's currency. Grouping by
   anything other than country requires a country filter; sorting the employee
   list by salary requires one too. Across countries, only headcount is
   totalled. If a change would produce a mixed-currency number, the change is
   wrong — the API refuses these questions on purpose.
2. **Every statistic is shown next to its headcount**, so a median over three
   people is visibly that.
3. **Nothing is readable without signing in.** `ApplicationController` requires
   a session; endpoints opt out explicitly, never by omission.
4. **Unknown filter values are rejected, not ignored.** Silently dropping a
   filter shows more people than the caller thinks they are seeing.
5. **Currency is derived from the country, never stored or accepted as input.**

## Layout and commands

| Path | What it is |
|---|---|
| `backend/` | Rails 8, API-only, SQLite, RSpec |
| `frontend/` | Vite · React · TypeScript · Ant Design · TanStack Query |
| `docs/` | Requirements, plan, architecture, AI usage |

```bash
cd backend  && bundle exec rspec && bundle exec rubocop
cd frontend && npm test && npm run typecheck && npm run lint
```

Run the checks for whichever side you touched before committing. CI runs both.

## Code conventions

- **Comments say why, never what.** If a comment restates the line below it,
  delete it. What earns a comment: a rule that is not obvious from the code, a
  trade-off, a refusal, a workaround and the bug behind it.
- **Write for the next reader, in prose.** Full sentences. British spelling.
  The existing files are the reference for tone — match them rather than
  inventing a second voice.
- **Put a comment at the top of a file** saying what it is for and what decision
  it encodes, where that is not self-evident.
- **Backend:** query objects for anything reusable (`EmployeeFilter` is used by
  both the list and the analytics — extend it rather than writing a second
  filter), plain serializer POROs for JSON shapes, service objects under
  `app/services`. Raise `InvalidParams` for a bad request rather than returning
  a half-answer.
- **Frontend:** `src/api/` is the only place that knows the API exists;
  `src/features/<area>/` holds everything for one area; API field names stay in
  `snake_case` on the client so no mapping layer can lose one. Filters, sort,
  page and the current insight question live **in the URL**, not in React state
  — those views get bookmarked and shared.
- **Money is formatted through `src/lib/format.ts`** with the currency the API
  sent. Never render a bare salary number.

## Tests

- **Do not add tests unless asked.** The suite is small on purpose.
- When you do: expectations for anything arithmetic are **hand-computed** and
  written out as arithmetic a reader can check. Never capture what the code
  currently returns and call it the expectation.
- Deterministic: fixed clocks, fixed seeds, no network, minimal factories.

## Commits

- Conventional-commit subject (`feat(ui):`, `fix(api):`, `docs:`, `ci:`), small
  and scoped, and every commit leaves the checks green.
- The body says **why**, not a list of the files changed — the diff already has
  those.
- End with the co-author trailer for the model that helped write it.

## Numbers and claims

Never write a performance figure that was not measured, and say in the document
how it was measured. Never state that something passes without having run it.
If something could not be verified here — because it needs a browser, a
deployment, or data this machine does not have — say so plainly rather than
implying it was checked.
