class ProfilesController < ApplicationController
  def show
    @user = User.find_by(id: params[:id_or_username]) ||
            User.find_by("lower(username) = ?", params[:id_or_username].to_s.downcase)

    raise ActiveRecord::RecordNotFound unless @user.present? && !@user.anonymized_at.present?

    if current_user&.admin? || current_user == @user
      @invite_codes = InviteCode.where(created_by_id: @user.id).order(created_at: :desc)
    end

    pastes_scope = @user.pastes.order(created_at: :desc)
    unless current_user == @user || current_user&.admin?
      pastes_scope = pastes_scope.where(visibility: :open)
    end
    @paste_count = pastes_scope.count
    @pagy, @pastes = pagy(:offset, pastes_scope, limit: 8)
  end
end