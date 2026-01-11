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

    @total_views = pastes_scope.sum(:views)
    @paste_count = pastes_scope.count
    @pagy, @pastes = pagy(:offset, pastes_scope, limit: 8)
  end

  def index
    open_visibility = Paste.visibilities[:open]
    open_paste_count_sql = "COALESCE(SUM(CASE WHEN pastes.visibility = ? THEN 1 ELSE 0 END), 0)"
    open_views_count_sql = "COALESCE(SUM(CASE WHEN pastes.visibility = ? THEN pastes.views ELSE 0 END), 0)"
    users_scope = User.where(anonymized_at: nil)
      .left_joins(:pastes)
      .select(
        "users.*,
        #{ActiveRecord::Base.send(:sanitize_sql_array, [open_paste_count_sql, open_visibility])} AS open_paste_count,
        #{ActiveRecord::Base.send(:sanitize_sql_array, [open_views_count_sql, open_visibility])} AS open_views_count"
      ).group(:id)

    case params[:sort]
    when "old"
      users_scope = users_scope.order(created_at: :asc)
    when "new"
      users_scope = users_scope.order(created_at: :desc)
    when "pastes"
      users_scope = users_scope.order(Arel.sql("#{open_paste_count_sql} DESC"))
    when "views"
      users_scope = users_scope.order(Arel.sql("#{open_views_count_sql} DESC"))
    else
      users_scope = users_scope.order(created_at: :desc)
    end

    @pagy, @users = pagy(:offset, users_scope, limit: 16)
  end
end
