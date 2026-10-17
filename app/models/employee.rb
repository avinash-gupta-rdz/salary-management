class Employee < ApplicationRecord
  enum :employment_type, {
    full_time: "full_time",
    part_time: "part_time",
    contract: "contract"
  }, validate: true

  has_many :salary_changes, dependent: :delete_all

  # Optional context for the salary history entry written when the salary changes.
  attribute :salary_change_reason, :string
  attribute :salary_effective_date, :date

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_title, :department, with: ->(value) { value.squish }
  normalizes :country_code, with: ->(value) { value.strip.upcase }

  # Currency is never set by HR: each country pays in one currency.
  before_validation :assign_currency_from_country

  # Runs inside the update's transaction, so a salary can't change without a
  # matching history entry, whichever code path performs the update.
  after_update :record_salary_change, if: :saved_change_to_annual_salary?

  validates :full_name, :job_title, :department, :hire_date, presence: true
  validates :department, inclusion: { in: ->(_) { Department.names }, message: "is not a known department" }, allow_blank: true
  validate :job_title_belongs_to_department
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, presence: true, inclusion: { in: ->(_) { Country.codes }, message: "is not supported" }
  validates :annual_salary, presence: true, numericality: { greater_than: 0 }
  validate :hire_date_not_in_future
  validate :salary_reentered_on_currency_change

  def country
    Country.find(country_code)
  end

  def annual_salary_usd
    ExchangeRate.to_usd(annual_salary, currency)
  end

  private

  def assign_currency_from_country
    self.currency = country&.currency
  end

  def record_salary_change
    old_salary, new_salary = saved_change_to_annual_salary
    old_currency, new_currency = saved_change_to_currency || [ currency, currency ]
    salary_changes.create!(
      old_salary: old_salary,
      old_currency: old_currency,
      new_salary: new_salary,
      new_currency: new_currency,
      effective_date: salary_effective_date || Date.current,
      reason: salary_change_reason.presence
    )
  end

  def job_title_belongs_to_department
    known_department = Department.find(department)
    return if job_title.blank? || known_department.nil? || known_department.job_titles.include?(job_title)

    errors.add(:job_title, "is not a role in #{department}")
  end

  # Moving country changes the payroll currency. Keeping the old number would
  # silently re-denominate it (INR 1,613,000 becoming USD 1,613,000), so the
  # salary has to be entered again in the new currency.
  def salary_reentered_on_currency_change
    return if new_record? || !currency_changed? || annual_salary_changed?

    errors.add(:annual_salary, "must be re-entered in #{currency} because the new country pays in #{currency}, not #{currency_was}")
  end

  def hire_date_not_in_future
    return if hire_date.blank? || hire_date <= Date.current

    errors.add(:hire_date, "can't be in the future")
  end
end
