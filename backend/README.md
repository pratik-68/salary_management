# Backend

The API: Rails 8 in API-only mode, SQLite, RSpec. It serves JSON under
`/api/v1` to the SPA in [`../frontend`](../frontend) and owns every rule about
what the data means.

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed        # 10,000 employees + the HR Manager account
bin/rails server         # http://localhost:3000
```

`SEED_EMPLOYEE_COUNT=200 bin/rails db:seed` gives a smaller set to work
against. Seeding is deterministic and idempotent: it empties the table first,
so the same rows come back every time.

## Layout

| Path | What lives there |
|---|---|
| `app/models/employee.rb` | The record and every validation on it |
| `app/models/reference_data.rb` | The catalog from `config/reference_data.yml`: countries → currency, departments → job titles, levels |
| `app/queries/employee_filter.rb` | Filters, search and the sort allow-list, shared by the list and the analytics |
| `app/services/analytics/` | `Breakdown` (the pay statistics) and `Median` |
| `app/serializers/` | Plain objects that decide the JSON shapes |
| `app/controllers/concerns/` | `Authentication` (sign-in required by default) and `ErrorResponses` (one error shape) |
| `lib/seeds/` | The deterministic employee generator behind `db/seeds.rb` |

Two rules are enforced here rather than trusted to the client, because
salaries are never converted: grouping by anything other than country needs a
country filter, and so does sorting the employee list by salary. Both come back
as `400 country_required`.

## Checks

```bash
bundle exec rspec
bundle exec rubocop
```

[`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) has the API contract, the
decisions behind it, and measured endpoint timings.
