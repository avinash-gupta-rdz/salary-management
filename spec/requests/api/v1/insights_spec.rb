require "rails_helper"

RSpec.describe "Insights API", type: :request do
  before do
    load Rails.root.join("db/seeds/exchange_rates.rb")
    create(:employee, country_code: "IN", annual_salary: 1_000_000)
    create(:employee, country_code: "US", annual_salary: 100_000)
  end

  let(:json) { response.parsed_body }

  it "returns the org summary" do
    get "/api/v1/insights/summary", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(json["data"]).to include("headcount" => 2, "total_payroll_usd" => 112_000.0)
  end

  it "returns stats per country" do
    get "/api/v1/insights/by_country", headers: auth_headers

    expect(json["data"].pluck("country_code")).to contain_exactly("IN", "US")
  end

  it "returns job title stats in the requested country's currency" do
    get "/api/v1/insights/by_job_title", params: { country_code: "IN" }, headers: auth_headers

    expect(json["data"]["currency"]).to eq("INR")
    expect(json["data"]["rows"].first).to include("job_title" => "Software Engineer", "average_salary" => 1_000_000.0)
  end

  it "returns department stats in USD by default" do
    get "/api/v1/insights/by_department", headers: auth_headers

    expect(json["data"]["currency"]).to eq("USD")
  end

  it "returns a salary distribution" do
    get "/api/v1/insights/distribution", params: { country_code: "US" }, headers: auth_headers

    expect(json["data"]["buckets"].sum { |bucket| bucket["count"] }).to eq(1)
  end

  it "fails clearly when a currency has no rate" do
    ExchangeRate.where(currency: "INR").delete_all

    get "/api/v1/insights/summary", headers: auth_headers

    expect(response).to have_http_status(:internal_server_error)
    expect(json).to eq("error" => "No exchange rate for INR")
  end

  it "rejects an unsupported country" do
    get "/api/v1/insights/by_job_title", params: { country_code: "FR" }, headers: auth_headers

    expect(response).to have_http_status(:bad_request)
    expect(json).to eq("error" => "Unsupported country_code")
  end

  it "requires authentication" do
    get "/api/v1/insights/summary"

    expect(response).to have_http_status(:unauthorized)
  end
end
