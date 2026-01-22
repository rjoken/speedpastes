class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by("lower(email) = ?", params[:email].to_s.downcase)
    if user&.anonymized_at.present?
      flash.now[:alert] = "Invalid email or password"
      return render :new, status: :unprocessable_entity
    end
    if user&.authenticate(params[:password])
      token = SecureRandom.urlsafe_base64(32)
      digest = UserSession.digest(token)

      user_session = user.user_sessions.create!(
        token_digest: digest,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        last_seen_at: Time.current,
        expires_at: 30.days.from_now
      )

      user.update!(
        last_sign_in_at: Time.current,
        last_sign_in_ip: request.remote_ip
      )

      cookies.encrypted[:auth_session] = {
        value: token,
        expires: user_session.expires_at,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }

      reset_session
      redirect_to root_path, notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    token = cookies.encrypted[:auth_session]
    if token.present?
      digest = UserSession.digest(token)
      UserSession.find_by(token_digest: digest, revoked_at: nil).update_all(revoked_at: Time.current)
    end

    cookies.delete(:auth_session)
    reset_session
    redirect_to root_path, notice: "Signed out successfully"
  end
end
