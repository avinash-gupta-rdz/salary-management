import { useEffect, useState } from 'react'
import Alert from '@mui/material/Alert'
import Autocomplete from '@mui/material/Autocomplete'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import AddIcon from '@mui/icons-material/Add'
import { DataGrid, type GridColDef, type GridPaginationModel, type GridSortModel } from '@mui/x-data-grid'
import { Link as RouterLink, useNavigate, useSearchParams } from 'react-router-dom'
import { useEmployees, useMeta } from '../api/hooks'
import type { Employee, EmployeeFilters } from '../api/types'
import { formatDate, formatEmploymentType, formatMoney } from '../utils/format'
import { useDebouncedValue } from '../utils/useDebouncedValue'

const PAGE_SIZES = [25, 50, 100]

// Grid column -> API sort key. Salary sorts by the USD equivalent on the server.
const SORT_KEYS: Record<string, string> = {
  full_name: 'full_name',
  hire_date: 'hire_date',
  annual_salary_usd: 'annual_salary',
}
const FIELD_FOR_SORT_KEY = Object.fromEntries(Object.entries(SORT_KEYS).map(([field, key]) => [key, field]))

const FILTER_KEYS = ['country_code', 'department', 'job_title', 'employment_type'] as const

const columns: GridColDef<Employee>[] = [
  { field: 'full_name', headerName: 'Name', flex: 1.2, minWidth: 170 },
  { field: 'job_title', headerName: 'Job title', flex: 1.2, minWidth: 180, sortable: false },
  { field: 'department', headerName: 'Department', flex: 0.8, minWidth: 120, sortable: false },
  { field: 'country_name', headerName: 'Country', flex: 0.8, minWidth: 130, sortable: false },
  {
    field: 'annual_salary',
    headerName: 'Salary (local)',
    flex: 0.9,
    minWidth: 140,
    type: 'number',
    sortable: false,
    renderCell: ({ row }) => formatMoney(row.annual_salary, row.currency),
  },
  {
    field: 'annual_salary_usd',
    headerName: 'Salary (USD)',
    flex: 0.9,
    minWidth: 130,
    type: 'number',
    renderCell: ({ row }) => formatMoney(row.annual_salary_usd, 'USD'),
  },
  {
    field: 'employment_type',
    headerName: 'Type',
    flex: 0.6,
    minWidth: 100,
    sortable: false,
    renderCell: ({ row }) => formatEmploymentType(row.employment_type),
  },
  {
    field: 'hire_date',
    headerName: 'Hire date',
    flex: 0.7,
    minWidth: 120,
    renderCell: ({ row }) => formatDate(row.hire_date),
  },
]

