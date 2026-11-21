module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    READ_SCOPES = ApiToken::SCOPES.select { |scope| scope.end_with?(":read") }.freeze

    before_action :authenticate_api_token!

    # Must stay below authenticate_api_token! so current_user is set
    rate_limit to: 120, within: 1.minute, scope: "api", name: "read",
      by: -> { current_user.id }, with: -> { render_rate_limited }, if: :read_request?
    rate_limit to: 30, within: 1.minute, scope: "api", name: "write",
      by: -> { current_user.id }, with: -> { render_rate_limited }, unless: :read_request?

    private

    attr_reader :current_api_token

    def current_user
      current_api_token&.user
    end

    def authenticate_api_token!
      @current_api_token = authenticate_with_http_token do |raw_token, _options|
        ApiToken.active.includes(:user).find_by(token_digest: ApiToken.digest(raw_token))
      end

      unless current_api_token
        headers["WWW-Authenticate"] = 'Bearer realm="speedpastes"'
        return render_error("Missing, invalid, expired, or revoked API token", :unauthorized)
      end

      return render_error("Your account does not have permission to use the API", :forbidden) unless current_user.activated?

      if current_api_token.last_used_at.nil? || current_api_token.last_used_at < 15.minutes.ago
        current_api_token.update_column(:last_used_at, Time.current)
      end
    end

    def require_any_scope!(*scopes)
      return if scopes.any? { |scope| current_api_token.allows?(scope) }

      render_error("API token requires one of these scopes: #{scopes.join(', ')}", :forbidden)
    end

    def read_request?
      request.get? || request.head?
    end

    def render_rate_limited
      render_error("Rate limit exceeded", :too_many_requests)
    end

    def render_error(message, status)
      render json: { error: message }, status: status
    end
  end
end
