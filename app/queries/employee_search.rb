# Filters, sorts and paginates employees for the list screen.
#
# Every row carries annual_salary_usd (computed in SQL from the fixed rates), so
# salaries in different currencies can be compared and sorted meaningfully.
class EmployeeSearch
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  FILTERS = %i[country_code department job_title employment_type].freeze

  # Sorting by local salary would rank 1,000,000 INR above 100,000 USD,
  # so salary sorting always uses the USD equivalent.
  SORTS = {
    "full_name" => "employees.full_name",
    "hire_date" => "employees.hire_date",
    "annual_salary" => "annual_salary_usd"
  }.freeze
  DEFAULT_SORT = "full_name".freeze

  Result = Data.define(:records, :page, :per_page, :total) do
    def total_pages
      (total.to_f / per_page).ceil
    end
  end

  def initialize(params = {})
    @params = params
  end

  def call
    scope = filtered_scope
    total = scope.count

    records = scope
      .joins("LEFT JOIN exchange_rates ON exchange_rates.currency = employees.currency")
      .select("employees.*", "ROUND(employees.annual_salary * exchange_rates.rate_to_usd, 2) AS annual_salary_usd")
      .order(Arel.sql("#{SORTS.fetch(sort_key)} #{direction}"), id: direction)
      .limit(per_page)
      .offset((page - 1) * per_page)

    Result.new(records: records, page: page, per_page: per_page, total: total)
  end

  private

  def filtered_scope
    scope = Employee.all
    FILTERS.each do |filter|
      value = @params[filter].presence
      scope = scope.where(filter => value) if value
    end
    search_term ? scope.where("employees.full_name LIKE :term OR employees.email LIKE :term", term: search_term) : scope
  end

  def search_term
    query = @params[:q].to_s.strip
    "%#{Employee.sanitize_sql_like(query)}%" if query.present?
  end

  # Unknown values fall back to defaults instead of erroring, so a stale or
  # hand-edited URL still returns a sensible list.
  def sort_key
    SORTS.key?(@params[:sort]) ? @params[:sort] : DEFAULT_SORT
  end

  def direction
    @params[:direction] == "desc" ? "DESC" : "ASC"
  end

  def page
    [ @params[:page].to_i, 1 ].max
  end

  def per_page
    requested = @params[:per_page].to_i
    requested.positive? ? [ requested, MAX_PER_PAGE ].min : DEFAULT_PER_PAGE
  end
end
