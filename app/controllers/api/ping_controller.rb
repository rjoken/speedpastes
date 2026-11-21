module Api
  class PingController < BaseController
    before_action -> { require_any_scope!(*READ_SCOPES) }

    # GET /api/ping
    def show
      render json: { message: "pong" }
    end
  end
end
