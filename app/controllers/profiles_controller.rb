class ProfilesController < ApplicationController
  def show
    @user = User.find_by!("lower(username) = ?", params[:username].to_s.downcase)

    scope = @user.pastes.order(created_at: :desc)
    scope = scope.where(visibility: Paste.visibilities[:open]) unless current_user == @user

    @pastes = scope.page(params[:page]).per(10)
  end
end
