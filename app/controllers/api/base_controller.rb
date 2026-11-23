module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods
    include Pagy::Method

    class BadRequest < StandardError; end
    class Forbidden < StandardError; end

    READ_SCOPES = ApiToken::SCOPES.select { |scope| scope.end_with?(":read") }.freeze
    RATE_LIMITS = { read: 120, write: 30 }.freeze

    before_action :authenticate_api_token!
    before_action :require_json_content_type!, if: -> { request.post? || request.patch? || request.put? }
    before_action :throttle!
    before_action :reject_invalid_url_params!

    rescue_from ActiveRecord::RecordNotFound, with: -> { render_error("Not found", :not_found) }
    rescue_from BadRequest, with: ->(e) { render_error(e.message, :bad_request) }
    rescue_from Forbidden, with: ->(e) { render_error(e.message, :forbidden) }
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: -> { render_error("Invalid JSON", :bad_request) }
    rescue_from ActionController::BadRequest, with: -> { render_error("Invalid request parameters", :bad_request) }

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

    # Fixed one-minute window per user, shared across all API endpoints.
    # cost lets a batch request count once per item.
    def throttle!(cost: 1)
      kind = read_request? ? :read : :write
      count = Rails.cache.increment("api-rate-limit:#{kind}:#{current_user.id}", cost, expires_in: 1.minute)

      render_error("Rate limit exceeded", :too_many_requests) if count && count > RATE_LIMITS[kind]
    end

    def read_request?
      request.get? || request.head?
    end

    def require_any_scope!(*scopes)
      return if scopes.any? { |scope| current_api_token.allows?(scope) }

      render_error("API token requires one of these scopes: #{scopes.join(', ')}", :forbidden)
    end

    def boolean_param(key)
      case params[key]
      when nil, "false" then false
      when "true" then true
      else raise BadRequest, "#{key} must be true or false"
      end
    end

    def page_param(count:, per_page:)
      last_page = [ (count.to_f / per_page).ceil, 1 ].max
      params[:page].to_s.to_i.clamp(1, last_page)
    end

    def integer_param(key, default:, max: nil)
      value = params[key]
      return default if value.nil?
      raise BadRequest, "#{key} must be a positive integer" unless value.to_s.match?(/\A[1-9]\d*\z/)

      value = value.to_i
      raise BadRequest, "#{key} must be at most #{max}" if max && value > max

      value
    end

    def json_body
      body = JSON.parse(request.raw_post)
      check_strings!(body, "Request body")
      body
    rescue JSON::ParserError
      raise BadRequest, "Request body must be valid JSON"
    end

    def require_json_content_type!
      return if request.media_type == "application/json"

      render_error("Content-Type must be application/json", :unsupported_media_type)
    end

    def reject_invalid_url_params!
      check_strings!(request.query_parameters, "Query parameters")
      check_strings!(request.path_parameters, "URL")
    end
    
    def check_strings!(value, source)
      error = SafeTextValidator.error_for(value)
      raise BadRequest, "#{source} #{error}" if error
    end

    def render_error(message, status, details: nil)
      render json: { error: message, details: details }.compact, status: status
    end
  end
end
