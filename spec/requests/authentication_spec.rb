require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "rejects requests without credentials with JSON and no browser login challenge" do
    get "/api/v1/employees"

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq("error" => "Unauthorized")
    # A challenge would make browsers cache the credentials, enabling CSRF.
    expect(response.headers["WWW-Authenticate"]).to be_nil
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

  describe "write requests" do
    it "reject a form-encoded body, which is what a cross-site form would send" do
      expect {
        post "/api/v1/employees", params: { employee: { full_name: "Forged" } }, headers: auth_headers
      }.not_to change(Employee, :count)

      expect(response).to have_http_status(:unsupported_media_type)
    end

    it "accept a JSON body" do
      post "/api/v1/employees", params: { employee: { full_name: "" } }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
