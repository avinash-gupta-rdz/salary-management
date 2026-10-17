export type EmploymentType = 'full_time' | 'part_time' | 'contract'

export interface Employee {
  id: number
  full_name: string
  email: string
  job_title: string
  department: string
  country_code: string
  country_name: string | null
  currency: string
  annual_salary: number
  annual_salary_usd: number
  employment_type: EmploymentType
  hire_date: string
  updated_at: string
}

export interface PageMeta {
  page: number
  per_page: number
  total: number
  total_pages: number
}

export interface Country {
  code: string
  name: string
  currency: string
}

export interface Meta {
  countries: Country[]
  departments: string[]
  job_titles: string[]
  job_titles_by_department: Record<string, string[]>
  employment_types: EmploymentType[]
}

export interface SalaryChange {
  id: number
  old_salary: number
  old_currency: string
  new_salary: number
  new_currency: string
  effective_date: string
  reason: string | null
  created_at: string
}

export interface EmployeeInput {
  full_name: string
  email: string
  job_title: string
  department: string
  country_code: string
  annual_salary: string
  employment_type: EmploymentType
  hire_date: string
  salary_change_reason?: string
  salary_effective_date?: string
}

export interface EmployeeFilters {
  q?: string
  country_code?: string
  department?: string
  job_title?: string
  employment_type?: string
  sort?: string
  direction?: 'asc' | 'desc'
  page?: number
  per_page?: number
}

export interface Summary {
  headcount: number
  total_payroll_usd: number | null
  average_salary_usd: number | null
  median_salary_usd: number | null
  countries: number
  departments: number
}

export interface CountryStats {
  country_code: string
  country_name: string | null
  currency: string | null
  headcount: number
  min_salary: number
  max_salary: number
  average_salary: number
  median_salary: number
  total_payroll: number
  average_salary_usd: number
  total_payroll_usd: number
}

export interface GroupStats {
  headcount: number
  min_salary: number
  max_salary: number
  average_salary: number
  median_salary: number
  job_title?: string
  department?: string
}

export interface Breakdown {
  currency: string
  rows: GroupStats[]
}

export interface Distribution {
  currency: string
  buckets: { from: number; to: number; count: number }[]
}

export type FieldErrors = Record<string, string[]>
