import { render, screen } from '@testing-library/react'
import { afterEach, expect, test, vi } from 'vitest'
import App from './App'

afterEach(() => {
  vi.restoreAllMocks()
  window.history.pushState({}, '', '/')
})

test('opens on the employee list', async () => {
  signedIn()

  render(<App />)

  expect(await screen.findByRole('heading', { name: 'Employees', level: 3 })).toBeInTheDocument()
})

function signedIn(): void {
  vi.spyOn(globalThis, 'fetch').mockResolvedValue(
    new Response(JSON.stringify({ data: { id: 1, email_address: 'hr@example.com' } }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    }),
  )
}
