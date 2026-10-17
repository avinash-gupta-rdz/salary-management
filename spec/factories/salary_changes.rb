FactoryBot.define do
  factory :salary_change do
    employee
    old_salary { 1_000_000 }
    new_salary { 1_200_000 }
    effective_date { Date.new(2026, 4, 1) }
  end
end
