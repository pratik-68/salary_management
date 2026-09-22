// Providers and routes: the whole app, assembled in one place.

import { App as AntApp } from 'antd'
import { QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { createQueryClient } from './api/queryClient'
import AppLayout from './app/AppLayout'
import NotFoundPage from './app/NotFoundPage'
import EmployeesPage from './features/employees/EmployeesPage'
import InsightsPage from './features/insights/InsightsPage'

export default function App() {
  // Held in state rather than at module scope so each mounted app — including
  // each test — starts with an empty cache.
  const [queryClient] = useState(createQueryClient)

  return (
    <QueryClientProvider client={queryClient}>
      {/* Ant Design's App supplies the context its message and modal helpers need. */}
      <AntApp>
        <BrowserRouter>
          <Routes>
            <Route element={<AppLayout />}>
              {/* The employee list is where the work starts, so "/" goes there. */}
              <Route index element={<Navigate to="/employees" replace />} />
              <Route path="employees" element={<EmployeesPage />} />
              <Route path="insights" element={<InsightsPage />} />
              <Route path="*" element={<NotFoundPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AntApp>
    </QueryClientProvider>
  )
}
