class ApplicationController < ActionController::Base
  include Pagy::Method

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?, :admin?

  private
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
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
