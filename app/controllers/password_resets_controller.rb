class PasswordResetsController < ApplicationController
    def new
    end

    def create
        email = params[:email].to_s.strip
        user = User.find_by("lower(email) = ?", email)

        if user.present? && user.anonymized_at.blank?
            user.account_change_requests.where(kind: :password_reset, used_at: nil).update_all(used_at: Time.current)

            req = user.account_change_requests.create!(
                kind: :password_reset,
                expires_at: 2.hours.from_now
            )

            AccountChangeMailer.confirm_change(req).deliver_now
        end
        redirect_to root_path, notice: "If an account with that email exists, a password reset link has been sent."
    end

    def edit
        @token = params[:token].to_s
        @req = AccountChangeRequest.find_signed(@token, purpose: :account_change)

        unless @req&.kind.to_sym == :password_reset && @req&.usable?
            redirect_to new_password_reset_path, alert: "The password reset link is invalid or has expired."
        end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
        redirect_to new_password_reset_path, alert: "The password reset link is invalid or has expired."
    end

    def update
        token = params[:token].to_s
        req = AccountChangeRequest.find_signed(token, purpose: :account_change)

        unless req&.kind.to_sym == :password_reset && req&.usable?
            return redirect_to new_password_reset_path, alert: "The password reset link is invalid or has expired."
        end

        pw = params[:password].to_s
        pw_conf = params[:password_confirmation].to_s

        unless pw.present? && pw == pw_conf
            @token = token
            @req = req
            flash.now[:alert] = "Password and confirmation do not match"
            return render :edit, status: :unprocessable_entity
        end

        user = req.user
        user.update!(password: pw, password_confirmation: pw_conf)

        req.update!(used_at: Time.current)

        user.user_sessions.active.update_all(revoked_at: Time.current) if user.respond_to?(:user_sessions)

        redirect_to login_path, notice: "Your password has been reset successfully. Please log in."
    rescue ActiveSupport::MessageVerifier::InvalidSignature
        redirect_to new_password_reset_path, alert: "The password reset link is invalid or has expired."
    end
end
