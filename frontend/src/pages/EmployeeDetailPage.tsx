import { useState } from 'react'
import Alert from '@mui/material/Alert'
import Button from '@mui/material/Button'
import CircularProgress from '@mui/material/CircularProgress'
import Dialog from '@mui/material/Dialog'
import DialogActions from '@mui/material/DialogActions'
import DialogContent from '@mui/material/DialogContent'
import DialogContentText from '@mui/material/DialogContentText'
import DialogTitle from '@mui/material/DialogTitle'
import Grid from '@mui/material/Grid'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import Typography from '@mui/material/Typography'
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom'
import { useDeleteEmployee, useEmployee, useSalaryChanges } from '../api/hooks'
import type { Employee } from '../api/types'
import { formatDate, formatEmploymentType, formatMoney } from '../utils/format'

export default function EmployeeDetailPage() {
  const { id } = useParams()
  const { data: employee, isLoading, error } = useEmployee(id)

  if (isLoading) return <CircularProgress />
  if (error || !employee) return <Alert severity="error">Could not load employee{error && `: ${error.message}`}</Alert>

  return (
    <Stack spacing={2} sx={{ maxWidth: 1000 }}>
      <EmployeeDetails employee={employee} />
      <SalaryHistory employee={employee} />
    </Stack>
  )
}

function EmployeeDetails({ employee }: { employee: Employee }) {
  const navigate = useNavigate()
  const deleteEmployee = useDeleteEmployee()
  const [confirmOpen, setConfirmOpen] = useState(false)

  async function handleDelete() {
    await deleteEmployee.mutateAsync(employee.id)
    navigate('/employees')
  }

  const fields: [string, string][] = [
    ['Email', employee.email],
    ['Job title', employee.job_title],
    ['Department', employee.department],
    ['Country', employee.country_name ?? employee.country_code],
    ['Employment type', formatEmploymentType(employee.employment_type)],
    ['Hire date', formatDate(employee.hire_date)],
    ['Annual salary', formatMoney(employee.annual_salary, employee.currency)],
    ['Annual salary (USD)', formatMoney(employee.annual_salary_usd, 'USD')],
  ]

  return (
    <Paper sx={{ p: 3 }}>
      <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'flex-start', mb: 2, gap: 1, flexWrap: 'wrap' }}>
        <div>
          <Button component={RouterLink} to="/employees" size="small" sx={{ ml: -1 }}>
            ← All employees
          </Button>
          <Typography variant="h5" component="h1">
            {employee.full_name}
          </Typography>
        </div>
        <Stack direction="row" spacing={1}>
          <Button variant="contained" component={RouterLink} to={`/employees/${employee.id}/edit`}>
            Edit
          </Button>
          <Button color="error" onClick={() => setConfirmOpen(true)}>
            Delete
          </Button>
        </Stack>
      </Stack>

      <Grid container spacing={2}>
        {fields.map(([label, value]) => (
          <Grid key={label} size={{ xs: 12, sm: 6, md: 3 }}>
            <Typography variant="caption" color="text.secondary">
              {label}
            </Typography>
            <Typography>{value}</Typography>
          </Grid>
        ))}
      </Grid>

      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)}>
        <DialogTitle>Delete {employee.full_name}?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            This permanently removes the employee and their salary history.
          </DialogContentText>
          {deleteEmployee.error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {deleteEmployee.error.message}
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmOpen(false)}>Cancel</Button>
          <Button color="error" variant="contained" onClick={handleDelete} disabled={deleteEmployee.isPending}>
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Paper>
  )
}

function SalaryHistory({ employee }: { employee: Employee }) {
  const { data: changes, isLoading, error } = useSalaryChanges(String(employee.id))

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" component="h2" gutterBottom>
        Salary history
      </Typography>
      {isLoading && <CircularProgress size={24} />}
      {error && <Alert severity="error">Could not load salary history: {error.message}</Alert>}
      {changes && changes.length === 0 && (
        <Typography color="text.secondary">No salary changes recorded yet.</Typography>
      )}
      {changes && changes.length > 0 && (
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Effective date</TableCell>
              <TableCell align="right">From</TableCell>
              <TableCell align="right">To</TableCell>
              <TableCell align="right">Change</TableCell>
              <TableCell>Reason</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {changes.map((change) => {
              const percent = ((change.new_salary - change.old_salary) / change.old_salary) * 100
              return (
                <TableRow key={change.id}>
                  <TableCell>{formatDate(change.effective_date)}</TableCell>
                  <TableCell align="right">{formatMoney(change.old_salary, change.currency)}</TableCell>
                  <TableCell align="right">{formatMoney(change.new_salary, change.currency)}</TableCell>
                  <TableCell align="right" sx={{ color: percent >= 0 ? 'success.main' : 'error.main' }}>
                    {percent >= 0 ? '+' : ''}
                    {percent.toFixed(1)}%
                  </TableCell>
                  <TableCell>{change.reason ?? '—'}</TableCell>
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      )}
    </Paper>
  )
}
