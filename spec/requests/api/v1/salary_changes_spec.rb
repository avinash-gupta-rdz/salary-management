require "rails_helper"

RSpec.describe "Salary changes API", type: :request do
  it "lists an employee's salary changes, latest first" do
    employee = create(:employee, country_code: "GB")
    older = create(:salary_change, employee: employee, effective_date: Date.new(2025, 4, 1), reason: "Annual review")
    newer = create(:salary_change, employee: employee, effective_date: Date.new(2026, 4, 1), reason: "Promotion")
    create(:salary_change) # another employee's change

    get "/api/v1/employees/#{employee.id}/salary_changes", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"].pluck("id")).to eq([ newer.id, older.id ])
    expect(response.parsed_body["data"].first).to include("currency" => "GBP", "reason" => "Promotion")
  end

  it "returns 404 for an unknown employee" do
    get "/api/v1/employees/0/salary_changes", headers: auth_headers

    expect(response).to have_http_status(:not_found)
  end
end
