# Salary Management — Requirements

## Goal

Replace the spreadsheets the HR team uses today with a web app. In it, the HR Manager can maintain salary data for ~10,000 employees across several countries and get reliable answers about how the organisation pays people.

**User:** the HR Manager, the only user and role. They are fluent in Excel. They need to find and fix records quickly, and they need figures they can trust enough to act on.

**Problem today:**

- Finding and updating a record in a large spreadsheet is slow.
- Nothing stops bad data such as typos, missing fields, or wrong currencies.
- Comparing pay across countries and currencies is manual, so the same question gets different answers.

## In scope

**1. Access.** The HR Manager signs in with an email and password. No data can be seen or changed without signing in, because salary data is sensitive.

**2. Employee records.**

- **Each record holds:** employee code, name, email, country, department, job title, level (L1–L6), annual salary, and hire date.
- **Browsing:** search by name, email, or code. Filter by country, department, level, and job title. Sort, and page through the results.
- **Create and update:** validation catches bad data before it is saved. Fields are required, values must come from the known lists, emails are unique, salaries are positive, and hire dates can't be in the future. The salary field shows the currency for the selected country.

**3. Insights.** Each feature answers a question the HR Manager asks:

| Question | Feature |
|---|---|
| Where are our people, and what does each country cost us? | **Pay by country:** one row per country with headcount, total annual payroll, and min, median, average, and max salary, in that country's currency |
| Within a country, how does pay compare across departments, job titles, or levels? What do we pay a given role at each level? | **Pay within a country:** pick a country, then group by department, job title, or level, optionally narrowed by any of them. Each row shows the same figures. |

**Currency rule:** salaries are never converted between currencies. Exchange rates change, so a converted figure would move even when nobody's pay did.

- Every salary figure belongs to one country and is shown in that country's currency.
- Across countries, only headcount is totalled.
- For the same reason, the employee list can only be sorted by salary once it is filtered to one country.
- Every figure appears next to its headcount.

**4. Data.** The app comes with a seed script that creates 10,000 realistic employees and gives the same data on every run.

**Extras worth adding:** a chart next to the within-country table, and CSV export of the filtered employee list.

## Deliberately left out

| Left out | Why |
|---|---|
| Converting salaries between currencies | Rates change, so converted comparisons would mislead. Countries are compared side by side in their own currencies instead. |
| Further analytics (pay outliers, percentile bands, distributions) | The two views above answer the core questions reliably. Outlier rules, such as which peer groups and thresholds to use, should be agreed with HR rather than guessed. |
| More users, roles, permissions; password reset, SSO, MFA | The brief names a single persona who is allowed to see everything. With only one account, its password can be reset from the server. |
| Deleting or offboarding employees | Someone leaving should be recorded (status, end date), not deleted. That needs its own design. |
| Bonus, equity, allowances | Base salary answers the core questions, and each of these has its own rules |
| Editing countries, departments, titles in the app | They rarely change, so they are kept in code. A fixed list of job titles also keeps the analytics clean. |

## Assumptions

- Salary means annual base gross pay, in whole units of local currency.
- Each employee belongs to one country and is paid in that country's currency.
- Job titles come from a fixed list for each department.

## What success looks like

- The HR Manager can find any employee and update their salary in seconds, and invalid data is rejected with a clear message.
- The questions in the Insights table can be answered in the app
- Every figure shows its currency and headcount, and the calculations are tested against hand-worked examples.
