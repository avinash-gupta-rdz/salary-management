require "rails_helper"

RSpec.describe SalaryChange, type: :model do
  subject(:change) { build(:salary_change) }

  it "is valid with valid attributes" do
    expect(change).to be_valid
  end

  it "requires positive amounts" do
    change.new_salary = 0

    expect(change).not_to be_valid
    expect(change.errors[:new_salary]).to include("must be greater than 0")
  end

  it "requires an effective date" do
    change.effective_date = nil

    expect(change).not_to be_valid
  end

  it "orders latest first by effective date" do
    employee = create(:employee)
    older = create(:salary_change, employee: employee, effective_date: Date.new(2025, 4, 1))
    newer = create(:salary_change, employee: employee, effective_date: Date.new(2026, 4, 1))

    expect(employee.salary_changes.latest_first).to eq([ newer, older ])
  end
end
