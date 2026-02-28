class UserPinsController < ApplicationController
  before_action :require_login!
  before_action :set_user
  before_action :set_paste, only: [ :create ]
  before_action :set_pin, only: [ :destroy, :update ]

  def create
    if @user != current_user || @user != @paste.user
      redirect_back fallback_location: profile_path(@user.username), alert: "You can only pin your own pastes."
      return
    end

    user_pin = @user.user_pins.new(paste: @paste, position: next_position)

    if user_pin.save
      redirect_back fallback_location: profile_path(@user.username), notice: "Paste pinned successfully."
    else
      redirect_back fallback_location: profile_path(@user.username), alert: user_pin.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @pin.user_id != current_user.id
      redirect_back fallback_location: profile_path(@user.username), alert: "You can only unpin your own pastes."
      return
    end
    @pin.destroy
    redirect_back fallback_location: profile_path(@user.username), notice: "Paste unpinned successfully."
  end

  def update
    if @pin.user_id != current_user.id
      redirect_back fallback_location: profile_path(@user.username), alert: "You can only reorder your own pins."
      return
    end

    direction = params[:direction].to_s
    unless %w[up down].include?(direction)
      redirect_back fallback_location: profile_path(@user.username), alert: "Invalid direction."
      return
    end

    target =
      case direction
      when "up"
        @user.user_pins.where("position < ?", @pin.position).reorder(position: :desc).first
      when "down"
        @user.user_pins.where("position > ?", @pin.position).reorder(position: :asc).first
      end

    if target.present?
      UserPin.transaction do
        @pin.lock!
        target.lock!

        current_position = @pin.position
        target_position = target.position
        temp_position = -1

        @pin.update!(position: temp_position)
        target.update!(position: current_position)
        @pin.update!(position: target_position)
      end
      redirect_back fallback_location: profile_path(@user.username)
    else
      redirect_back fallback_location: profile_path(@user.username), alert: "Cannot move paste #{direction}."
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_paste
    @paste = Paste.find(params[:paste_id])
  end

  def set_pin
    @pin = @user.user_pins.find(params[:id])
  end

  def next_position
    @user.user_pins.maximum(:position).to_i + 1
  end
end
