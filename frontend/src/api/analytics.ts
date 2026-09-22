// Pay statistics. Both insight views come from this one endpoint: group by
// country to see what each country costs, or pick a country and group by
// something inside it to see how pay varies there.

import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { apiRequest } from './client'
import type { Breakdown, BreakdownParams } from './types'

export const breakdownKeys = {
  all: ['breakdown'] as const,
  one: (params: BreakdownParams) => ['breakdown', params] as const,
}

export function useBreakdown(params: BreakdownParams, options: { enabled?: boolean } = {}) {
  return useQuery({
    queryKey: breakdownKeys.one(params),
    queryFn: () => apiRequest<Breakdown>('/analytics/breakdown', { params: { ...params } }),
    // The caller switches this off while the request would be refused — a
    // grouping that needs a country, before one has been picked.
    enabled: options.enabled ?? true,
    // Changing the grouping keeps the previous figures on screen rather than
    // emptying the table and the chart under the toggle that was just used.
    placeholderData: keepPreviousData,
  })
}
