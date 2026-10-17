class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :authenticate_hr_manager

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_hr_manager
    expected = Rails.configuration.x.hr_auth

    authenticate_or_request_with_http_basic("Salary Management") do |username, password|
      next false if expected.username.blank? || expected.password.blank?

      # Both comparisons always run, so the response time doesn't reveal which one failed.
      username_ok = ActiveSupport::SecurityUtils.secure_compare(username, expected.username)
      password_ok = ActiveSupport::SecurityUtils.secure_compare(password, expected.password)
      username_ok && password_ok
    end
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
