class SettingsController < ApplicationController
    before_action :require_login!

    def show
        @user = current_user
    end

    # POST /settings/data_export
    def data_export
        zip_path, zip_filename = Users::ZipExport.call(user: current_user)

        send_data File.binread(zip_path), filename: zip_filename, type: "application/zip", disposition: "attachment"
    ensure
        File.delete(zip_path) if zip_path && File.exist?(zip_path)
    end

    # DELETE /settings/account
    def account
        user = current_user

        unless user.authenticate(params[:password].to_s)
            return redirect_to settings_path, alert: "Incorrect password"
        end

        Users::Anonymize.call(user: user)

        reset_session
        redirect_to root_path, notice: "Your account has been deleted"
    end

    def username
        user = current_user
        unless user.authenticate(params[:current_password].to_s)
            return redirect_to settings_path, alert: "Incorrect current password"
        end

        new_username = params[:new_username].to_s.strip
        req = AccountChangeRequest.create!(
            user: user,
            kind: :username,
            new_username: new_username,
            expires_at: 2.hours.from_now
        )

        AccountChangeMailer.confirm_change(req).deliver_later
        redirect_to settings_path, notice: "Please check your email to confirm the username change."

    rescue ActiveRecord::RecordInvalid => e
        redirect_to settings_path, alert: e.record.errors.full_messages.to_sentence
    end

    def email
        user = current_user
        unless user.authenticate(params[:current_password].to_s)
            return redirect_to settings_path, alert: "Incorrect current password"
        end

        new_email = params[:new_email].to_s.strip.downcase
        req = AccountChangeRequest.create!(
            user: user,
            kind: :email,
            new_email: new_email,
            expires_at: 2.hours.from_now
        )

        AccountChangeMailer.confirm_change(req).deliver_later
        redirect_to settings_path, notice: "Please check your new email to confirm the email change."
    rescue ActiveRecord::RecordInvalid => e
        redirect_to settings_path, alert: e.record.errors.full_messages.to_sentence
    end

    def password
        user = current_user
        unless user.authenticate(params[:current_password].to_s)
            return redirect_to settings_path, alert: "Incorrect current password"
        end

        new_password = params[:new_password].to_s
        new_password_confirmation = params[:new_password_confirmation].to_s

        unless new_password == new_password_confirmation
            return redirect_to settings_path, alert: "New password and confirmation do not match"
        end

        new_password_digest = BCrypt::Password.create(new_password)

        req = AccountChangeRequest.create!(
            user: user,
            kind: :password,
            new_password_digest: new_password_digest,
            expires_at: 2.hours.from_now
        )

        AccountChangeMailer.confirm_change(req).deliver_later
        redirect_to settings_path, notice: "Please check your email to confirm the password change."
    rescue ActiveRecord::RecordInvalid => e
        redirect_to settings_path, alert: e.record.errors.full_messages.to_sentence
    end
end