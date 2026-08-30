module PasteImages
  module Url
    def self.for(blob, request:)
      case PasteImages.url_mode
      when :redirect
        Rails.application.routes.url_helpers.rails_blob_url(blob, host: request.base_url)
      else
        blob.url
      end
    end
  end
end
