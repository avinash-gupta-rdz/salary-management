require "rails_helper"

RSpec.describe "Meta API", type: :request do
  it "returns option lists for filters and forms from the fixed lists" do
    get "/api/v1/meta", headers: auth_headers

    data = response.parsed_body["data"]
    expect(data["countries"]).to include("code" => "IN", "name" => "India", "currency" => "INR")
    expect(data["departments"]).to eq(Department.names)
    expect(data["job_titles"]).to eq(Department.job_titles.sort)
    expect(data["job_titles_by_department"]["Sales"]).to eq([ "Account Executive", "Sales Manager" ])
    expect(data["employment_types"]).to eq(%w[full_time part_time contract])
  end
end
