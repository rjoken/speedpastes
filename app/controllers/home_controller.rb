class HomeController < ApplicationController
  def index
    @latest_pastes = Paste.open
                          .where(hide_frontpage: false)
                          .joins(:user)
                          .merge(User.activated)
                          .order(created_at: :desc)
                          .limit(10)

    @news_pastes = Paste.open
                        .where(user_id: 1)
                        .where("tags @> ARRAY[?]::varchar[]", "frontpage")
                        .order(created_at: :desc)
                        .limit(4)

    if signed_in?
      @paste = current_user.pastes.new
    end

    @stats = {
      pastes_count: Paste.count,
      users_count: User.activated.count
    }
  end
end
