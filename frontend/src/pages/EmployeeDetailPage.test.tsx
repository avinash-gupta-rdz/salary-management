import { screen } from '@testing-library/react'
import { Route, Routes } from 'react-router-dom'
import EmployeeDetailPage from './EmployeeDetailPage'
import { saveToken } from '../auth/session'
import { EMPLOYEE, mockApi, renderWithProviders } from '../test/utils'

describe('EmployeeDetailPage salary history', () => {
  it('shows each amount in its own currency and no % across currencies', async () => {
    saveToken('token')
    mockApi({
      [`GET /api/v1/employees/${EMPLOYEE.id}`]: () => ({ body: { data: { ...EMPLOYEE, currency: 'USD' } } }),
      [`GET /api/v1/employees/${EMPLOYEE.id}/salary_changes`]: () => ({
        body: {
          data: [
            { id: 2, old_salary: 1_200_000, old_currency: 'INR', new_salary: 90_000, new_currency: 'USD', effective_date: '2026-06-01', reason: 'Relocation', created_at: '' },
            { id: 1, old_salary: 1_000_000, old_currency: 'INR', new_salary: 1_200_000, new_currency: 'INR', effective_date: '2025-04-01', reason: null, created_at: '' },
          ],
        },
      }),
    })

    renderWithProviders(
      <Routes>
        <Route path="/employees/:id" element={<EmployeeDetailPage />} />
      </Routes>,
      { route: `/employees/${EMPLOYEE.id}` },
    )

    expect(await screen.findByText('$90,000')).toBeInTheDocument()
    expect(screen.getByText('Moved INR → USD')).toBeInTheDocument()
    expect(screen.getByText('+20.0%')).toBeInTheDocument()
  })
})
