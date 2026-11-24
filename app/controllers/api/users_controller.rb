module Api
  class UsersController < BaseController
    before_action -> { require_any_scope!("users:read") }

    # GET /api/users/:id_or_username
    def show
      user = find_public_user!(params[:id_or_username])

      open_pastes = user.pastes.where(visibility: :open)

      render json: {
        username: user.username,
        joined_at: user.created_at.iso8601,
        total_views: user.show_view_count? ? open_pastes.sum(:views) : 0,
        total_pastes: open_pastes.count,
        bio: user.bio,
        website: user.safe_link,
        is_supporter: user.is_supporter? && user.show_supporter
      }
    end
  end
end
