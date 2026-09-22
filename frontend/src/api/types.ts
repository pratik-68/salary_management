// The shapes the API sends back.
//
// Every successful response is wrapped: `{ data }` for one thing, `{ data,
// meta }` where there are counts or a currency to carry alongside the rows.
// Unwrapping happens in the hooks, so components only ever see the payload.
//
// Field names stay in the API's snake_case rather than being mapped to
// camelCase. A mapping layer is one more place for a field to go missing, and
// forms post back the same names the server validates.

export interface Envelope<T> {
  data: T
}

/** The signed-in HR Manager. There is a single role, so there is nothing else to carry. */
export interface User {
  id: number
  email_address: string
}

export interface PageMeta {
  page: number
  per_page: number
  total: number
}

export interface Page<T> {
  data: T[]
  meta: PageMeta
}

/**
 * An employee as the API sends them.
 *
 * `country_name` and `currency` are not stored on the record: the API derives
 * them from the country so that every salary arrives already labelled, rather
 * than each screen having to look the currency up for itself.
 */
export interface Employee {
  id: number
  employee_code: string
  first_name: string
  last_name: string
  full_name: string
  email: string
  country_code: string
  country_name: string | null
  currency: string | null
  department: string
  job_title: string
  level: string
  annual_salary: number
  hire_date: string
}

export type SortDirection = 'asc' | 'desc'

/**
 * Everything that decides which employees are on screen. It is the API's query
 * string, the React Query cache key and the app's own URL, all one object, so
 * a view can be bookmarked and shared and comes back exactly as it was.
 */
export interface EmployeeListParams {
  q?: string
  country?: string
  department?: string
  job_title?: string
  level?: string
  sort: string
  direction: SortDirection
  page: number
  per_page: number
}

/** The catalog behind every dropdown: what the API will accept. */
export interface Country {
  code: string
  name: string
  currency: string
}

export interface DepartmentCatalog {
  name: string
  job_titles: string[]
}

export interface ReferenceData {
  countries: Country[]
  departments: DepartmentCatalog[]
  job_titles: string[]
  levels: string[]
}

/**
 * What the API accepts when creating or updating an employee.
 *
 * No currency: it is derived from the country, so sending it would let the two
 * disagree. The API ignores it for the same reason.
 */
export interface EmployeeInput {
  employee_code: string
  first_name: string
  last_name: string
  email: string
  country_code: string
  department: string
  job_title: string
  level: string
  annual_salary: number
  hire_date: string
}
