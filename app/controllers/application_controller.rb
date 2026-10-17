class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate_hr_manager

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_hr_manager
    return if authenticate_with_http_basic { |username, password| valid_hr_credentials?(username, password) }

    # The React app shows its own login screen. Without the WWW-Authenticate
    # challenge header the browser won't pop up its native login dialog.
    if request.xhr?
      render json: { error: "Unauthorized" }, status: :unauthorized
    else
      request_http_basic_authentication("Salary Management")
    end
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
end
