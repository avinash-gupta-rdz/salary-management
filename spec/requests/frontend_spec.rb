require "rails_helper"

RSpec.describe "Frontend shell", type: :request do
  let(:index_path) { Rails.root.join("tmp/test_app.html") }

  before do
    File.write(index_path, "<!doctype html><title>Salary Management</title>")
    stub_const("FrontendController::INDEX_PATH", index_path)
  end

  after { FileUtils.rm_f(index_path) }

  it "serves the app shell for client-side routes without signing in" do
    get "/employees/42", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<title>Salary Management</title>")
    expect(response.headers["Cache-Control"]).to eq("no-cache")
  end

  it "serves the app shell at the root" do
    get "/", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:ok)
  end

  it "does not answer unknown API paths with the shell" do
    get "/api/v1/unknown", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("<title>Salary Management</title>")
  end

  it "explains when the frontend has not been built" do
    FileUtils.rm_f(index_path)

    get "/insights", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("bin/build-frontend")
  end
end
