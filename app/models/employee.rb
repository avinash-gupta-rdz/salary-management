class Employee < ApplicationRecord
  enum :employment_type, {
    full_time: "full_time",
    part_time: "part_time",
    contract: "contract"
  }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_title, :department, with: ->(value) { value.squish }
  normalizes :country_code, with: ->(value) { value.strip.upcase }

  # Currency is never set by HR: each country pays in one currency.
  before_validation :assign_currency_from_country

  validates :full_name, :job_title, :department, :hire_date, presence: true
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, presence: true, inclusion: { in: ->(_) { Country.codes }, message: "is not supported" }
  validates :annual_salary, presence: true, numericality: { greater_than: 0 }
  validate :hire_date_not_in_future

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

  def hire_date_not_in_future
    return if hire_date.blank? || hire_date <= Date.current

    errors.add(:hire_date, "can't be in the future")
  end
end
