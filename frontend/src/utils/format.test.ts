import { formatCompactMoney, formatDate, formatEmploymentType, formatMoney } from './format'

describe('formatMoney', () => {
  it('formats whole amounts in the given currency', () => {
    expect(formatMoney(1_234_567.89, 'USD')).toBe('$1,234,568')
    expect(formatMoney(1_200_000, 'INR')).toBe('₹1,200,000')
  })

  it('shows a dash when the amount or currency is missing', () => {
    expect(formatMoney(null, 'USD')).toBe('—')
    expect(formatMoney(100, null)).toBe('—')
  })
})

describe('formatCompactMoney', () => {
  it('abbreviates large amounts', () => {
    expect(formatCompactMoney(536_449_904, 'USD')).toBe('$536.4M')
  })
})

describe('formatDate', () => {
  it('keeps the calendar day regardless of the browser time zone', () => {
    expect(formatDate('2022-04-01')).toBe('1 Apr 2022')
  })
})

describe('formatEmploymentType', () => {
  it('turns API values into labels', () => {
    expect(formatEmploymentType('part_time')).toBe('Part-time')
  })
})
