class UserpagesController < ApplicationController
  before_action :require_login!
  before_action :require_activated!
  before_action :set_paste, only: [ :create, :update ]

  def create
    unless current_user.is_supporter?
      redirect_back fallback_location: profile_path(current_user.username), alert: "Only supporters can set a userpage."
    end

    if @paste.user_id != current_user.id
      redirect_back fallback_location: profile_path(current_user.username), alert: "Userpage must be your own paste."
    end

    userpage = current_user.userpage || current_user.build_userpage
    userpage.paste = @paste

    if userpage.save
      redirect_back fallback_location: profile_path(current_user.username), notice: "Userpage set successfully."
    else
      redirect_back fallback_location: profile_path(current_user.username), alert: userpage.errors.full_messages.to_sentence
    end
  end

  def update
    userpage = current_user.userpage
    if userpage.nil?
      redirect_back fallback_location: profile_path(current_user.username), alert: "Must first create a userpage"
    end

    userpage.paste = @paste
    if userpage.save
      redirect_back fallback_location: profile_path(current_user.username), notice: "Userpage updated successfully."
    else
      redirect_back fallback_location: profile_path(current_user.username), alert: userpage.errors.full_messages.to_sentence
    end
  end

  def destroy
    userpage = current_user.userpage

    unless userpage
      redirect_back fallback_location: profile_path(current_user.username), alert: "No userpage to remove."
      return
    end

    userpage.destroy
    redirect_back fallback_location: profile_path(current_user.username), notice: "Userpage removed successfully."
  end

  private
  def set_paste
    @paste = Paste.find_by(id: params[:paste_id])
    unless @paste
      redirect_back fallback_location: profile_path(current_user.username), alert: "Paste not found."
    end
  end
end
