import { render, screen } from '@testing-library/react'
import { afterEach, expect, test, vi } from 'vitest'
import App from './App'

afterEach(() => {
  vi.restoreAllMocks()
  window.history.pushState({}, '', '/')
})

test('asks for sign-in when the session check comes back unauthorized', async () => {
  stubSession(
    401,
    { error: { code: 'unauthorized', message: 'You must sign in to do that.' } },
  )

  render(<App />)

  expect(await screen.findByRole('button', { name: 'Sign in' })).toBeInTheDocument()
})

test('opens on the employee list when signed in', async () => {
  stubSession(200, { data: { id: 1, email_address: 'hr@example.com' } })

  render(<App />)

  expect(await screen.findByRole('heading', { name: 'Employees', level: 3 })).toBeInTheDocument()
})

function stubSession(status: number, body: unknown): void {
  vi.spyOn(globalThis, 'fetch').mockResolvedValue(
    new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }),
  )
}
