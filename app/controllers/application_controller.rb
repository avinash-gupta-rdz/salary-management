class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate_hr_manager
  before_action :require_json_body

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ExchangeRate::Missing, with: :render_missing_exchange_rate

  private

  # Never sends a WWW-Authenticate challenge. A challenge makes the browser cache
  # the credentials and attach them to any request to this host, including
  # forged cross-site form posts (CSRF). The React app and curl -u both send the
  # Authorization header themselves, so they don't need one.
  def authenticate_hr_manager
    return if authenticate_with_http_basic { |username, password| valid_hr_credentials?(username, password) }

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  # Second CSRF layer: a cross-site HTML form can only send form-encoded or
  # multipart bodies, never application/json.
  def require_json_body
    return unless request.post? || request.patch? || request.put?
    return if request.media_type == "application/json"

    render json: { error: "Content-Type must be application/json" }, status: :unsupported_media_type
  end

  def valid_hr_credentials?(username, password)
    expected = Rails.configuration.x.hr_auth
    return false if expected.username.blank? || expected.password.blank?

    # Both comparisons always run, so the response time doesn't reveal which one failed.
    username_ok = ActiveSupport::SecurityUtils.secure_compare(username, expected.username)
    password_ok = ActiveSupport::SecurityUtils.secure_compare(password, expected.password)
    username_ok && password_ok
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  # A configuration problem, not a client error: log it and say so plainly.
  def render_missing_exchange_rate(exception)
    Rails.logger.error("[exchange_rates] #{exception.message}")
    render json: { error: exception.message }, status: :internal_server_error
  end
end
