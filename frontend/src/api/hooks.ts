import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiRequest, buildQuery } from './client'
import type {
  Breakdown,
  CountryStats,
  Distribution,
  Employee,
  EmployeeFilters,
  EmployeeInput,
  Meta,
  PageMeta,
  SalaryChange,
  Summary,
} from './types'

export function useMeta() {
  return useQuery({
    queryKey: ['meta'],
    queryFn: () => apiRequest<{ data: Meta }>('/meta').then((r) => r.data),
    staleTime: 5 * 60 * 1000,
  })
}

export function useEmployees(filters: EmployeeFilters) {
  return useQuery({
    queryKey: ['employees', filters],
    queryFn: () =>
      apiRequest<{ data: Employee[]; meta: PageMeta }>(`/employees${buildQuery({ ...filters })}`),
    // Keep showing the current page while the next one loads, so the grid doesn't flash empty.
    placeholderData: keepPreviousData,
  })
}

export function useEmployee(id: string | undefined) {
  return useQuery({
    queryKey: ['employee', id],
    queryFn: () => apiRequest<{ data: Employee }>(`/employees/${id}`).then((r) => r.data),
    enabled: id !== undefined,
  })
}

export function useSalaryChanges(id: string | undefined) {
  return useQuery({
    queryKey: ['salary-changes', id],
    queryFn: () => apiRequest<{ data: SalaryChange[] }>(`/employees/${id}/salary_changes`).then((r) => r.data),
    enabled: id !== undefined,
  })
}

// An employee change can move list results, every insight and the filter options
// (a new department or job title), so refresh everything.
function useInvalidateEmployeeData() {
  const queryClient = useQueryClient()
  return () => queryClient.invalidateQueries()
}

export function useSaveEmployee(id?: number) {
  const invalidate = useInvalidateEmployeeData()
  return useMutation({
    mutationFn: (employee: EmployeeInput) =>
      apiRequest<{ data: Employee }>(id ? `/employees/${id}` : '/employees', {
        method: id ? 'PATCH' : 'POST',
        body: { employee },
      }).then((r) => r.data),
    onSuccess: invalidate,
  })
}

export function useDeleteEmployee() {
  const invalidate = useInvalidateEmployeeData()
  return useMutation({
    mutationFn: (id: number) => apiRequest<void>(`/employees/${id}`, { method: 'DELETE' }),
    onSuccess: invalidate,
  })
}

export function useSummary() {
  return useQuery({
    queryKey: ['insights', 'summary'],
    queryFn: () => apiRequest<{ data: Summary }>('/insights/summary').then((r) => r.data),
  })
}

export function useCountryStats() {
  return useQuery({
    queryKey: ['insights', 'by_country'],
    queryFn: () => apiRequest<{ data: CountryStats[] }>('/insights/by_country').then((r) => r.data),
  })
}

export function useBreakdown(kind: 'by_job_title' | 'by_department', countryCode: string) {
  return useQuery({
    queryKey: ['insights', kind, countryCode],
    queryFn: () =>
      apiRequest<{ data: Breakdown }>(`/insights/${kind}${buildQuery({ country_code: countryCode })}`).then((r) => r.data),
  })
}

export function useDistribution(countryCode: string, jobTitle: string) {
  return useQuery({
    queryKey: ['insights', 'distribution', countryCode, jobTitle],
    queryFn: () =>
      apiRequest<{ data: Distribution }>(
        `/insights/distribution${buildQuery({ country_code: countryCode, job_title: jobTitle })}`,
      ).then((r) => r.data),
  })
}
