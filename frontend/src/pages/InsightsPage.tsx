import { useState, type ReactNode } from 'react'
import Alert from '@mui/material/Alert'
import Autocomplete from '@mui/material/Autocomplete'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import CircularProgress from '@mui/material/CircularProgress'
import Grid from '@mui/material/Grid'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import { BarChart } from '@mui/x-charts/BarChart'
import { useBreakdown, useCountryStats, useDistribution, useMeta, useSummary } from '../api/hooks'
import { formatCompactMoney, formatMoney, formatNumber } from '../utils/format'

export default function InsightsPage() {
  const { data: meta } = useMeta()
  const [countryCode, setCountryCode] = useState('')
  const [jobTitle, setJobTitle] = useState<string | null>(null)
  const scopeLabel = meta?.countries.find((c) => c.code === countryCode)?.name ?? 'All countries'

  return (
    <Stack spacing={3}>
      <div>
        <Typography variant="h5" component="h1">
          Salary insights
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Figures for one country are in its local currency. Figures across countries are converted to USD at fixed rates.
        </Typography>
      </div>

      <SummaryCards />
      <CountrySection />

      <Paper sx={{ p: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ alignItems: { sm: 'center' } }}>
          <Typography variant="h6" component="h2" sx={{ flexGrow: 1 }}>
            Breakdown: {scopeLabel}
          </Typography>
          <TextField
            select
            label="Country"
            value={countryCode}
            onChange={(e) => setCountryCode(e.target.value)}
            size="small"
            sx={{ minWidth: 200 }}
          >
            <MenuItem value="">All countries (USD)</MenuItem>
            {meta?.countries.map((country) => (
              <MenuItem key={country.code} value={country.code}>
                {country.name} ({country.currency})
              </MenuItem>
            ))}
          </TextField>
        </Stack>
      </Paper>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 6 }}>
          <DepartmentChart countryCode={countryCode} />
        </Grid>
        <Grid size={{ xs: 12, lg: 6 }}>
          <DistributionChart
            countryCode={countryCode}
            jobTitle={jobTitle}
            jobTitles={meta?.job_titles ?? []}
            onJobTitleChange={setJobTitle}
          />
        </Grid>
        <Grid size={12}>
          <JobTitleTable countryCode={countryCode} />
        </Grid>
      </Grid>
    </Stack>
  )
}

function Section({ title, subtitle, action, children }: { title: string; subtitle?: string; action?: ReactNode; children: ReactNode }) {
  return (
    <Paper sx={{ p: 2, height: '100%' }}>
      <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'flex-start', mb: 1, gap: 2, flexWrap: 'wrap' }}>
        <div>
          <Typography variant="h6" component="h2">
            {title}
          </Typography>
          {subtitle && (
            <Typography variant="body2" color="text.secondary">
              {subtitle}
            </Typography>
          )}
        </div>
        {action}
      </Stack>
      {children}
    </Paper>
  )
}

function QueryState({ isLoading, error }: { isLoading: boolean; error: Error | null }) {
  if (isLoading) return <CircularProgress size={28} />
  if (error) return <Alert severity="error">Could not load: {error.message}</Alert>
  return null
}

