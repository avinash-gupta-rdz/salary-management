require "rails_helper"

RSpec.describe "Employees API", type: :request do
  before { load Rails.root.join("db/seeds/exchange_rates.rb") }

  let(:json) { response.parsed_body }

  describe "GET /api/v1/employees" do
    it "returns a page of employees with pagination meta" do
      create_list(:employee, 3)

      get "/api/v1/employees", params: { per_page: 2, page: 2 }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(1)
      expect(json["meta"]).to eq("page" => 2, "per_page" => 2, "total" => 3, "total_pages" => 2)
    end

    it "caps per_page at 100" do
      get "/api/v1/employees", params: { per_page: 5_000 }, headers: auth_headers

      expect(json["meta"]["per_page"]).to eq(100)
    end

    it "includes the salary converted to USD" do
      create(:employee, country_code: "IN", annual_salary: 1_000_000)

      get "/api/v1/employees", headers: auth_headers

      expect(json["data"].first).to include("currency" => "INR", "annual_salary" => 1_000_000.0, "annual_salary_usd" => 12_000.0)
    end

    it "searches by name or email, ignoring case" do
      create(:employee, full_name: "Priya Sharma", email: "priya@acme.test")
      create(:employee, full_name: "John Smith", email: "john@acme.test")

      get "/api/v1/employees", params: { q: "PRIYA" }, headers: auth_headers

      expect(json["data"].pluck("full_name")).to eq([ "Priya Sharma" ])
    end

    it "treats search wildcards literally" do
      create(:employee, full_name: "John Smith")

      get "/api/v1/employees", params: { q: "%" }, headers: auth_headers

      expect(json["data"]).to be_empty
    end

    it "filters by country, department, job title and employment type" do
      match = create(:employee, country_code: "GB", department: "Sales", job_title: "Sales Manager", employment_type: "contract")
      create(:employee, country_code: "GB", department: "Sales", job_title: "Sales Manager", employment_type: "full_time")
      create(:employee, country_code: "US", department: "Sales", job_title: "Sales Manager", employment_type: "contract")

      get "/api/v1/employees",
          params: { country_code: "GB", department: "Sales", job_title: "Sales Manager", employment_type: "contract" },
          headers: auth_headers

      expect(json["data"].pluck("id")).to eq([ match.id ])
    end

    it "sorts salary by the USD equivalent, not the local amount" do
      india = create(:employee, country_code: "IN", annual_salary: 5_000_000) # ~60,000 USD
      us = create(:employee, country_code: "US", annual_salary: 100_000)

      get "/api/v1/employees", params: { sort: "annual_salary", direction: "desc" }, headers: auth_headers

      expect(json["data"].pluck("id")).to eq([ us.id, india.id ])
    end

    it "falls back to sorting by name for an unknown sort" do
      create(:employee, full_name: "Zara Khan")
      create(:employee, full_name: "Aditi Rao")

      get "/api/v1/employees", params: { sort: "drop table" }, headers: auth_headers

      expect(json["data"].pluck("full_name")).to eq([ "Aditi Rao", "Zara Khan" ])
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the employee" do
      employee = create(:employee, country_code: "DE", annual_salary: 70_000)

      get "/api/v1/employees/#{employee.id}", headers: auth_headers

      expect(json["data"]).to include("id" => employee.id, "country_name" => "Germany", "currency" => "EUR", "annual_salary_usd" => 75_600.0)
    end

    it "returns 404 for an unknown employee" do
      get "/api/v1/employees/0", headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Not found")
    end
  end

  describe "POST /api/v1/employees" do
    let(:valid_params) do
      {
        employee: {
          full_name: "Jane Doe", email: "jane@acme.test", job_title: "Product Manager",
          department: "Product", country_code: "SG", annual_salary: 150_000,
          employment_type: "full_time", hire_date: "2024-01-15"
        }
      }
    end

    it "creates the employee with the country's currency" do
      expect {
        post "/api/v1/employees", params: valid_params, headers: auth_headers
      }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["data"]).to include("email" => "jane@acme.test", "currency" => "SGD")
    end

    it "ignores a currency sent by the client" do
      post "/api/v1/employees", params: valid_params.deep_merge(employee: { currency: "USD" }), headers: auth_headers

      expect(json["data"]["currency"]).to eq("SGD")
    end

    it "returns field errors for invalid input" do
      post "/api/v1/employees", params: valid_params.deep_merge(employee: { email: "bad", annual_salary: 0 }), headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("email" => [ "is invalid" ], "annual_salary" => [ "must be greater than 0" ])
    end

    it "returns 400 when the employee payload is missing" do
      post "/api/v1/employees", params: {}, headers: auth_headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let!(:employee) { create(:employee, annual_salary: 1_000_000) }

    it "updates the employee" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { job_title: "Engineering Manager" } }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(employee.reload.job_title).to eq("Engineering Manager")
    end

    it "records a salary change with its reason" do
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { annual_salary: 1_100_000, salary_change_reason: "Promotion", salary_effective_date: "2026-04-01" } },
            headers: auth_headers

      expect(employee.salary_changes.sole).to have_attributes(
        old_salary: BigDecimal("1000000"), new_salary: BigDecimal("1100000"),
        reason: "Promotion", effective_date: Date.new(2026, 4, 1)
      )
    end

    it "does not change anything when invalid" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { annual_salary: -5 } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.annual_salary).to eq(1_000_000)
      expect(employee.salary_changes).to be_empty
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "deletes the employee and their salary history" do
      employee = create(:employee)
      create(:salary_change, employee: employee)

      delete "/api/v1/employees/#{employee.id}", headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect(Employee.exists?(employee.id)).to be(false)
      expect(SalaryChange.where(employee_id: employee.id)).to be_empty
    end
  end
end
