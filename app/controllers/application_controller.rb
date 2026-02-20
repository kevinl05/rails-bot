class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate

  private

  def authenticate
    return unless ENV["AUTH_PASSWORD"].present?

    authenticate_or_request_with_http_basic("RailsBot") do |_user, password|
      ActiveSupport::SecurityUtils.secure_compare(password, ENV["AUTH_PASSWORD"])
    end
  end
end
