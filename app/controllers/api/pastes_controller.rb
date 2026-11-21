module Api
  class PastesController < BaseController
    include TagsHelper

    FIELD_TYPES = {
      "title" => ->(v) { v.nil? || v.is_a?(String) },
      "body" => ->(v) { v.is_a?(String) },
      "visibility" => ->(v) { v.is_a?(String) },
      "render_type" => ->(v) { v.is_a?(String) },
      "tags" => ->(v) { v.is_a?(String) || (v.is_a?(Array) && v.all?(String)) },
      "hide_frontpage" => ->(v) { v == true || v == false },
      "collaborators" => ->(v) { v.is_a?(Array) && v.all?(Integer) }
    }.freeze

    TAG_OPERATORS = { "or" => "&&", "and" => "@>" }.freeze

    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100
    MAX_BATCH_SIZE = 25

    # create throttles itself so a batch costs one per paste
    skip_before_action :throttle!, only: :create
    before_action -> { require_any_scope!("pastes:read") }, only: [ :index, :show ]
    before_action -> { require_any_scope!("pastes:write") }, only: [ :create, :update, :destroy ]
    before_action :set_paste, only: [ :show, :update, :destroy ]

    # GET /api/pastes?user=&tags=&tag_filtering=&unlisted=&page=&per_page=
    def index
      per_page = integer_param(:per_page, default: DEFAULT_PER_PAGE, max: MAX_PER_PAGE)
      page = integer_param(:page, default: 1)

      pagy, pastes = pagy(:offset, filtered_pastes.includes(:user).order(created_at: :desc), limit: per_page, page: page)

      render json: {
        pastes: serialize(pastes),
        page: pagy.page,
        pages: pagy.pages,
        per_page: per_page,
        count: pagy.count
      }
    end

    # GET /api/pastes/:shortcode
    def show
      render json: serialize([ @paste ]).first
    end

    # POST /api/pastes with a paste object, or an array of them
    def create
      body = json_body
      batch = body.is_a?(Array)
      items = Array.wrap(body)

      raise BadRequest, "Request body must be a paste object or an array of them" if items.empty? || !items.all?(Hash)
      raise BadRequest, "Cannot create more than #{MAX_BATCH_SIZE} pastes at once" if items.size > MAX_BATCH_SIZE

      throttle!(cost: items.size)
      return if performed?

      pastes = items.each_with_index.map do |attrs, index|
        context = batch ? " (paste #{index})" : ""
        raise BadRequest, "body is required#{context}" unless attrs.key?("body")

        paste = current_user.pastes.new(paste_attributes(attrs, context))
        paste.title = paste.default_title if paste.title.blank?
        paste
      end

      errors = pastes.each_with_index.filter_map { |paste, index| { index: index, errors: paste.errors.to_hash } unless paste.valid? }
      if errors.any?
        return render_error("Validation failed", :unprocessable_entity, details: batch ? errors : errors.first[:errors])
      end

      Paste.transaction { pastes.each(&:save!) }

      json = serialize(pastes)
      render json: batch ? json : json.first, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render_error("Validation failed", :unprocessable_entity, details: e.record.errors.to_hash)
    end

    # PATCH /api/pastes/:shortcode
    def update
      authorize!(@paste.editable_by?(current_user))

      attrs = json_body
      raise BadRequest, "Request body must be a non-empty paste object" unless attrs.is_a?(Hash) && attrs.any?
      raise Forbidden, "Only the paste owner can change collaborators" if attrs.key?("collaborators") && !@paste.owned_by?(current_user)

      if @paste.update(paste_attributes(attrs))
        render json: serialize([ @paste ]).first
      else
        render_error("Validation failed", :unprocessable_entity, details: @paste.errors.to_hash)
      end
    end

    # DELETE /api/pastes/:shortcode
    def destroy
      authorize!(@paste.deletable_by?(current_user))

      @paste.destroy!
      head :no_content
    end

    private

    # Covers reads and writes, so admins can't reach unlisted pastes they aren't part of
    def set_paste
      @paste = active_author_pastes.includes(:user).find_by!(shortcode: params[:shortcode])
      raise ActiveRecord::RecordNotFound unless viewable?(@paste)
    end

    def active_author_pastes
      Paste.joins(:user).where(users: { role: User::ACTIVATED_ROLES })
    end

    # Admins get no extra read access through the API
    def viewable?(paste)
      paste.open? || paste.owned_by?(current_user) || paste.collaborator?(current_user)
    end

    def authorize!(allowed)
      raise Forbidden, "You do not have permission to modify this paste" unless allowed
    end

    def filtered_pastes
      scope = active_author_pastes

      if params[:user].present?
        user = User.find_by_id_or_username(params[:user])
        raise ActiveRecord::RecordNotFound if user.nil? || user.anonymized_at.present? || user.inactive?

        scope = scope.where(user: user)
      end

      scope = if boolean_param(:unlisted)
        scope.where(
          "pastes.visibility = :open OR pastes.user_id = :me OR :me = ANY(pastes.collaborators)",
          open: Paste.visibilities[:open], me: current_user.id
        )
      else
        scope.where(visibility: :open)
      end

      raise BadRequest, "tags must be a comma-separated string" unless params[:tags].nil? || params[:tags].is_a?(String)

      tags = normalize_tags(params[:tags])
      return scope if tags.empty?

      operator = TAG_OPERATORS.fetch(params[:tag_filtering] || "or") { raise BadRequest, "tag_filtering must be or or and" }
      scope.where("pastes.tags::text[] #{operator} ARRAY[?]::text[]", tags)
    end

    def paste_attributes(attrs, context = "")
      unknown = attrs.keys - FIELD_TYPES.keys
      raise BadRequest, "Unknown field(s)#{context}: #{unknown.join(', ')}" if unknown.any?

      invalid = attrs.reject { |key, value| FIELD_TYPES[key].call(value) }.keys
      raise BadRequest, "Invalid type for field(s)#{context}: #{invalid.join(', ')}" if invalid.any?

      attrs = attrs.dup
      attrs["tags"] = normalize_tags(attrs["tags"]) if attrs.key?("tags")
      attrs["collaborators"] = Paste.collaborator_ids_for(attrs["collaborators"], owner: current_user) if attrs.key?("collaborators")
      attrs
    end

    def serialize(pastes)
      collaborator_ids = pastes.flat_map(&:collaborators).uniq
      usernames = User.activated.where(id: collaborator_ids, anonymized_at: nil).pluck(:id, :username).to_h

      pastes.map do |paste|
        {
          shortcode: paste.shortcode,
          title: paste.title,
          body: paste.body,
          visibility: paste.visibility,
          render_type: paste.render_type,
          tags: paste.tags || [],
          hide_frontpage: paste.hide_frontpage,
          views: (paste.user.show_view_count? || paste.owned_by?(current_user)) ? paste.views : 0,
          author: paste.user.username,
          collaborators: paste.collaborators.filter_map { |id| { id: id, username: usernames[id] } if usernames.key?(id) },
          created_at: paste.created_at.iso8601,
          edited_at: paste.edited_at&.iso8601,
          url: short_paste_url(paste.shortcode),
          raw_url: raw_paste_url(paste.shortcode)
        }
      end
    end
  end
end
