require "rails_helper"

RSpec.describe "Meta API", type: :request do
  it "returns option lists for filters and forms" do
    create(:employee, department: "Sales", job_title: "Account Executive")
    create(:employee, department: "Engineering", job_title: "QA Engineer")

    get "/api/v1/meta", headers: auth_headers

    data = response.parsed_body["data"]
    expect(data["countries"]).to include("code" => "IN", "name" => "India", "currency" => "INR")
    expect(data["departments"]).to eq([ "Engineering", "Sales" ])
    expect(data["job_titles"]).to eq([ "Account Executive", "QA Engineer" ])
    expect(data["employment_types"]).to eq(%w[full_time part_time contract])
  end
end
