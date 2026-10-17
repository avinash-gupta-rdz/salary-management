import { useState, type FormEvent } from 'react'
import Alert from '@mui/material/Alert'
import Autocomplete from '@mui/material/Autocomplete'
import Button from '@mui/material/Button'
import CircularProgress from '@mui/material/CircularProgress'
import Grid from '@mui/material/Grid'
import InputAdornment from '@mui/material/InputAdornment'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import { useEmployee, useMeta, useSaveEmployee } from '../api/hooks'
import type { Employee, EmployeeInput, FieldErrors, Meta } from '../api/types'
import { formatEmploymentType } from '../utils/format'

function toInput(employee?: Employee): EmployeeInput {
  return {
    full_name: employee?.full_name ?? '',
    email: employee?.email ?? '',
    job_title: employee?.job_title ?? '',
    department: employee?.department ?? '',
    country_code: employee?.country_code ?? '',
    annual_salary: employee ? String(employee.annual_salary) : '',
    employment_type: employee?.employment_type ?? 'full_time',
    hire_date: employee?.hire_date ?? '',
    salary_change_reason: '',
    salary_effective_date: '',
  }
}

export default function EmployeeFormPage() {
  const { id } = useParams()
  const { data: employee, isLoading, error } = useEmployee(id)
  const { data: meta } = useMeta()

  if (id && isLoading) return <CircularProgress />
  if (error) return <Alert severity="error">Could not load employee: {error.message}</Alert>
  if (!meta) return <CircularProgress />

  // Keyed so the form state starts fresh from the loaded employee.
  return <EmployeeForm key={employee?.id ?? 'new'} employee={employee} meta={meta} />
}

function EmployeeForm({ employee, meta }: { employee?: Employee; meta: Meta }) {
  const navigate = useNavigate()
  const save = useSaveEmployee(employee?.id)
  const [values, setValues] = useState<EmployeeInput>(() => toInput(employee))
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({})

  const isEdit = employee !== undefined
  const salaryChanged = isEdit && Number(values.annual_salary) !== employee.annual_salary
  const currency = meta.countries.find((country) => country.code === values.country_code)?.currency
  const [today] = useState(() => new Date().toISOString().slice(0, 10))

  function set<K extends keyof EmployeeInput>(field: K, value: EmployeeInput[K]) {
    setValues((current) => ({ ...current, [field]: value }))
  }

  function errorFor(field: string) {
    const messages = fieldErrors[field]
    return messages ? { error: true, helperText: messages.join(', ') } : {}
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setFieldErrors({})
    const payload = { ...values }
    if (!salaryChanged) {
      delete payload.salary_change_reason
      delete payload.salary_effective_date
    }
    try {
      const saved = await save.mutateAsync(payload)
      navigate(`/employees/${saved.id}`)
    } catch (err) {
      if (err instanceof ApiError) setFieldErrors(err.fieldErrors)
    }
  }

  const baseError = save.error && Object.keys(fieldErrors).length === 0 ? save.error.message : null

  return (
    <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3, maxWidth: 900 }} noValidate>
      <Typography variant="h5" component="h1" gutterBottom>
        {isEdit ? `Edit ${employee.full_name}` : 'Add employee'}
      </Typography>

      {Object.keys(fieldErrors).length > 0 && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Please fix the highlighted fields.
        </Alert>
      )}
      {baseError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {baseError}
        </Alert>
      )}

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            label="Full name"
            value={values.full_name}
            onChange={(e) => set('full_name', e.target.value)}
            required
            fullWidth
            {...errorFor('full_name')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            label="Email"
            type="email"
            value={values.email}
            onChange={(e) => set('email', e.target.value)}
            required
            fullWidth
            {...errorFor('email')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <Autocomplete
            freeSolo
            options={meta.job_titles}
            inputValue={values.job_title}
            onInputChange={(_, value) => set('job_title', value)}
            renderInput={(params) => <TextField {...params} label="Job title" required {...errorFor('job_title')} />}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <Autocomplete
            freeSolo
            options={meta.departments}
            inputValue={values.department}
            onInputChange={(_, value) => set('department', value)}
            renderInput={(params) => <TextField {...params} label="Department" required {...errorFor('department')} />}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            select
            label="Country"
            value={values.country_code}
            onChange={(e) => set('country_code', e.target.value)}
            required
            fullWidth
            {...errorFor('country_code')}
            helperText={errorFor('country_code').helperText ?? (currency ? `Paid in ${currency}` : ' ')}
          >
            {meta.countries.map((country) => (
              <MenuItem key={country.code} value={country.code}>
                {country.name}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            label="Annual salary"
            type="number"
            value={values.annual_salary}
            onChange={(e) => set('annual_salary', e.target.value)}
            required
            fullWidth
            {...errorFor('annual_salary')}
            slotProps={{
              htmlInput: { min: 1, step: 1000 },
              input: { startAdornment: <InputAdornment position="start">{currency ?? '—'}</InputAdornment> },
            }}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            select
            label="Employment type"
            value={values.employment_type}
            onChange={(e) => set('employment_type', e.target.value as EmployeeInput['employment_type'])}
            required
            fullWidth
            {...errorFor('employment_type')}
          >
            {meta.employment_types.map((type) => (
              <MenuItem key={type} value={type}>
                {formatEmploymentType(type)}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            label="Hire date"
            type="date"
            value={values.hire_date}
            onChange={(e) => set('hire_date', e.target.value)}
            required
            fullWidth
            {...errorFor('hire_date')}
            slotProps={{ inputLabel: { shrink: true }, htmlInput: { max: today } }}
          />
        </Grid>

        {salaryChanged && (
          <>
            <Grid size={12}>
              <Alert severity="info">This salary change will be saved in the employee's salary history.</Alert>
            </Grid>
            <Grid size={{ xs: 12, sm: 8 }}>
              <TextField
                label="Reason for change"
                placeholder="e.g. Annual review, Promotion"
                value={values.salary_change_reason}
                onChange={(e) => set('salary_change_reason', e.target.value)}
                fullWidth
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField
                label="Effective date"
                type="date"
                value={values.salary_effective_date}
                onChange={(e) => set('salary_effective_date', e.target.value)}
                fullWidth
                helperText="Defaults to today"
                slotProps={{ inputLabel: { shrink: true } }}
              />
            </Grid>
          </>
        )}
      </Grid>

      <Stack direction="row" spacing={1} sx={{ mt: 3 }}>
        <Button type="submit" variant="contained" disabled={save.isPending}>
          {save.isPending ? 'Saving…' : isEdit ? 'Save changes' : 'Add employee'}
        </Button>
        <Button component={RouterLink} to={isEdit ? `/employees/${employee.id}` : '/employees'}>
          Cancel
        </Button>
      </Stack>
    </Paper>
  )
}
