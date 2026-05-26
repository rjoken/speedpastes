module Webhooks
  class PatreonController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.raw_post
      signature = request.headers["X-Patreon-Signature"].to_s

      unless valid_patreon_signature?(payload, signature)
        head :unauthorized
        return
      end

      data = JSON.parse(payload)

      event = request.headers["X-Patreon-Event"]
      case event
      when "members:create", "members:update", "members:pledge:create", "members:pledge:update"
        patron_id = data.dig("data", "relationships", "user", "data", "id")
        patron_status = data.dig("data", "attributes", "patron_status").to_s
        connection = PatreonConnection.find_by(patreon_user_id: patron_id)
        if connection
          connection.update!(last_synced_at: Time.current, patron_status: patron_status)
          user = connection.user
          if user && patron_status != "active_patron"
            user.update!(is_supporter: false)
          elsif user && patron_status == "active_patron"
            user.update!(is_supporter: true)
          end
        end
      when "members:delete"
        patron_id = data.dig("data", "relationships", "user", "data", "id")
        connection = PatreonConnection.find_by(patreon_user_id: patron_id)
        if connection
          connection.update!(last_synced_at: Time.current, patron_status: nil)
          user = connection.user
          user.update!(is_supporter: false) if user
        end
      end
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def valid_patreon_signature?(payload, signature)
      secret = ENV["PATREON_WEBHOOK_SECRET"].to_s
      return false if secret.blank? || signature.blank?

      # Patreon's choice to use MD5, not mine :P
      expected = OpenSSL::HMAC.hexdigest("MD5", secret, payload)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end
  end
end
