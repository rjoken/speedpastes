class HomeController < ApplicationController
  def index
    @latest_pastes = Paste.open
                          .joins(:user)
                          .merge(User.activated)
                          .order(created_at: :desc)
                          .limit(10)

    if signed_in?
      @paste = current_user.pastes.new
    end

    @stats = {
      pastes_count: Paste.count,
      users_count: User.activated.count
    }
  end
end
