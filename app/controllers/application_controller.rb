class ApplicationController < ActionController::Base
  include Pagy::Method

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?, :admin?

  before_action :load_current_user

  private

  def load_current_user
    token = cookies.encrypted[:auth_session]
    return unless token.present?

    digest = UserSession.digest(token)
    @current_user_session = UserSession.active.includes(:user).find_by(token_digest: digest)

    if @current_user_session
      @current_user = @current_user_session.user

      if @current_user_session.last_seen_at.nil? || @current_user_session.last_seen_at < 15.minutes.ago
        @current_user_session.update(:last_seen_at, Time.current)
      end
    else
      cookies.delete(:auth_session)
    end
  end

  def current_user
    @current_user
  end

  def signed_in?
    current_user.present?
  end

  def require_login!
    redirect_to login_path, alert: "Please log in" unless signed_in?
  end

  def admin?
    current_user&.admin?
  end
end
