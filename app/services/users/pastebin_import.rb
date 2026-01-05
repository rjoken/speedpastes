require "zip"

module Users
    class PastebinImport
        MAX_FILES = 500
        MAX_TOTAL_BYTES = 10 * 1024 * 1024 # 10 MB
        MAX_FILE_BYTES = 512 * 1024 # 512 KB per paste

        SHORTCODE_RE = /\A[a-zA-Z0-9_-]{6,12}\z/

        def self.call(user:, zip_path:, default_visibility:)
            new(user:, zip_path:, default_visibility:).call
        end

        def initialize(user:, zip_path:, default_visibility:)
            @user = user
            @zip_path = zip_path
            @default_visibility = default_visibility
        end

        def call
            imported = 0
            skipped = 0
            errors = []
            total_bytes = 0

            Zip::File.open(@zip_path) do |zip|
                entries = zip.entries.reject(&:directory?)

                if entries.size > MAX_FILES
                    raise "ZIP contains too many files (max #{MAX_FILES})"
                end

                entries.each do |entry|
                    begin
                        # Prevent path traversal
                        name = entry.name
                        base = File.basename(name)
                        next if base.blank?

                        # Accept only .txt files
                        ext = File.extname(base).downcase
                        next unless [".txt"].include?(ext)

                        # Read with size limits
                        data = entry.get_input_stream.read(MAX_FILE_BYTES + 1)
                        if data.bytesize > MAX_FILE_BYTES
                            skipped += 1
                            next
                        end

                        total_bytes += data.bytesize
                        if total_bytes > MAX_TOTAL_BYTES
                            raise "ZIP content too large (max #{MAX_TOTAL_BYTES / 1024 / 1024}MB)."
                        end

                        visibility, title, shortcode = parse_filename(base)

                        # user must prefix "!" for unlisted
                        visibility ||= @default_visibility
                        visibility = visibility.to_s

                        paste = @user.pastes.new(
                            title: title.presence,
                            body: data.to_s,
                            visibility: visibility
                        )

                        # Try to reuse shortcode if it looks acceptable
                        if shortcode.present? && acceptable_shortcode?(shortcode)
                            paste.shortcode = shortcode
                        end

                        # Save; if shortcode collides/invalid, retry without it
                        begin
                            paste.save!
                        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
                            paste.shortcode = nil
                            paste.save!
                        end

                        imported += 1
                    rescue => e
                        errors << "#{File.basename(entry.name)}: #{e.message}"
                        skipped += 1
                    end
                end
            end

            { imported:, skipped:, errors: }
        end

        private

        # filename formats:
        # - "!Title - shortcode.txt" => unlisted
        # - "Title - shortcode.txt" => default visibility
        # - "Title.txt" => title only, no shortcode
        def parse_filename(base)
            unlisted = base.start_with?("!")
            base = base.sub(/\A!+/, "")
            base = base.sub(/\.txt\z/i, "")

            title = base
            shortcode = nil
            if base.include?(" - ")
                # Split on last " - " so titles can contain hyphens
                left, right = base.rpartition(" - ").values_at(0, 2)
                if right.present?
                    title = left
                    shortcode = right
                end
            end

            visibility = if unlisted then "unlisted" else nil end

            [visibility, sanitize_title(title), sanitize_shortcode(shortcode)]
        end

        def sanitize_title(title)
            title.to_s.strip.gsub(/\s+/, " ")[0, 200]
        end

        def sanitize_shortcode(shortcode)
            shortcode.to_s.strip
        end

        def acceptable_shortcode?(shortcode)
            shortcode.present? && shortcode.match?(SHORTCODE_RE) && shortcode.length.between?(1, 8)
        end
    end
end
