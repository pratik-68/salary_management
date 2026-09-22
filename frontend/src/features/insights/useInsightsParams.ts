// The insights view lives in the URL, as the employee list does.
//
// "India, by level, Software Engineers only" is a question someone asks again
// next quarter or sends to a colleague, so it has to survive a bookmark and
// the back button rather than sitting in React state.

import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import type { BreakdownGroupBy } from '../../api/types'

/** The two insight views. */
export const VIEWS = ['country', 'within'] as const
export type InsightsView = (typeof VIEWS)[number]

/**
 * What pay can be grouped by inside one country. `country` is missing on
 * purpose: it is the other view, and grouping countries within a country is
 * one row.
 */
export const WITHIN_GROUPS = ['department', 'job_title', 'level'] as const
export type WithinGroupBy = Extract<BreakdownGroupBy, (typeof WITHIN_GROUPS)[number]>

export const GROUP_LABELS: Record<WithinGroupBy, string> = {
  department: 'Department',
  job_title: 'Job title',
  level: 'Level',
}

const DEFAULT_VIEW: InsightsView = 'country'
const DEFAULT_GROUP_BY: WithinGroupBy = 'department'

export interface InsightsParams {
  view: InsightsView
  /** The country the within-country view is about; nothing is shown until one is chosen. */
  country?: string
  group_by: WithinGroupBy
  department?: string
  job_title?: string
  level?: string
}

export function useInsightsParams() {
  const [searchParams, setSearchParams] = useSearchParams()

  const params = useMemo<InsightsParams>(
    () => ({
      // A hand-edited URL can name a view or a grouping that does not exist.
      // Falling back to the default shows something sensible rather than an
      // empty page or a request the API is going to refuse.
      view: oneOf(searchParams.get('view'), VIEWS) ?? DEFAULT_VIEW,
      country: trimmed(searchParams.get('country'))?.toUpperCase(),
      group_by: oneOf(searchParams.get('group_by'), WITHIN_GROUPS) ?? DEFAULT_GROUP_BY,
      department: trimmed(searchParams.get('department')),
      job_title: trimmed(searchParams.get('job_title')),
      level: trimmed(searchParams.get('level')),
    }),
    [searchParams],
  )

  const update = useCallback(
    (patch: Partial<InsightsParams>) => {
      setSearchParams((current) => {
        const next = new URLSearchParams(current)

        for (const [key, value] of Object.entries(patch)) {
          if (value === undefined || value === null || value === '') {
            next.delete(key)
          } else {
            next.set(key, String(value))
          }
        }

        return dropDefaults(next)
      })
    },
    [setSearchParams],
  )

  return { params, update }
}

// A shared URL should carry the question that was asked and nothing else.
function dropDefaults(params: URLSearchParams): URLSearchParams {
  const defaults: Record<string, string> = { view: DEFAULT_VIEW, group_by: DEFAULT_GROUP_BY }

  for (const [key, value] of Object.entries(defaults)) {
    if (params.get(key) === value) {
      params.delete(key)
    }
  }

  return params
}

function oneOf<T extends string>(value: string | null, allowed: readonly T[]): T | undefined {
  return allowed.find((candidate) => candidate === value)
}

function trimmed(value: string | null): string | undefined {
  return value?.trim() || undefined
}
