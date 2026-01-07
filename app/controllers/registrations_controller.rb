class RegistrationsController < ApplicationController
  def new
  end

  def create
    invite = InviteCode.lock.find_by(code: params[:invite_code].to_s)

    if invite.nil? || !invite.usable?
      flash.now[:alert] = "Invalid invite code"
      return render :new, status: :unprocessable_entity
    end

    user = User.new(
      email: params[:email],
      username: params[:username],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    User.transaction do
      user.save!
      invite.update!(used_by: user, used_at: Time.current, uses_count: invite.uses_count + 1)

      if invite.created_by.present?
        user.update!(invited_by: invite.created_by)
      end
    end

    InviteCodes::Generate.call(user: user, count: 5)

    sign_in(user)
    redirect_to root_path

  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = user.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end
end
