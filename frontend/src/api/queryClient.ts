// How the app caches and when it gives up.

import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query'
import { ApiError } from './client'
import { sessionQueryKey } from './session'

export function createQueryClient(): QueryClient {
  const queryClient: QueryClient = new QueryClient({
    // A session can end while the app is open, and then every request starts
    // coming back 401. Forgetting the cached user in one place turns that into
    // a trip to the login page, rather than a screen of failed panels the user
    // has to work out for themselves.
    queryCache: new QueryCache({ onError: (error) => forgetSessionIfUnauthorized(error, queryClient) }),
    mutationCache: new MutationCache({ onError: (error) => forgetSessionIfUnauthorized(error, queryClient) }),
    defaultOptions: {
      queries: {
        // One person uses this app, so data only changes when they change it.
        refetchOnWindowFocus: false,
        staleTime: 30_000,
        // An answer the API gave deliberately — 401, 400, 404 — will be the
        // same next time; retrying only delays the message. Anything else is
        // a network hiccup and worth one more go.
        retry: (failureCount, error) => !(error instanceof ApiError) && failureCount < 1,
      },
    },
  })

  return queryClient
}

function forgetSessionIfUnauthorized(error: unknown, queryClient: QueryClient): void {
  if (error instanceof ApiError && error.isUnauthorized) {
    queryClient.setQueryData(sessionQueryKey, null)
  }
}
