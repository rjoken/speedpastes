class PastesController < ApplicationController
  before_action :require_login!, except: [:show]
  before_action :set_paste_by_id, only: [:edit, :update, :destroy]
  before_action :set_paste_by_shortcode, only: [:show]

  def new
    @paste = current_user.pastes.new
  end

  def create
    @paste = current_user.pastes.new(paste_params)
    if @paste.title.blank? then @paste.title = "Untitled paste" end
    if @paste.save
      redirect_to short_paste_path(@paste.shortcode)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize_view!(@paste)
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
    redirect_to profile_path(@paste.user.username), notice: "Paste deleted"
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
    head :not_found unless (current_user == paste.user || current_user&.admin?)
  end

  def authorize_view!(paste)
    return if paste.open? || paste.unlisted?
    return if current_user == paste.user || current_user&.admin?

    head :not_found
  end
end
