class Employee < ApplicationRecord
  enum :employment_type, {
    full_time: "full_time",
    part_time: "part_time",
    contract: "contract"
  }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_title, :department, with: ->(value) { value.squish }
  normalizes :country_code, :currency, with: ->(value) { value.strip.upcase }

  validates :full_name, :job_title, :department, :hire_date, presence: true
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, presence: true, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter ISO code" }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code" }
  validates :annual_salary, presence: true, numericality: { greater_than: 0 }
  validate :hire_date_not_in_future

  private

  def hire_date_not_in_future
    return if hire_date.blank? || hire_date <= Date.current

    errors.add(:hire_date, "can't be in the future")
  end
end
