// Signing in, signing out, and knowing who is signed in.
//
// The session lives in React Query's cache under one key, so the route guard,
// the header and the login page all read the same answer, and signing in
// updates every one of them.

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { ApiError, apiRequest } from './client'
import type { Envelope, User } from './types'

export const sessionQueryKey = ['session'] as const

export interface Credentials {
  email_address: string
  password: string
}

/**
 * The current user, or null when nobody is signed in.
 *
 * A 401 here is the expected answer to "am I signed in?", not a failure, so it
 * becomes null rather than an error state every caller would have to unpick.
 */
async function fetchSession(): Promise<User | null> {
  try {
    const { data } = await apiRequest<Envelope<User>>('/session')
    return data
  } catch (error) {
    if (error instanceof ApiError && error.isUnauthorized) {
      return null
    }

    throw error
  }
}

export function useSession() {
  return useQuery({
    queryKey: sessionQueryKey,
    queryFn: fetchSession,
    // Who is signed in only changes through this app, which updates the cache
    // itself, so there is nothing to poll for.
    staleTime: Infinity,
    retry: false,
  })
}

export function useSignIn() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (credentials: Credentials): Promise<User> => {
      const { data } = await apiRequest<Envelope<User>>('/session', {
        method: 'POST',
        body: credentials,
      })
      return data
    },
    // Writing the user straight into the cache saves a second round trip, and
    // the guard re-renders onto the page the user was heading for.
    onSuccess: (user) => queryClient.setQueryData(sessionQueryKey, user),
  })
}

export function useSignOut() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: () => apiRequest<void>('/session', { method: 'DELETE' }),
    onSuccess: () => {
      // Everything, not only the session: the cached employees and pay figures
      // belong to the account that has just signed out.
      queryClient.clear()
      queryClient.setQueryData(sessionQueryKey, null)
    },
  })
}
