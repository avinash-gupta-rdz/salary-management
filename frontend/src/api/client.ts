import { getToken } from '../auth/session'
import type { FieldErrors } from './types'

export class ApiError extends Error {
  readonly status: number
  readonly fieldErrors: FieldErrors

  constructor(status: number, message: string, fieldErrors: FieldErrors = {}) {
    super(message)
    this.status = status
    this.fieldErrors = fieldErrors
  }
}

let onUnauthorized: () => void = () => {}

export function setUnauthorizedHandler(handler: () => void): void {
  onUnauthorized = handler
}

type Params = Record<string, string | number | undefined>

export function buildQuery(params: Params = {}): string {
  const search = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== '') search.set(key, String(value))
  })
  const query = search.toString()
  return query ? `?${query}` : ''
}

export async function apiRequest<T>(
  path: string,
  { method = 'GET', body, token = getToken() }: { method?: string; body?: unknown; token?: string | null } = {},
): Promise<T> {
  const response = await fetch(`/api/v1${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      // Tells Rails to answer 401 with JSON instead of the browser's login popup.
      'X-Requested-With': 'XMLHttpRequest',
      ...(body !== undefined && { 'Content-Type': 'application/json' }),
      ...(token && { Authorization: `Basic ${token}` }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  if (response.status === 204) return undefined as T

  const payload = await response.json().catch(() => ({}))

  if (!response.ok) {
    if (response.status === 401) onUnauthorized()
    throw new ApiError(response.status, payload.error ?? `Request failed (${response.status})`, payload.errors)
  }

  return payload as T
}
