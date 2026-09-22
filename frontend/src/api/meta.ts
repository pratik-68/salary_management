// The reference-data catalog: the countries, departments, job titles and
// levels the API will accept. It drives every dropdown in the app.

import { useQuery } from '@tanstack/react-query'
import { apiRequest } from './client'
import type { Envelope, ReferenceData } from './types'

export const referenceDataQueryKey = ['meta'] as const

export function useReferenceData() {
  return useQuery({
    queryKey: referenceDataQueryKey,
    queryFn: async (): Promise<ReferenceData> => {
      const { data } = await apiRequest<Envelope<ReferenceData>>('/meta')
      return data
    },
    // The catalog lives in the backend's source, so it cannot change while the
    // app is open: fetched once, then never again.
    staleTime: Infinity,
    gcTime: Infinity,
  })
}
