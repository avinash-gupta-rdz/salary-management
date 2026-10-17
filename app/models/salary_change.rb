class SalaryChange < ApplicationRecord
  belongs_to :employee

  validates :old_salary, :new_salary, presence: true, numericality: { greater_than: 0 }
  validates :effective_date, presence: true
  validates :reason, length: { maximum: 255 }

  scope :latest_first, -> { order(effective_date: :desc, id: :desc) }
end
