class ProfilesController < ApplicationController
  def show
    @user = User.find_by("lower(username) = ?", params[:username].to_s.downcase)

    raise ActiveRecord::RecordNotFound unless @user.present? && !@user.anonymized_at.present?

    if current_user&.admin? || current_user == @user
      @invite_codes = InviteCode.where(created_by_id: @user.id).order(created_at: :desc)
    end

    scope = @user.pastes.order(created_at: :desc)

    unless current_user == @user || current_user&.admin?
      scope = scope.where(visibility: :open)
    end

    @paste_count = scope.count
    @pagy, @pastes = pagy(:offset, scope, limit: 8)
  end
end
