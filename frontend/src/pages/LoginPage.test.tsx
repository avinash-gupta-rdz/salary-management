import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import App from '../App'
import { META, mockApi, renderWithProviders } from '../test/utils'

async function signIn(password: string) {
  const user = userEvent.setup()
  await user.type(screen.getByLabelText(/username/i), 'hr')
  await user.type(screen.getByLabelText(/password/i), password)
  await user.click(screen.getByRole('button', { name: /sign in/i }))
}

describe('Login', () => {
  it('shows an error for wrong credentials', async () => {
    mockApi({ 'GET /api/v1/meta': () => ({ status: 401, body: { error: 'Unauthorized' } }) })
    renderWithProviders(<App />)

    await signIn('wrong')

    expect(await screen.findByText('Wrong username or password')).toBeInTheDocument()
  })

  it('opens the app after a successful sign in', async () => {
    mockApi({
      'GET /api/v1/meta': () => ({ body: { data: META } }),
      'GET /api/v1/employees': () => ({ body: { data: [], meta: { page: 1, per_page: 25, total: 0, total_pages: 0 } } }),
    })
    renderWithProviders(<App />)

    await signIn('password')

    expect(await screen.findByRole('button', { name: /sign out/i })).toBeInTheDocument()
    expect(await screen.findByRole('heading', { name: 'Employees' })).toBeInTheDocument()
  })
})