export default function EmployeeListPage() {
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const { data: meta } = useMeta()

  const [searchInput, setSearchInput] = useState(searchParams.get('q') ?? '')
  const debouncedSearch = useDebouncedValue(searchInput)

  const page = Number(searchParams.get('page') ?? 1)
  const perPage = Number(searchParams.get('per_page') ?? PAGE_SIZES[0])
  const sort = searchParams.get('sort') ?? 'full_name'
  const direction = searchParams.get('direction') === 'desc' ? 'desc' : 'asc'

  // Every filter change returns to page 1, otherwise you can land on an empty page.
  function updateParams(changes: Record<string, string | undefined>, resetPage = true) {
    setSearchParams((current) => {
      const next = new URLSearchParams(current)
      Object.entries(changes).forEach(([key, value]) => (value ? next.set(key, value) : next.delete(key)))
      if (resetPage) next.delete('page')
      return next
    })
  }

  // Replace (not push) history so typing doesn't create an entry per keystroke.
  useEffect(() => {
    setSearchParams(
      (current) => {
        if ((current.get('q') ?? '') === debouncedSearch) return current
        const next = new URLSearchParams(current)
        if (debouncedSearch) next.set('q', debouncedSearch)
        else next.delete('q')
        next.delete('page')
        return next
      },
      { replace: true },
    )
  }, [debouncedSearch, setSearchParams])

  const filters: EmployeeFilters = {
    q: searchParams.get('q') ?? undefined,
    ...Object.fromEntries(FILTER_KEYS.map((key) => [key, searchParams.get(key) ?? undefined])),
    sort,
    direction,
    page,
    per_page: perPage,
  }
  const { data, isFetching, error } = useEmployees(filters)

  const paginationModel: GridPaginationModel = { page: page - 1, pageSize: perPage }
  const sortModel: GridSortModel = FIELD_FOR_SORT_KEY[sort] ? [{ field: FIELD_FOR_SORT_KEY[sort], sort: direction }] : []

  function handlePaginationChange(model: GridPaginationModel) {
    updateParams(
      { page: model.page > 0 ? String(model.page + 1) : undefined, per_page: String(model.pageSize) },
      model.pageSize !== perPage,
    )
  }

  function handleSortChange(model: GridSortModel) {
    const item = model[0]
    updateParams({
      sort: item ? SORT_KEYS[item.field] : undefined,
      direction: item?.sort === 'desc' ? 'desc' : undefined,
    })
  }

  const hasFilters = Boolean(filters.q || FILTER_KEYS.some((key) => searchParams.get(key)))

  return (
    <Stack spacing={2}>
      <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 1 }}>
        <Box>
          <Typography variant="h5" component="h1">
            Employees
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {data ? `${data.meta.total.toLocaleString()} ${hasFilters ? 'matching' : 'total'}` : ' '}
          </Typography>
        </Box>
        <Button variant="contained" startIcon={<AddIcon />} component={RouterLink} to="/employees/new">
          Add employee
        </Button>
      </Stack>

      <Paper sx={{ p: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            label="Search name or email"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            size="small"
            sx={{ minWidth: 220, flex: 1 }}
          />
          <TextField
            select
            label="Country"
            value={searchParams.get('country_code') ?? ''}
            onChange={(e) => updateParams({ country_code: e.target.value || undefined })}
            size="small"
            sx={{ minWidth: 160 }}
          >
            <MenuItem value="">All countries</MenuItem>
            {meta?.countries.map((country) => (
              <MenuItem key={country.code} value={country.code}>
                {country.name}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            select
            label="Department"
            value={searchParams.get('department') ?? ''}
            onChange={(e) => updateParams({ department: e.target.value || undefined })}
            size="small"
            sx={{ minWidth: 160 }}
          >
            <MenuItem value="">All departments</MenuItem>
            {meta?.departments.map((department) => (
              <MenuItem key={department} value={department}>
                {department}
              </MenuItem>
            ))}
          </TextField>
          <Autocomplete
            options={meta?.job_titles ?? []}
            value={searchParams.get('job_title')}
            onChange={(_, value) => updateParams({ job_title: value ?? undefined })}
            renderInput={(params) => <TextField {...params} label="Job title" size="small" />}
            sx={{ minWidth: 220 }}
          />
          <TextField
            select
            label="Type"
            value={searchParams.get('employment_type') ?? ''}
            onChange={(e) => updateParams({ employment_type: e.target.value || undefined })}
            size="small"
            sx={{ minWidth: 140 }}
          >
            <MenuItem value="">All types</MenuItem>
            {meta?.employment_types.map((type) => (
              <MenuItem key={type} value={type}>
                {formatEmploymentType(type)}
              </MenuItem>
            ))}
          </TextField>
        </Stack>
      </Paper>

      {error && <Alert severity="error">Could not load employees: {error.message}</Alert>}

      <Paper sx={{ height: 640 }}>
        <DataGrid
          rows={data?.data ?? []}
          columns={columns}
          rowCount={data?.meta.total ?? 0}
          loading={isFetching}
          paginationMode="server"
          sortingMode="server"
          paginationModel={paginationModel}
          onPaginationModelChange={handlePaginationChange}
          sortModel={sortModel}
          onSortModelChange={handleSortChange}
          pageSizeOptions={PAGE_SIZES}
          disableColumnFilter
          disableRowSelectionOnClick
          onRowClick={({ row }) => navigate(`/employees/${row.id}`)}
          sx={{ border: 0, '& .MuiDataGrid-row': { cursor: 'pointer' } }}
        />
      </Paper>
    </Stack>
  )
}
