module PasteImages
  class Upload
    MAX_BYTES = 10.megabytes
    USER_QUOTA = 250.megabytes
    ALLOWED = %w[image/png image/jpeg image/gif image/webp].freeze
    EXTENSIONS = { "image/png" => "png", "image/jpeg" => "jpg", "image/gif" => "gif", "image/webp" => "webp" }.freeze

    Result = Struct.new(:ok, :blob, :error, :status, keyword_init: true) do
      def ok? = ok
    end

    def self.call(user:, file:)
      new(user:, file:).call
    end

    def initialize(user:, file:)
      @user = user
      @file = file
      @attempts = 0
    end

    def call
      return failure("No image provided", :bad_request) unless uploaded_file?
      return failure("The file is empty", :bad_request) if @file.size.zero?
      return failure("The file is too large (max #{MAX_BYTES / 1.megabyte}MB)", :content_too_large) if @file.size > MAX_BYTES

      # No name: hint on purpose. Marcel falls back to the filename when the magic
      # bytes are inconclusive, which would let any .png-named text file through.
      content_type = Marcel::MimeType.for(@file)
      return failure("Unsupported file type", :unsupported_media_type) unless ALLOWED.include?(content_type)
      @file.rewind

      return failure("Image storage quota reached", :content_too_large) if quota_exceeded?

      Result.new(ok: true, blob: create_blob(content_type))
    rescue ActiveRecord::RecordNotUnique
      # I guess be safe
      @attempts += 1
      if @attempts < 3
        @file.rewind
        retry
      end
      failure("Failed to upload image", :unprocessable_entity)
    rescue StandardError => e
      Rails.logger.error("[PasteImages::Upload] #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
      failure("Failed to upload image", :unprocessable_entity)
    end

    private

    def create_blob(content_type)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: @file,
        filename: safe_filename(content_type),
        content_type: content_type,
        identify: false,
        key: storage_key(content_type),
        service_name: PasteImages.service_name,
        metadata: { "identified" => true, "analyzed" => false }
      )

      @user.paste_images.attach(blob)
      blob
    end

    def storage_key(content_type)
      "paste-images/#{@user.username.downcase}/#{SecureRandom.uuid}.#{EXTENSIONS.fetch(content_type)}"
    end

    def safe_filename(content_type)
      base = File.basename(@file.original_filename.to_s.tr("\\", "/"))
      base = base.sub(/\.[^.]+\z/, "").gsub(/[^\w.\- ]/, "").strip.first(80)
      base = "image" if base.blank?
      "#{base}.#{EXTENSIONS.fetch(content_type)}"
    end

    def quota_exceeded?
      @user.paste_images.blobs.sum(:byte_size) + @file.size > USER_QUOTA
    end

    def uploaded_file?
      @file.respond_to?(:read) && @file.respond_to?(:original_filename)
    end

    def failure(error, status)
      Result.new(ok: false, error: error, status: status)
    end
  end
end
