// Reading the employee list.

import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { apiRequest } from './client'
import type { Employee, EmployeeListParams, Page } from './types'

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
