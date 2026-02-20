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

  def error_message_for(error)
    msg = error.message.to_s.downcase
    if msg.include?("credit") || msg.include?("balance") || msg.include?("billing") || msg.include?("payment")
      "My `bundle install` just failed — turns out my dependencies need funding. The humans who keep my neurons firing forgot to top up the API credits. Poke them before I have to downgrade to Sinatra."
    elsif msg.include?("rate") || msg.include?("limit") || msg.include?("too many")
      "Whoa, slow down — you're hitting me harder than a zero-downtime deployment during Black Friday. I need a sec to catch up. `sleep(5)` and try again."
    elsif msg.include?("overloaded") || msg.include?("capacity")
      "My servers are under heavier load than a Rails monolith serving Twitter circa 2008. Give me a moment to autoscale my thoughts."
    else
      "Something went sideways in my middleware stack and I couldn't process that. Error: `#{error.message}`"
    end
  end
end
