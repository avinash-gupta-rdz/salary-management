import type { ReactElement } from 'react'
import { render } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter } from 'react-router-dom'
import { vi } from 'vitest'
import { AuthProvider } from '../auth/AuthContext'

export function renderWithProviders(ui: ReactElement, { route = '/' }: { route?: string } = {}) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[route]}>
        <AuthProvider>{ui}</AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

type Handler = (init: RequestInit | undefined) => { status?: number; body?: unknown }

// Routes are matched by "METHOD /path" prefix (query string ignored), e.g. "GET /api/v1/meta".
export function mockApi(routes: Record<string, Handler>) {
  const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input).split('?')[0]
    const key = `${init?.method ?? 'GET'} ${url}`
    const handler = routes[key]
    if (!handler) return new Response(JSON.stringify({ error: `No mock for ${key}` }), { status: 500 })
    const { status = 200, body = {} } = handler(init)
    return new Response(status === 204 ? null : JSON.stringify(body), { status })
  })
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

export const META = {
  countries: [
    { code: 'IN', name: 'India', currency: 'INR' },
    { code: 'US', name: 'United States', currency: 'USD' },
  ],
  departments: ['Engineering', 'Sales'],
  job_titles: ['Software Engineer', 'Account Executive'],
  employment_types: ['full_time', 'part_time', 'contract'],
}

export const EMPLOYEE = {
  id: 7,
  full_name: 'Priya Sharma',
  email: 'priya@acme.test',
  job_title: 'Software Engineer',
  department: 'Engineering',
  country_code: 'IN',
  country_name: 'India',
  currency: 'INR',
  annual_salary: 1_200_000,
  annual_salary_usd: 14_400,
  employment_type: 'full_time',
  hire_date: '2022-04-01',
  updated_at: '2026-10-01T00:00:00Z',
}
