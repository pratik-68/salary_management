# How AI was used

This project was built with an AI coding assistant (Claude Opus 5, driven
through Claude Code). Every commit it worked on records it as a co-author, so
the history shows exactly where it was involved:

```bash
git log --format='%h %s' --grep='Co-Authored-By: Claude'
```

This document is the honest version of that: what the assistant did, what it
was not allowed to do, and what had to be checked because of how it fails.

## The shape of the work

**Decisions first, in writing, before any code.** The scope, the data model,
the statistic definitions and the rule that salaries are never converted were
settled and written into [`REQUIREMENTS.md`](REQUIREMENTS.md) and
[`PLAN.md`](PLAN.md) before the first line of Ruby. Those documents then acted
as the brief for every prompt that followed. An assistant asked "build an
employee list" will invent product decisions to fill the gaps — quietly
converting currencies for a nice total, for instance. Asked to build against a
written plan, it has fewer gaps to fill.

**One milestone at a time.** Work went in the order set out in `PLAN.md` §12:
requirements, backend skeleton, domain, seeds, auth, employees API, analytics
API, then the UI, and finally CI and these documents. Each milestone ended with
its checks green and its own small commits. The assistant was never handed the
whole project at once — a long unreviewable diff is the failure mode, not a
feature.

**Every diff read before it was committed.** Not skimmed: read. The assistant
writes plausible code quickly, which is precisely why reviewing it is the
bottleneck that must not be skipped.

## What it was good for

- **Scaffolding and boilerplate.** Rails and Vite app setup, serializers,
  controller plumbing, Ant Design form and table wiring — mechanical code where
  the shape is known in advance and reviewing is fast.
- **Brainstorming test cases.** Asking for the edge cases of a median helper or
  a filter object surfaces the empty set, the single element, the even count,
  the unknown sort column. Which cases matter is still a judgement call; the
  list to choose from is cheap to generate.
- **Prose that has to stay consistent.** The same currency rule is explained in
  the requirements, the architecture notes and a dozen code comments. Keeping
  those saying the same thing is work an assistant is genuinely good at.
- **Mechanical refactors** across two languages at once, such as renaming a
  response field in the Ruby serializer, the TypeScript types and the component
  that reads it in one pass.

## What it was not allowed to do

- **Invent expected values in tests.** Every figure in the analytics specs is
  hand-computed from about ten employees and written into the spec as
  arithmetic a reader can verify. A test whose expectations came from running
  the implementation agrees with the implementation's bugs — it records
  behaviour instead of checking it.
- **Guess at numbers.** The endpoint timings in
  [`ARCHITECTURE.md`](ARCHITECTURE.md) were measured against the full seed with
  a documented method, because an assistant will happily produce a
  confident-sounding "~50 ms" that nobody ever measured.
- **Make product decisions.** Never converting currencies, leaving delete out,
  keeping the catalog in code, showing headcount beside every statistic: these
  are decisions with consequences for the HR Manager, recorded in
  `REQUIREMENTS.md` with their reasoning, and not delegated.
- **Write tests nobody asked for.** Tests were added deliberately, where they
  earn their place; the suite is small enough that every spec in it is one
  someone chose to have.

## Where it needed correcting

- **It reaches for the familiar pattern, not the one in the room.** Left alone
  it converts currencies to a common one, adds a soft-delete, pages in the
  browser — all normal, all wrong here. The written rules exist because the
  default is strong and has to be overridden explicitly and repeatedly.
- **Library knowledge is sometimes a version behind.** Suggested APIs had to be
  checked against the versions actually installed rather than trusted.
- **Real bugs surface as confident wrong answers.** The `json` gem pinned in
  the `Gemfile` is one: json 3.0 broke every signed-cookie read through
  `ActiveSupport::JSON.decode`, which presents as a mystifying
  `ArgumentError` on sign-in. Getting from the symptom to the cause took
  reading the actual stack, not asking again differently.
- **Comments drift into narration.** "Set the country code" above
  `country_code = ...` is noise, and it is the default an assistant falls back
  to. Hence the convention written into [`../CLAUDE.md`](../CLAUDE.md):
  comments explain *why*, never *what*, and a comment that restates the line
  below it gets deleted in review.

## What this means for the result

The assistant made the mechanical parts fast, which left more time for the
parts that decide whether the app is any good: what the statistics mean, what
the API refuses to answer, and what the HR Manager sees when they ask a
question the data cannot honestly answer. None of those came from a prompt.
