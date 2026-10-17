require "rails_helper"

RSpec.describe Employee, type: :model do
  subject(:employee) { build(:employee) }

  it "is valid with valid attributes" do
    expect(employee).to be_valid
  end

  describe "required fields" do
    %i[full_name email job_title department country_code currency annual_salary employment_type hire_date].each do |field|
      it "requires #{field}" do
        employee[field] = nil

        expect(employee).not_to be_valid
        expect(employee.errors[field]).to be_present
      end
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

  describe "country_code and currency" do
    it "are stored upcased" do
      employee.country_code = "us"
      employee.currency = "usd"

      expect(employee.country_code).to eq("US")
      expect(employee.currency).to eq("USD")
    end

    it "rejects a country code that is not 2 letters" do
      employee.country_code = "IND"

      expect(employee).not_to be_valid
      expect(employee.errors[:country_code]).to include("must be a 2-letter ISO code")
    end

    it "rejects a currency that is not 3 letters" do
      employee.currency = "RS"

      expect(employee).not_to be_valid
      expect(employee.errors[:currency]).to include("must be a 3-letter ISO code")
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

  describe "name fields" do
    it "squishes extra whitespace" do
      employee.full_name = "  Jane   Doe "

      expect(employee.full_name).to eq("Jane Doe")
    end
  end
end
