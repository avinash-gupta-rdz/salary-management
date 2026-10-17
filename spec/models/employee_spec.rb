require "rails_helper"

RSpec.describe Employee, type: :model do
  subject(:employee) { build(:employee) }

  it "is valid with valid attributes" do
    expect(employee).to be_valid
  end

  describe "required fields" do
    %i[full_name email job_title department country_code annual_salary employment_type hire_date].each do |field|
      it "requires #{field}" do
        employee[field] = nil

        expect(employee).not_to be_valid
        expect(employee.errors[field]).to be_present
      end
    end
  end

  describe "department and job title" do
    it "rejects a department that isn't on the list" do
      employee.department = "Engg"

      expect(employee).not_to be_valid
      expect(employee.errors[:department]).to include("is not a known department")
    end

    it "rejects a job title from another department" do
      employee.department = "Sales"
      employee.job_title = "Software Engineer"

      expect(employee).not_to be_valid
      expect(employee.errors[:job_title]).to include("is not a role in Sales")
    end

    it "accepts a job title that belongs to the department" do
      employee.department = "Sales"
      employee.job_title = "Account Executive"

      expect(employee).to be_valid
    end
  end

  describe "email" do
    it "rejects an invalid format" do
      employee.email = "not-an-email"

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("is invalid")
    end

    it "must be unique ignoring case" do
      create(:employee, email: "jane@acme.test")
      employee.email = "JANE@acme.test"

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("has already been taken")
    end

    it "is stored stripped and downcased" do
      employee.email = "  Jane.Doe@ACME.test "

      expect(employee.email).to eq("jane.doe@acme.test")
    end
  end

  describe "country_code" do
    it "is stored upcased" do
      employee.country_code = "us"

      expect(employee.country_code).to eq("US")
    end

    it "rejects a country ACME does not operate in" do
      employee.country_code = "FR"

      expect(employee).not_to be_valid
      expect(employee.errors[:country_code]).to include("is not supported")
    end
  end

  describe "changing country" do
    let!(:employee) { create(:employee, country_code: "IN", annual_salary: 1_613_000) }

    it "requires the salary to be re-entered, instead of re-labelling INR as USD" do
      employee.country_code = "US"

      expect(employee).not_to be_valid
      expect(employee.errors[:annual_salary]).to include("must be re-entered in USD because the new country pays in USD, not INR")
      expect(employee.reload).to have_attributes(currency: "INR", annual_salary: BigDecimal("1613000"))
    end

    it "is allowed together with a new salary" do
      employee.update!(country_code: "US", annual_salary: 90_000)

      expect(employee.reload).to have_attributes(currency: "USD", annual_salary: BigDecimal("90000"))
    end
  end

  describe "currency" do
    it "is set from the country" do
      employee.country_code = "GB"
      employee.validate

      expect(employee.currency).to eq("GBP")
    end

    it "follows the country when the country changes" do
      employee.save!
      employee.update!(country_code: "DE", annual_salary: 70_000)

      expect(employee.reload.currency).to eq("EUR")
    end

    it "ignores a currency that does not match the country" do
      employee.country_code = "SG"
      employee.currency = "USD"
      employee.save!

      expect(employee.reload.currency).to eq("SGD")
    end
  end

  describe "#annual_salary_usd" do
    it "converts the salary using the currency's rate" do
      create(:exchange_rate, currency: "INR", rate_to_usd: "0.012")
      employee.annual_salary = 1_200_000
      employee.validate

      expect(employee.annual_salary_usd).to eq(BigDecimal("14400"))
    end
  end

  describe "annual_salary" do
    it "must be greater than zero" do
      employee.annual_salary = 0

      expect(employee).not_to be_valid
      expect(employee.errors[:annual_salary]).to include("must be greater than 0")
    end

    it "is enforced by a database check constraint" do
      employee.save!

      expect { employee.update_column(:annual_salary, -1) }
        .to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed/)
    end
  end

  describe "employment_type" do
    it "rejects an unknown value" do
      employee.employment_type = "intern"

      expect(employee).not_to be_valid
      expect(employee.errors[:employment_type]).to include("is not included in the list")
    end
  end

  describe "hire_date" do
    it "can't be in the future" do
      employee.hire_date = Date.current + 1

      expect(employee).not_to be_valid
      expect(employee.errors[:hire_date]).to include("can't be in the future")
    end

    it "can be today" do
      employee.hire_date = Date.current

      expect(employee).to be_valid
    end
  end

  describe "salary history" do
    let!(:employee) { create(:employee, annual_salary: 1_000_000) }

    it "records the old and new salary when the salary changes" do
      travel_to Date.new(2026, 5, 10) do
        employee.update!(annual_salary: 1_150_000, salary_change_reason: "Annual review")
      end

      change = employee.salary_changes.sole
      expect(change).to have_attributes(
        old_salary: BigDecimal("1000000"),
        new_salary: BigDecimal("1150000"),
        effective_date: Date.new(2026, 5, 10),
        reason: "Annual review"
      )
    end

    it "uses the given effective date" do
      employee.update!(annual_salary: 1_150_000, salary_effective_date: Date.new(2026, 4, 1))

      expect(employee.salary_changes.sole.effective_date).to eq(Date.new(2026, 4, 1))
    end

    it "records nothing when other fields change" do
      employee.update!(job_title: "Senior Software Engineer")

      expect(employee.salary_changes).to be_empty
    end

    it "records both currencies when the employee moves country with a new salary" do
      employee.update!(country_code: "US", annual_salary: 90_000)

      expect(employee.salary_changes.sole).to have_attributes(
        old_salary: BigDecimal("1000000"), old_currency: "INR",
        new_salary: BigDecimal("90000"), new_currency: "USD"
      )
    end

    it "records the currency on both sides for an ordinary raise" do
      employee.update!(annual_salary: 1_100_000)

      expect(employee.salary_changes.sole).to have_attributes(old_currency: "INR", new_currency: "INR")
    end

    it "records nothing on create" do
      expect(employee.salary_changes).to be_empty
    end

    it "is removed with the employee" do
      employee.update!(annual_salary: 1_150_000)

      expect { employee.destroy }.to change(SalaryChange, :count).by(-1)
    end
  end

  describe "name fields" do
    it "squishes extra whitespace" do
      employee.full_name = "  Jane   Doe "

      expect(employee.full_name).to eq("Jane Doe")
    end
  end
end
