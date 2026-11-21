module TokenDigest
  extend ActiveSupport::Concern

  class_methods do
    def digest(token)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, token)
    end
  end
end
