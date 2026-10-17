require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "rejects requests without credentials" do
    get "/api/v1/employees"

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to include("Basic")
  end

  it "answers the frontend with JSON and no browser login challenge" do
    get "/api/v1/employees", headers: { "X-Requested-With" => "XMLHttpRequest" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to be_nil
    expect(response.parsed_body).to eq("error" => "Unauthorized")
  end

  it "rejects a wrong password" do
    get "/api/v1/employees", headers: auth_headers(password: "wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts the HR manager credentials" do
    get "/api/v1/employees", headers: auth_headers

    expect(response).to have_http_status(:ok)
  end

  it "refuses everyone when no credentials are configured" do
    allow(Rails.configuration.x).to receive(:hr_auth)
      .and_return(ActiveSupport::OrderedOptions.new.merge(username: nil, password: nil))

    get "/api/v1/employees", headers: auth_headers(username: "", password: "")

    expect(response).to have_http_status(:unauthorized)
  end

  it "leaves the health check open" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
