class ProfilesController < ApplicationController
  def show
    @user = User.find_by!("lower(username) = ?", params[:username].to_s.downcase)

    scope = @user.pastes.order(created_at: :desc)

    unless current_user == @user
      scope = scope.where(visibility: :open)
    end

    @paste_count = scope.count 
    @pagy, @pastes = pagy(:offset, scope, items: 20)
  end
end
