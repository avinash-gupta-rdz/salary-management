import { ApiError, apiRequest, buildQuery, setUnauthorizedHandler } from './client'
import { mockApi } from '../test/utils'
import { saveToken } from '../auth/session'

describe('buildQuery', () => {
  it('skips empty values', () => {
    expect(buildQuery({ q: '', page: 2, country_code: undefined, sort: 'full_name' })).toBe('?page=2&sort=full_name')
  })

  it('returns an empty string when nothing is set', () => {
    expect(buildQuery({ q: '' })).toBe('')
  })
})

describe('apiRequest', () => {
  it('sends the stored credentials', async () => {
    saveToken('aHI6cGFzc3dvcmQ=')
    const fetchMock = mockApi({ 'GET /api/v1/meta': () => ({ body: { data: {} } }) })

    await apiRequest('/meta')

    const headers = fetchMock.mock.calls[0][1]?.headers as Record<string, string>
    expect(headers.Authorization).toBe('Basic aHI6cGFzc3dvcmQ=')
  })

  it('sends write bodies as JSON (the API rejects anything else)', async () => {
    const fetchMock = mockApi({ 'POST /api/v1/employees': () => ({ status: 201, body: { data: {} } }) })

    await apiRequest('/employees', { method: 'POST', body: { employee: {} } })

    const headers = fetchMock.mock.calls[0][1]?.headers as Record<string, string>
    expect(headers['Content-Type']).toBe('application/json')
  })

  it('throws field errors from a 422', async () => {
    mockApi({ 'POST /api/v1/employees': () => ({ status: 422, body: { errors: { email: ['is invalid'] } } }) })

    const error = (await apiRequest('/employees', { method: 'POST', body: {} }).catch((e) => e)) as ApiError

    expect(error).toBeInstanceOf(ApiError)
    expect(error.status).toBe(422)
    expect(error.fieldErrors).toEqual({ email: ['is invalid'] })
  })

  it('signs out on a 401', async () => {
    const onUnauthorized = vi.fn()
    setUnauthorizedHandler(onUnauthorized)
    mockApi({ 'GET /api/v1/meta': () => ({ status: 401, body: { error: 'Unauthorized' } }) })

    await expect(apiRequest('/meta')).rejects.toThrow('Unauthorized')
    expect(onUnauthorized).toHaveBeenCalled()
  })
})
