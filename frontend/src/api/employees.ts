// Reading and writing employees.

import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiRequest } from './client'
import type { Employee, EmployeeInput, EmployeeListParams, Envelope, Page } from './types'

export const employeeKeys = {
  all: ['employees'] as const,
  list: (params: EmployeeListParams) => ['employees', 'list', params] as const,
}

export function useEmployees(params: EmployeeListParams) {
  return useQuery({
    queryKey: employeeKeys.list(params),
    queryFn: () => apiRequest<Page<Employee>>('/employees', { params: { ...params } }),
    // Every page of every filter combination is its own cache entry, so going
    // back a page or undoing a filter is instant. Holding the previous page on
    // screen while the next one loads stops the table blinking empty between
    // the two.
    placeholderData: keepPreviousData,
  })
}

export function useCreateEmployee() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: EmployeeInput): Promise<Employee> => {
      const { data } = await apiRequest<Envelope<Employee>>('/employees', {
        method: 'POST',
        body: { employee: input },
      })
      return data
    },
    // Every cached page and filter may now be wrong — a new employee could
    // belong on any of them — so they are all refetched rather than patched.
    onSuccess: () => queryClient.invalidateQueries({ queryKey: employeeKeys.all }),
  })
}

export function useUpdateEmployee() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ id, input }: { id: number; input: EmployeeInput }): Promise<Employee> => {
      const { data } = await apiRequest<Envelope<Employee>>(`/employees/${id}`, {
        method: 'PATCH',
        body: { employee: input },
      })
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: employeeKeys.all }),
  })
}
