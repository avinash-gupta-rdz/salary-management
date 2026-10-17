require "rails_helper"

RSpec.describe EmployeeSeeder do
  before { load Rails.root.join("db/seeds/exchange_rates.rb") }

  def seed(count: 50, seed: 42)
    described_class.new(count: count, random: Random.new(seed)).call
  end

  it "has a salary band for every job title" do
    expect(described_class::SALARY_BANDS.keys).to match_array(Department.job_titles)
  end

  it "inserts the requested number of employees" do
    expect(seed(count: 50)).to eq(50)
    expect(Employee.count).to eq(50)
  end

  it "produces employees that pass model validations" do
    # Large enough to include accented names such as Müller.
    seed(count: 300)
    expect(Employee.where("full_name LIKE ?", "%ü%")).to exist

    invalid = Employee.all.reject(&:valid?)
    expect(invalid).to be_empty, invalid.map { |e| [ e.email, e.errors.full_messages ] }.inspect
  end

  it "pays each employee in their country's currency" do
    seed

    Employee.find_each do |employee|
      expect(employee.currency).to eq(employee.country.currency)
    end
  end

  it "produces the same data for the same random seed" do
    seed(seed: 7)
    first_run = Employee.order(:email).pluck(:email, :annual_salary, :country_code)
    Employee.delete_all
    seed(seed: 7)

    expect(Employee.order(:email).pluck(:email, :annual_salary, :country_code)).to eq(first_run)
  end

  it "does nothing when employees already exist" do
    create(:employee)

    expect(seed).to eq(0)
    expect(Employee.count).to eq(1)
  end
end
