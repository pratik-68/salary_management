// The employee list's state lives in the URL, not in React.
//
// Filters, sort, and page are what someone means by "the view I'm looking at",
// so they belong somewhere that can be bookmarked, shared with a colleague,
// and stepped back through with the browser's back button.

import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import type { EmployeeListParams } from '../../api/types'

export const DEFAULT_SORT = 'employee_code'
export const DEFAULT_DIRECTION = 'asc'
export const DEFAULT_PER_PAGE = 25

/** Sorts the API allows only inside one country, since salaries are never converted. */
const COUNTRY_SCOPED_SORTS = ['annual_salary']

export function useEmployeeListParams() {
  const [searchParams, setSearchParams] = useSearchParams()

  const params = useMemo<EmployeeListParams>(() => {
    const country = trimmed(searchParams.get('country'))
    const sort = searchParams.get('sort') ?? DEFAULT_SORT

    return {
      q: trimmed(searchParams.get('q')),
      country,
      department: trimmed(searchParams.get('department')),
      job_title: trimmed(searchParams.get('job_title')),
      level: trimmed(searchParams.get('level')),
      // A hand-edited URL can ask for a salary sort with no country. The API
      // would refuse it, so fall back to the default rather than sending a
      // request that is going to fail.
      sort: COUNTRY_SCOPED_SORTS.includes(sort) && !country ? DEFAULT_SORT : sort,
      direction: searchParams.get('direction') === 'desc' ? 'desc' : DEFAULT_DIRECTION,
      page: positiveInteger(searchParams.get('page')) ?? 1,
      per_page: positiveInteger(searchParams.get('per_page')) ?? DEFAULT_PER_PAGE,
    }
  }, [searchParams])

  const update = useCallback(
    (patch: Partial<EmployeeListParams>) => {
      setSearchParams((current) => {
        const next = new URLSearchParams(current)

        for (const [key, value] of Object.entries(patch)) {
          if (value === undefined || value === null || value === '') {
            next.delete(key)
          } else {
            next.set(key, String(value))
          }
        }

        // Any change but the page itself returns to the first page: page 7 of
        // one filter is not a place the next filter has.
        if (patch.page === undefined) {
          next.delete('page')
        }

        // Salaries are never converted, so ordering by salary across
        // currencies would rank 90,000 USD below 2,400,000 INR. The API
        // refuses it; clearing the country clears the sort with it.
        if (COUNTRY_SCOPED_SORTS.includes(next.get('sort') ?? '') && !next.get('country')) {
          next.delete('sort')
          next.delete('direction')
        }

        return dropDefaults(next)
      })
    },
    [setSearchParams],
  )

  return { params, update }
}

// A shared URL should carry what was chosen and nothing else, so the defaults
// come out again after every change.
function dropDefaults(params: URLSearchParams): URLSearchParams {
  const defaults: Record<string, string> = {
    sort: DEFAULT_SORT,
    direction: DEFAULT_DIRECTION,
    page: '1',
    per_page: String(DEFAULT_PER_PAGE),
  }

  for (const [key, value] of Object.entries(defaults)) {
    if (params.get(key) === value) {
      params.delete(key)
    }
  }

  return params
}

function trimmed(value: string | null): string | undefined {
  return value?.trim() || undefined
}

function positiveInteger(value: string | null): number | undefined {
  const parsed = Number(value)
  return Number.isInteger(parsed) && parsed > 0 ? parsed : undefined
}
