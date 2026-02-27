class UserPinsController < ApplicationController
  before_action :require_login!

  def create
    paste = Paste.find(params[:paste_id])
    user_pin = current_user.user_pins.new(paste: paste, position: next_position)

    if user_pin.save
      redirect_back fallback_location: profile_path(current_user.username), notice: "Paste pinned successfully."
    else
      redirect_back fallback_location: profile_path(current_user.username), alert: user_pin.errors.full_messages.to_sentence
    end
  end

  def destroy
    user_pin = current_user.user_pins.find(params[:id])
    user_pin.destroy
    redirect_back fallback_location: profile_path(current_user.username), notice: "Paste unpinned successfully."
  end

  private

  def next_position
    current_user.user_pins.maximum(:position).to_i + 1
  end
end
