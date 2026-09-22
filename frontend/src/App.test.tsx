import { render, screen } from '@testing-library/react'
import { afterEach, expect, test, vi } from 'vitest'
import App from './App'

afterEach(() => {
  vi.restoreAllMocks()
  window.history.pushState({}, '', '/')
})

test('asks for sign-in when the session check comes back unauthorized', async () => {
  stubApi({ signedIn: false })

  render(<App />)

  expect(await screen.findByRole('button', { name: 'Sign in' })).toBeInTheDocument()
})

test('opens on the employee list when signed in', async () => {
  stubApi({ signedIn: true })

  render(<App />)

  expect(await screen.findByRole('heading', { name: 'Employees', level: 3 })).toBeInTheDocument()
})

function stubApi({ signedIn }: { signedIn: boolean }): void {
  vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
    const url = String(input)

    if (url.includes('/session')) {
      return signedIn
        ? json(200, { data: { id: 1, email_address: 'hr@example.com' } })
        : json(401, { error: { code: 'unauthorized', message: 'You must sign in to do that.' } })
    }

    if (url.includes('/meta')) {
      return json(200, { data: { countries: [], departments: [], job_titles: [], levels: [] } })
    }

    return json(200, { data: [], meta: { page: 1, per_page: 25, total: 0 } })
  })
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}
