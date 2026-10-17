import { screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes } from 'react-router-dom'
import EmployeeFormPage from './EmployeeFormPage'
import { saveToken } from '../auth/session'
import { EMPLOYEE, META, mockApi, renderWithProviders } from '../test/utils'

function renderEditPage() {
  saveToken('token')
  return renderWithProviders(
    <Routes>
      <Route path="/employees/:id/edit" element={<EmployeeFormPage />} />
      <Route path="/employees/:id" element={<p>Detail page</p>} />
    </Routes>,
    { route: `/employees/${EMPLOYEE.id}/edit` },
  )
}

describe('EmployeeFormPage', () => {
  it('asks for a reason only when the salary changes', async () => {
    mockApi({
      'GET /api/v1/meta': () => ({ body: { data: META } }),
      [`GET /api/v1/employees/${EMPLOYEE.id}`]: () => ({ body: { data: EMPLOYEE } }),
    })
    renderEditPage()
    const salary = await screen.findByLabelText(/annual salary/i)

    expect(screen.queryByLabelText(/reason for change/i)).not.toBeInTheDocument()

    await userEvent.clear(salary)
    await userEvent.type(salary, '1300000')

    expect(screen.getByLabelText(/reason for change/i)).toBeInTheDocument()
  })

  it('sends the salary change reason and opens the detail page on success', async () => {
    const fetchMock = mockApi({
      'GET /api/v1/meta': () => ({ body: { data: META } }),
      [`GET /api/v1/employees/${EMPLOYEE.id}`]: () => ({ body: { data: EMPLOYEE } }),
      [`PATCH /api/v1/employees/${EMPLOYEE.id}`]: () => ({ body: { data: { ...EMPLOYEE, annual_salary: 1_300_000 } } }),
    })
    renderEditPage()
    const salary = await screen.findByLabelText(/annual salary/i)

    await userEvent.clear(salary)
    await userEvent.type(salary, '1300000')
    await userEvent.type(screen.getByLabelText(/reason for change/i), 'Promotion')
    await userEvent.click(screen.getByRole('button', { name: /save changes/i }))

    expect(await screen.findByText('Detail page')).toBeInTheDocument()
    const patch = fetchMock.mock.calls.find(([, init]) => init?.method === 'PATCH')
    expect(JSON.parse(String(patch?.[1]?.body)).employee).toMatchObject({
      annual_salary: '1300000',
      salary_change_reason: 'Promotion',
    })
  })

  it('shows server validation errors next to the fields', async () => {
    mockApi({
      'GET /api/v1/meta': () => ({ body: { data: META } }),
      [`GET /api/v1/employees/${EMPLOYEE.id}`]: () => ({ body: { data: EMPLOYEE } }),
      [`PATCH /api/v1/employees/${EMPLOYEE.id}`]: () => ({
        status: 422,
        body: { errors: { email: ['has already been taken'] } },
      }),
    })
    renderEditPage()

    await userEvent.click(await screen.findByRole('button', { name: /save changes/i }))

    expect(await screen.findByText('Please fix the highlighted fields.')).toBeInTheDocument()
    const emailField = screen.getByLabelText(/email/i).closest('.MuiFormControl-root') as HTMLElement
    expect(within(emailField).getByText('has already been taken')).toBeInTheDocument()
  })
})
