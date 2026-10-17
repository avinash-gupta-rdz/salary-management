class SalaryChange < ApplicationRecord
  belongs_to :employee

  validates :old_salary, :new_salary, presence: true, numericality: { greater_than: 0 }
  validates :old_currency, :new_currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :effective_date, presence: true
  validates :reason, length: { maximum: 255 }

  scope :latest_first, -> { order(effective_date: :desc, id: :desc) }
end
