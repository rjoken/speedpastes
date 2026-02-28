class PastesController < ApplicationController
  include TagsHelper
  before_action :require_login!, except: [ :show, :raw, :index ]
  before_action :set_paste_by_id, only: [ :edit, :update, :destroy ]
  before_action :set_paste_by_shortcode, only: [ :show, :raw ]

  def new
    @paste = current_user.pastes.new
  end

  def create
    @paste = current_user.pastes.new(paste_params)
    if @paste.title.blank? then @paste.title = @paste.body.split.first(5).join(" ") end
    if @paste.save
      redirect_to short_paste_path(@paste.shortcode)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize_view!(@paste)
    # Initialize viewed pastes in session
    session[:viewed_pastes] ||= {}

    # Increment view count if not already viewed in this session
    unless session[:viewed_pastes][@paste.id.to_s]
      @paste.increment!(:views) if session[:viewed_pastes].nil? || !session[:viewed_pastes][@paste.id.to_s]
      session[:viewed_pastes][@paste.id.to_s] = true
    end
  end

  def edit
    require_owner_or_admin!(@paste)
  end

  def update
    require_owner_or_admin!(@paste)
    if @paste.update(paste_params)
      redirect_to short_paste_path(@paste.shortcode)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    require_owner_or_admin!(@paste)
    @paste.destroy
    # Redirect to the user's profile after deletion if on profile page
    if params[:context] == "profile"
      redirect_to profile_path(@paste.user.id), notice: "Paste deleted", status: :see_other
    else
      redirect_to pastes_path, notice: "Paste deleted", status: :see_other
    end
  end

  def index
    pastes_scope = Paste.where(visibility: :open)

    @all_tags = pastes_scope
      .where.not(tags: nil)
      .pluck(:tags)
      .flatten
      .map { |t| t.to_s.strip.downcase }
      .reject(&:blank?)
      .tally
      .sort_by { |tag, count| [ -count, tag ] }
      .first(50)
      .map(&:first)

    @selected_tags = normalize_tags(params[:tags])
    if @selected_tags.any?
      # PostgreSQL '&&' operator means 'array overlap' so we get OR behavior
      pastes_scope = pastes_scope.where("tags::text[] && ARRAY[?]::text[]", @selected_tags)
    end

    if params[:q].present?
      query = params[:q].strip.downcase
      pastes_scope = pastes_scope.where("lower(title) LIKE ? OR lower(body) LIKE ?", "%#{query}%", "%#{query}%")
    end

    case params[:sort]
    when "old"
      pastes_scope = pastes_scope.order(created_at: :asc)
    when "new"
      pastes_scope = pastes_scope.order(created_at: :desc)
    when "views"
      pastes_scope = pastes_scope.order(views: :desc)
    else
      pastes_scope = pastes_scope.order(created_at: :desc)
    end
    @pagy, @pastes = pagy(:offset, pastes_scope, limit: 16)
  end

  def raw
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    response.headers["Content-Disposition"] = "inline; filename=\"#{@paste.title}.txt\""
    render plain: @paste.body
  end

  private

  def paste_params
    permitted = params.require(:paste).permit(:title, :body, :visibility, :tags)
    permitted[:tags] = normalize_tags(permitted[:tags]) if permitted[:tags].present?
    permitted
  end

  def set_paste_by_id
    @paste = Paste.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @paste.present?
  end

  def set_paste_by_shortcode
    @paste = Paste.find_by(shortcode: params[:shortcode])
    raise ActiveRecord::RecordNotFound unless @paste.present?
  end

  def require_owner_or_admin!(paste)
    raise ActiveRecord::RecordNotFound unless current_user == paste.user || current_user&.admin?
  end

  def authorize_view!(paste)
    return if paste.open? || paste.unlisted?
    return if current_user == paste.user || current_user&.admin?

    raise ActiveRecord::RecordNotFound
  end
end
