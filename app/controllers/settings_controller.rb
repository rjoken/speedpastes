class SettingsController < ApplicationController
    before_action :require_login!

    def show
        @user = current_user
    end

    def import_pastebin
        file = params[:zip]
        unless file.respond_to?(:path)
            return redirect_to settings_path, alert: "Please choose a ZIP file."
        end

        result = Users::PastebinImport.call(
            user: current_user,
            zip_path: file.path,
            default_visibility: params[:default_visibility].presence || "open"
        )

        msg = "Imported #{result[:imported]} paste(s)."
        msg += "Skipped #{result[:skipped]}." if result[:skipped] > 0
        msg += "Errors: #{result[:errors].join(', ')}" if result[:errors].any?

        redirect_to settings_path, notice: msg
    rescue => e
        redirect_to settings_path, alert: "Import failed: #{e.message}"
    end

    # PATCH /settings
    def update
        user = current_user

        if user.update(profile_params)
            redirect_to settings_path, notice: "Profile updated successfully"
        else
            redirect_to settings_path, alert: user.errors.full_messages.to_sentence
        end
    end

    def avatar
        user = current_user
        user.avatar.purge_later if user.avatar.attached?
        redirect_to settings_path, notice: "Avatar removed successfully"
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

        AccountChangeMailer.confirm_change(req).deliver_now
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

        AccountChangeMailer.confirm_change(req).deliver_now
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

        AccountChangeMailer.confirm_change(req).deliver_now
        redirect_to settings_path, notice: "Please check your email to confirm the password change."
    rescue ActiveRecord::RecordInvalid => e
        redirect_to settings_path, alert: e.record.errors.full_messages.to_sentence
    end

    # PATCH /settings/revoke_session/:id
    def revoke_session
        session = current_user.user_sessions.find_by(id: params[:id], revoked_at: nil)
        if session
            session.update(revoked_at: Time.current)
            notice = "Session revoked successfully"
        else
            notice = "Session not found or already revoked"
        end
        redirect_to settings_path, notice: notice
    end

    def connect_patreon
        state = SecureRandom.hex(24)
        session[:patreon_oauth_state] = state

        authorize_uri = URI("https://www.patreon.com/oauth2/authorize")
        authorize_uri.query = URI.encode_www_form(
            response_type: "code",
            client_id: ENV["PATREON_CLIENT_ID"],
            redirect_uri: patreon_callback_url,
            scope: "identity identity.memberships",
            state: state
        )

        redirect_to authorize_uri.to_s, allow_other_host: true
    end

    def patreon_callback
        expected_state = session.delete(:patreon_oauth_state).to_s
        received_state = params[:state].to_s

        if expected_state.blank? || received_state.blank? || expected_state != received_state
            redirect_to settings_path, alert: "Invalid Patreon OAuth state. Please try again."
            return
        end

        code = params[:code].to_s
        redirect_to(settings_path, alert: "Missing Patreon authorization code") if code.blank?

        token_payload = exchange_patreon_code_for_token(code)
        identity_payload = fetch_patreon_identity(token_payload.fetch("access_token"))

        puts "Patreon identity payload: #{identity_payload.inspect}"

        patreon_user_id = identity_payload.dig("data", "id").to_s
        if patreon_user_id.blank?
            redirect_to settings_path, alert: "Failed to retrieve Patreon user ID"
            return
        end

        existing = PatreonConnection.find_by(patreon_user_id: patreon_user_id)
        if existing && existing.user_id != current_user.id
            redirect_to settings_path, alert: "This Patreon account is already connected to a user"
            return
        end

        patreon_username = identity_payload.dig("data", "attributes", "vanity").presence || identity_payload.dig("data", "attributes", "full_name").to_s || "anonymous"
        patron_status = get_patron_status(identity_payload)

        ActiveRecord::Base.transaction do
          connection = PatreonConnection.find_or_initialize_by(user: current_user)
          connection.update!(
            patreon_user_id: patreon_user_id,
            patreon_username: patreon_username,
            patron_status: patron_status,
            last_synced_at: Time.current
          )

          current_user.update!(is_supporter: true) if patron_status == "active_patron" && current_user.user?
        end

        redirect_to settings_path, notice: "Patreon account connected successfully"
    rescue KeyError
        redirect_to settings_path, alert: "Patreon connection is currently unavailable. Please try again later."
    rescue StandardError => e
        redirect_to settings_path, alert: "Failed to connect Patreon account: #{e.message}"
    end

    def disconnect_patreon
        connection = current_user.patreon_connection
        return redirect_to settings_path, alert: "No Patreon account connected" unless connection

        ActiveRecord::Base.transaction do
            connection.destroy!
            current_user.update!(is_supporter: false)
        end

        redirect_to settings_path, notice: "Patreon account disconnected successfully"
    end

    private

    def profile_params
        params.require(:user).permit(:bio, :link, :avatar, :show_view_count, :show_supporter)
    end

    def exchange_patreon_code_for_token(code)
      uri = URI("https://www.patreon.com/api/oauth2/token")
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(
        code: code,
        grant_type: "authorization_code",
        client_id: ENV["PATREON_CLIENT_ID"],
        client_secret: ENV["PATREON_CLIENT_SECRET"],
        redirect_uri: patreon_callback_url
      )

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      raise "Token exchange failed: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      body
    end

    def fetch_patreon_identity(access_token)
      uri = URI("https://www.patreon.com/api/oauth2/v2/identity?include=memberships,memberships.campaign&fields%5Bmember%5D=patron_status")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{access_token}"

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      body = JSON.parse(res.body)

      raise "Failed to fetch Patreon identity: #{res.code}" unless res.is_a?(Net::HTTPSuccess)

      body
    end

    def get_patron_status(identity_payload)
      campaign_id = ENV["PATREON_CAMPAIGN_ID"].to_s
      return nil if campaign_id.blank?

      memberships_data = Array(identity_payload.dig("data", "relationships", "memberships", "data"))
      included = Array(identity_payload["included"])

      memberships_data.each do |membership_ref|
        membership_id = membership_ref["id"]
        full_membership = included.find { |item| item["type"] == "member" && item["id"] == membership_id }

        membership_campaign_id = full_membership.dig("relationships", "campaign", "data", "id").to_s
        if membership_campaign_id == campaign_id
          status = full_membership.dig("attributes", "patron_status").to_s
          return status if status.present?
        end
      end
      nil
    end
end