function SummaryCards() {
  const { data, isLoading, error } = useSummary()
  if (!data) return <QueryState isLoading={isLoading} error={error} />

  const cards = [
    { label: 'Employees', value: formatNumber(data.headcount) },
    { label: 'Annual payroll (USD)', value: formatCompactMoney(data.total_payroll_usd, 'USD') },
    { label: 'Average salary (USD)', value: formatMoney(data.average_salary_usd, 'USD') },
    { label: 'Median salary (USD)', value: formatMoney(data.median_salary_usd, 'USD') },
    { label: 'Countries', value: formatNumber(data.countries) },
  ]

  return (
    <Grid container spacing={2}>
      {cards.map((card) => (
        <Grid key={card.label} size={{ xs: 6, md: 'grow' }}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="body2" color="text.secondary">
                {card.label}
              </Typography>
              <Typography variant="h5" component="p">
                {card.value}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  )
}

function CountrySection() {
  const { data, isLoading, error } = useCountryStats()

  return (
    <Section title="Pay by country" subtitle="Local currency per country; USD columns compare countries.">
      {!data ? (
        <QueryState isLoading={isLoading} error={error} />
      ) : (
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, lg: 5 }}>
            <BarChart
              height={330}
              xAxis={[
                {
                  scaleType: 'band',
                  data: data.map((row) => row.country_name ?? row.country_code),
                  // Show every country; angled so long names like "United Kingdom" don't get dropped.
                  tickLabelInterval: () => true,
                  tickLabelStyle: { angle: -30, textAnchor: 'end', fontSize: 12 },
                  height: 80,
                },
              ]}
              yAxis={[{ valueFormatter: (value: number) => formatCompactMoney(value, 'USD') }]}
              series={[
                {
                  data: data.map((row) => row.average_salary_usd),
                  label: 'Average salary (USD)',
                  valueFormatter: (value) => formatMoney(value, 'USD'),
                },
              ]}
            />
          </Grid>
          <Grid size={{ xs: 12, lg: 7 }}>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Country</TableCell>
                    <TableCell align="right">Headcount</TableCell>
                    <TableCell align="right">Min</TableCell>
                    <TableCell align="right">Median</TableCell>
                    <TableCell align="right">Average</TableCell>
                    <TableCell align="right">Max</TableCell>
                    <TableCell align="right">Avg (USD)</TableCell>
                    <TableCell align="right">Payroll (USD)</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {data.map((row) => (
                    <TableRow key={row.country_code}>
                      <TableCell>{row.country_name}</TableCell>
                      <TableCell align="right">{formatNumber(row.headcount)}</TableCell>
                      <TableCell align="right">{formatMoney(row.min_salary, row.currency)}</TableCell>
                      <TableCell align="right">{formatMoney(row.median_salary, row.currency)}</TableCell>
                      <TableCell align="right">{formatMoney(row.average_salary, row.currency)}</TableCell>
                      <TableCell align="right">{formatMoney(row.max_salary, row.currency)}</TableCell>
                      <TableCell align="right">{formatMoney(row.average_salary_usd, 'USD')}</TableCell>
                      <TableCell align="right">{formatCompactMoney(row.total_payroll_usd, 'USD')}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Grid>
        </Grid>
      )}
    </Section>
  )
}

function DepartmentChart({ countryCode }: { countryCode: string }) {
  const { data, isLoading, error } = useBreakdown('by_department', countryCode)

  return (
    <Section title="Pay by department" subtitle={data ? `Average and median, ${data.currency}` : undefined}>
      {!data ? (
        <QueryState isLoading={isLoading} error={error} />
      ) : data.rows.length === 0 ? (
        <Typography color="text.secondary">No employees.</Typography>
      ) : (
        <BarChart
          height={320}
          xAxis={[{ scaleType: 'band', data: data.rows.map((row) => row.department ?? '') }]}
          yAxis={[{ valueFormatter: (value: number) => formatCompactMoney(value, data.currency) }]}
          series={[
            {
              data: data.rows.map((row) => row.average_salary),
              label: 'Average',
              valueFormatter: (value) => formatMoney(value, data.currency),
            },
            {
              data: data.rows.map((row) => row.median_salary),
              label: 'Median',
              valueFormatter: (value) => formatMoney(value, data.currency),
            },
          ]}
        />
      )}
    </Section>
  )
}

function DistributionChart({
  countryCode,
  jobTitle,
  jobTitles,
  onJobTitleChange,
}: {
  countryCode: string
  jobTitle: string | null
  jobTitles: string[]
  onJobTitleChange: (value: string | null) => void
}) {
  const { data, isLoading, error } = useDistribution(countryCode, jobTitle ?? '')

  return (
    <Section
      title="Salary distribution"
      subtitle={data ? `Number of employees per salary band, ${data.currency}` : undefined}
      action={
        <Autocomplete
          options={jobTitles}
          value={jobTitle}
          onChange={(_, value) => onJobTitleChange(value)}
          renderInput={(params) => <TextField {...params} label="Job title (all)" size="small" />}
          sx={{ minWidth: 220 }}
        />
      }
    >
      {!data ? (
        <QueryState isLoading={isLoading} error={error} />
      ) : data.buckets.length === 0 ? (
        <Typography color="text.secondary">No employees match.</Typography>
      ) : (
        <BarChart
          height={320}
          xAxis={[
            {
              scaleType: 'band',
              data: data.buckets.map((bucket) => formatCompactMoney(bucket.from, data.currency)),
              label: `Salary band starting at (${data.currency})`,
            },
          ]}
          series={[{ data: data.buckets.map((bucket) => bucket.count), label: 'Employees' }]}
          hideLegend
        />
      )}
    </Section>
  )
}

function JobTitleTable({ countryCode }: { countryCode: string }) {
  const { data, isLoading, error } = useBreakdown('by_job_title', countryCode)

  return (
    <Section title="Pay by job title" subtitle={data ? `Highest average first, ${data.currency}` : undefined}>
      {!data ? (
        <QueryState isLoading={isLoading} error={error} />
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Job title</TableCell>
                <TableCell align="right">Headcount</TableCell>
                <TableCell align="right">Min</TableCell>
                <TableCell align="right">Median</TableCell>
                <TableCell align="right">Average</TableCell>
                <TableCell align="right">Max</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {data.rows.map((row) => (
                <TableRow key={row.job_title}>
                  <TableCell>{row.job_title}</TableCell>
                  <TableCell align="right">{formatNumber(row.headcount)}</TableCell>
                  <TableCell align="right">{formatMoney(row.min_salary, data.currency)}</TableCell>
                  <TableCell align="right">{formatMoney(row.median_salary, data.currency)}</TableCell>
                  <TableCell align="right">{formatMoney(row.average_salary, data.currency)}</TableCell>
                  <TableCell align="right">{formatMoney(row.max_salary, data.currency)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Section>
  )
}
