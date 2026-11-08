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
      patron_id = data.dig("data", "relationships", "user", "data", "id")
      connection = PatreonConnection.find_by(patreon_user_id: patron_id) if patron_id.present?

      if connection
        status = status_for_event(request.headers["X-Patreon-Event"], data)
        connection.sync_patron_status!(status) unless status == :unchanged
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    # A null status means "no payment yet", so don't revoke an existing status.
    def status_for_event(event, data)
      case event
      when "members:pledge:delete"
        "former_patron"
      when "members:delete"
        nil
      when "members:create", "members:update", "members:pledge:create", "members:pledge:update"
        data.dig("data", "attributes", "patron_status").presence || :unchanged
      else
        :unchanged
      end
    end

    def valid_patreon_signature?(payload, signature)
      secret = ENV["PATREON_WEBHOOK_SECRET"].to_s
      return false if secret.blank? || signature.blank?

      # Patreon's choice to use MD5, not mine :P
      expected = OpenSSL::HMAC.hexdigest("MD5", secret, payload)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end
  end
end
