module Api
  class UsersController < BaseController
    before_action -> { require_any_scope!("users:read") }

    # GET /api/users/:id_or_username
    def show
      user = User.find_by_id_or_username(params[:id_or_username])

      raise ActiveRecord::RecordNotFound if user.nil? || user.anonymized_at.present? || user.inactive?

      open_pastes = user.pastes.where(visibility: :open)

      render json: {
        username: user.username,
        joined_at: user.created_at.iso8601,
        total_views: user.show_view_count? ? open_pastes.sum(:views) : 0,
        total_pastes: open_pastes.count,
        bio: user.bio,
        website: user.link,
        is_supporter: user.is_supporter? && user.show_supporter
      }
    end
  end
end
