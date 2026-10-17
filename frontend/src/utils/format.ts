const formatters = new Map<string, Intl.NumberFormat>()

// Whole units only: salaries here are annual figures, cents add noise.
export function formatMoney(amount: number | null | undefined, currency: string | null | undefined): string {
  if (amount === null || amount === undefined || !currency) return '—'
  let formatter = formatters.get(currency)
  if (!formatter) {
    formatter = new Intl.NumberFormat('en-US', { style: 'currency', currency, maximumFractionDigits: 0 })
    formatters.set(currency, formatter)
  }
  return formatter.format(amount)
}

// Short form for chart axes and cards, e.g. $1.2M, ₹45K.
export function formatCompactMoney(amount: number | null | undefined, currency: string | null | undefined): string {
  if (amount === null || amount === undefined || !currency) return '—'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(amount)
}

export function formatNumber(value: number | null | undefined): string {
  return value === null || value === undefined ? '—' : new Intl.NumberFormat('en-US').format(value)
}

const EMPLOYMENT_TYPE_LABELS: Record<string, string> = {
  full_time: 'Full-time',
  part_time: 'Part-time',
  contract: 'Contract',
}

export function formatEmploymentType(value: string): string {
  return EMPLOYMENT_TYPE_LABELS[value] ?? value
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return '—'
  // Dates from the API are plain YYYY-MM-DD; parse as UTC so the day never shifts.
  return new Date(`${value.slice(0, 10)}T00:00:00Z`).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  })
}
