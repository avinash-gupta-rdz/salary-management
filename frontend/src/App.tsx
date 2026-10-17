import { lazy, Suspense } from 'react'
import CircularProgress from '@mui/material/CircularProgress'
import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './auth/useAuth'
import Layout from './components/Layout'
import EmployeeDetailPage from './pages/EmployeeDetailPage'
import EmployeeFormPage from './pages/EmployeeFormPage'
import EmployeeListPage from './pages/EmployeeListPage'
import LoginPage from './pages/LoginPage'

// Charts are the heaviest dependency; load them only when Insights is opened.
const InsightsPage = lazy(() => import('./pages/InsightsPage'))

function App() {
  const { isAuthenticated } = useAuth()

  if (!isAuthenticated) return <LoginPage />

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/employees" replace />} />
        <Route path="employees" element={<EmployeeListPage />} />
        <Route path="employees/new" element={<EmployeeFormPage />} />
        <Route path="employees/:id" element={<EmployeeDetailPage />} />
        <Route path="employees/:id/edit" element={<EmployeeFormPage />} />
        <Route
          path="insights"
          element={
            <Suspense fallback={<CircularProgress />}>
              <InsightsPage />
            </Suspense>
          }
        />
        <Route path="*" element={<Navigate to="/employees" replace />} />
      </Route>
    </Routes>
  )
}

export default App
