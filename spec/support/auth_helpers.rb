module AuthHelpers
  def auth_headers(username: Rails.configuration.x.hr_auth.username, password: Rails.configuration.x.hr_auth.password)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
