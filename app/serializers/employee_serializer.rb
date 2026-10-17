class EmployeeSerializer
  def initialize(employee)
    @employee = employee
  end

  def as_json(*)
    {
      id: @employee.id,
      full_name: @employee.full_name,
      email: @employee.email,
      job_title: @employee.job_title,
      department: @employee.department,
      country_code: @employee.country_code,
      country_name: @employee.country&.name,
      currency: @employee.currency,
      annual_salary: @employee.annual_salary.to_f,
      annual_salary_usd: annual_salary_usd.to_f,
      employment_type: @employee.employment_type,
      hire_date: @employee.hire_date,
      updated_at: @employee.updated_at
    }
  end

  private

  # List queries select the USD amount in SQL (NULL when the LEFT JOIN finds no
  # rate); single records convert on demand. Either way a missing rate raises
  # instead of being shown as 0.
  def annual_salary_usd
    return @employee.annual_salary_usd unless @employee.has_attribute?(:annual_salary_usd)

    @employee[:annual_salary_usd] or raise ExchangeRate::Missing, @employee.currency
  end
end
