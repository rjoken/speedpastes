module Api
  class ScratchpadsController < BaseController
    before_action -> { require_any_scope!("scratchpad:read") }, only: :show
    before_action -> { require_any_scope!("scratchpad:write") }, only: [ :create, :update ]
    before_action :set_scratchpad

    # GET /api/scratchpad
    def show
      render_scratchpad
    end

    # POST /api/scratchpad appends to the body on a new line
    def create
      text = body_from_request
      raise BadRequest, "body must not be empty" if text.empty?

      # Locked so concurrent appends don't overwrite each other
      saved = @scratchpad.with_lock do
        separator = (@scratchpad.body.empty? || @scratchpad.body.end_with?("\n")) ? "" : "\n"
        @scratchpad.body += separator + text
        @scratchpad.save
      end

      saved ? render_scratchpad : render_validation_error
    end

    # PATCH /api/scratchpad replaces the body
    def update
      @scratchpad.update(body: body_from_request) ? render_scratchpad : render_validation_error
    end

    private

    def set_scratchpad
      @scratchpad = current_user.build_scratchpad
    end

    def body_from_request
      attrs = json_body
      raise BadRequest, "Request body must be an object with only a body field" unless attrs.is_a?(Hash) && attrs.keys == [ "body" ]
      raise BadRequest, "body must be a string" unless attrs["body"].is_a?(String)

      attrs["body"]
    end

    def render_scratchpad
      render json: {
        body: @scratchpad.body,
        created_at: @scratchpad.created_at.iso8601,
        updated_at: @scratchpad.updated_at.iso8601
      }
    end

    def render_validation_error
      render_error("Validation failed", :unprocessable_entity, details: @scratchpad.errors.to_hash)
    end
  end
end
