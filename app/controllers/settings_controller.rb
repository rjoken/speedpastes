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
end