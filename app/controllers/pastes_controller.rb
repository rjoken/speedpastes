class PastesController < ApplicationController
  before_action :require_login!, except: [ :show, :raw ]
  before_action :set_paste_by_id, only: [ :edit, :update, :destroy ]
  before_action :set_paste_by_shortcode, only: [ :show ]

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
    @paste = Paste.find_by!(shortcode: params[:shortcode])
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
    redirect_to profile_path(@paste.user.id), notice: "Paste deleted"
  end

  def index
    pastes_scope = Paste.where(visibility: :open).order(created_at: :desc)
    @pagy, @pastes = pagy(:offset, pastes_scope, limit: 16)
  end

  def raw
    paste = Paste.find_by(shortcode: params[:shortcode])
    if paste
      response.headers["Content-Type"] = "text/plain; charset=utf-8"
      response.headers["Content-Disposition"] = "inline; filename=\"#{paste.title}.txt\""
      render plain: paste.body
    else
      head :not_found
    end
  end

  private

  def paste_params
    params.require(:paste).permit(:title, :body, :visibility)
  end

  def set_paste_by_id
    @paste = Paste.find(params[:id])
  end

  def set_paste_by_shortcode
    @paste = Paste.find_by!(shortcode: params[:shortcode])
  end

  def require_owner_or_admin!(paste)
    head :not_found unless current_user == paste.user || current_user&.admin?
  end

  def authorize_view!(paste)
    return if paste.open? || paste.unlisted?
    return if current_user == paste.user || current_user&.admin?

    head :not_found
  end
end
