# Answers "how does the org pay people?" with aggregations done in SQL.
#
# Currency rule: figures scoped to one country stay in that country's currency
# (one currency per country, so they are directly comparable). Anything that
# spans countries is converted to USD with the fixed exchange rates.
class SalaryInsights
  class MissingExchangeRate < StandardError; end

  LOCAL_SALARY = "employees.annual_salary".freeze
  USD_SALARY = "(employees.annual_salary * exchange_rates.rate_to_usd)".freeze
  DEFAULT_BUCKETS = 10

  def summary
    stats = aggregate(usd_scope, USD_SALARY).first || {}

    {
      headcount: stats.fetch(:headcount, 0),
      total_payroll_usd: stats[:total],
      average_salary_usd: stats[:average],
      median_salary_usd: medians(usd_scope, USD_SALARY).values.first,
      countries: Employee.distinct.count(:country_code),
      departments: Employee.distinct.count(:department)
    }
  end

  # Local-currency stats per country, plus USD figures for comparing countries.
  def by_country
    local = aggregate(Employee.all, LOCAL_SALARY, group: "employees.country_code").index_by { |row| row[:group] }
    usd = aggregate(usd_scope, USD_SALARY, group: "employees.country_code").index_by { |row| row[:group] }
    local_medians = medians(Employee.all, LOCAL_SALARY, group: "employees.country_code")

    local.map do |code, row|
      country = Country.find(code)
      {
        country_code: code,
        country_name: country&.name,
        currency: country&.currency,
        headcount: row[:headcount],
        min_salary: row[:min],
        max_salary: row[:max],
        average_salary: row[:average],
        median_salary: local_medians[code],
        total_payroll: row[:total],
        average_salary_usd: usd.dig(code, :average),
        total_payroll_usd: usd.dig(code, :total)
      }
    end.sort_by { |row| -row[:headcount] }
  end

  def by_job_title(country_code: nil)
    breakdown("employees.job_title", :job_title, country_code)
  end

  def by_department(country_code: nil)
    breakdown("employees.department", :department, country_code)
  end

  # Histogram of salaries, with "nice" bucket widths (e.g. 20,000 not 18,347).
  def distribution(country_code: nil, job_title: nil, buckets: DEFAULT_BUCKETS)
    scope, salary = scope_for(country_code)
    scope = scope.where(job_title: job_title) if job_title.present?
    low, high = scope.pick(Arel.sql("MIN(#{salary})"), Arel.sql("MAX(#{salary})"))
    return { currency: currency_for(country_code), buckets: [] } if low.nil?

    width = nice_width((high - low) / buckets)
    start = (low / width).floor * width
    counts = scope.group(Arel.sql("CAST((#{salary} - #{start}) / #{width} AS INTEGER)")).count
    last_index = ((high - start) / width).floor

    {
      currency: currency_for(country_code),
      buckets: (0..last_index).map do |index|
        { from: start + index * width, to: start + (index + 1) * width, count: counts.fetch(index, 0) }
      end
    }
  end

  private

  def breakdown(column, key, country_code)
    scope, salary = scope_for(country_code)
    group_medians = medians(scope, salary, group: column)

    rows = aggregate(scope, salary, group: column).map do |row|
      {
        key => row[:group],
        headcount: row[:headcount],
        min_salary: row[:min],
        max_salary: row[:max],
        average_salary: row[:average],
        median_salary: group_medians[row[:group]]
      }
    end

    { currency: currency_for(country_code), rows: rows.sort_by { |row| -row[:average_salary] } }
  end

  # Within one country use local currency; across countries use USD.
  def scope_for(country_code)
    return [ usd_scope, USD_SALARY ] if country_code.blank?

    [ Employee.where(country_code: country_code), LOCAL_SALARY ]
  end

  def currency_for(country_code)
    country_code.present? ? Country.find(country_code)&.currency : "USD"
  end

  def usd_scope
    ensure_exchange_rates!
    Employee.joins("INNER JOIN exchange_rates ON exchange_rates.currency = employees.currency")
  end

  # An inner join would silently drop employees whose currency has no rate,
  # under-reporting payroll. Fail loudly instead.
  def ensure_exchange_rates!
    missing = Employee.where.not(currency: ExchangeRate.select(:currency)).distinct.pluck(:currency)
    raise MissingExchangeRate, "No exchange rate for #{missing.join(', ')}" if missing.any?
  end

  # salary/group are internal SQL fragments (constants or column names), never user input.
  def aggregate(scope, salary, group: nil)
    columns = [
      "COUNT(*)", "MIN(#{salary})", "MAX(#{salary})", "AVG(#{salary})", "SUM(#{salary})"
    ].map { |sql| Arel.sql(sql) }
    scope = scope.group(Arel.sql(group)) if group
    rows = group ? scope.pluck(Arel.sql(group), *columns) : [ [ nil, *scope.pick(*columns) ] ]

    rows.filter_map do |group_value, count, min, max, average, total|
      next if count.to_i.zero?

      { group: group_value, headcount: count, min: round(min), max: round(max), average: round(average), total: round(total) }
    end
  end

  # SQLite has no MEDIAN, so rank rows within each group and average the middle
  # one (odd count) or two (even count). Returns { group_value => median }.
  def medians(scope, salary, group: nil)
    partition = group ? "PARTITION BY #{group}" : ""
    ranked = scope.select(
      Arel.sql("#{group || 'NULL'} AS group_value"),
      Arel.sql("#{salary} AS salary"),
      Arel.sql("ROW_NUMBER() OVER (#{partition} ORDER BY #{salary}) AS position"),
      Arel.sql("COUNT(*) OVER (#{partition}) AS group_size")
    )

    Employee.unscoped
      .from(ranked, :ranked)
      .where("position IN ((group_size + 1) / 2, (group_size + 2) / 2)")
      .group(:group_value)
      .pluck(:group_value, Arel.sql("AVG(salary)"))
      .to_h { |group_value, median| [ group_value, round(median) ] }
  end

  def nice_width(raw)
    raw = raw.to_f
    return 1 if raw <= 0

    magnitude = 10**Math.log10(raw).floor
    step = [ 1, 2, 5, 10 ].find { |multiple| multiple * magnitude >= raw }
    step * magnitude
  end

  def round(value)
    value&.to_f&.round(2)
  end
end
