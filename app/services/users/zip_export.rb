# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require "zip"

module Users
  class ZipExport
    def self.call(user:, now: Time.current)
      new(user:, now:).call
    end

    def initialize(user:, now:)
      @user = user
      @now  = now
    end

    # Returns: [zip_path, zip_filename]
    def call
      timestamp = @now.strftime("%Y%m%d-%H%M%S")
      zip_filename = "#{@user.username}-speedpastes-user-export-#{timestamp}.zip"

      tmp_zip = Tempfile.new([ @user.username, ".zip" ])
      tmp_zip.close # rubyzip wants a path

      Dir.mktmpdir("speedpastes-export-") do |dir|
        export_root = File.join(dir, "export")
        pastes_dir  = File.join(export_root, "pastes")
        FileUtils.mkdir_p(pastes_dir)

        # 1) Write paste text files
        paste_entries = @user.pastes.order(created_at: :desc).map do |p|
          title = (p.title.presence || "untitled")
          safe_title = sanitize_filename(title)

          prefix = p.respond_to?(:unlisted?) && p.unlisted? ? "!" : ""
          filename = "#{prefix}#{p.shortcode} - #{safe_title}.txt"
          filepath = File.join(pastes_dir, filename)

          File.write(filepath, p.body.to_s)

          {
            id: p.id,
            shortcode: p.shortcode,
            title: p.title,
            visibility: p.visibility,
            created_at: p.created_at.iso8601,
            updated_at: p.updated_at.iso8601,
            edited_at: (p.respond_to?(:edited_at) ? p.edited_at&.iso8601 : nil),
            views: p.views,
            file: File.join("pastes", filename)
          }
        end

        # 2) Write user data json (no bodies, since they're in txt files)
        data = {
          exported_at: @now.iso8601,
          user: {
            id: @user.id,
            email: @user.email,
            username: @user.username,
            bio: @user.bio,
            link: @user.link,
            role: (@user.respond_to?(:role) ? @user.role : nil),
            created_at: @user.created_at.iso8601
          },
          pastes: paste_entries,
          user_pins: UserPin.where(user_id: @user.id).order(:position).map { |up|
            {
              id: up.id,
              user_id: up.user_id,
              paste_id: up.paste_id,
              position: up.position,
              created_at: up.created_at.iso8601,
              updated_at: up.updated_at.iso8601
            }
          },
          scratchpad: {
            id: @user.scratchpad.id,
            body: @user.scratchpad.body,
            updated_at: @user.scratchpad.updated_at.iso8601,
            created_at: @user.scratchpad.created_at.iso8601
          },
          invite_codes_created: InviteCode.where(created_by_id: @user.id).order(created_at: :desc).map { |ic|
            {
              code: ic.code,
              uses_count: ic.uses_count,
              max_uses: ic.max_uses,
              used_at: ic.used_at&.iso8601,
              created_at: ic.created_at.iso8601
            }
          },
          sessions: UserSession.where(user_id: @user.id).order(created_at: :desc).map { |s|
            {
              id: s.id,
              user_id: s.user_id,
              user_agent: s.user_agent,
              ip_address: s.ip,
              token_digest: s.token_digest,
              created_at: s.created_at.iso8601,
              updated_at: s.updated_at.iso8601,
              expires_at: s.expires_at.iso8601,
              revoked_at: s.revoked_at&.iso8601
            }
          },
          account_change_requests: AccountChangeRequest.where(user_id: @user.id).order(created_at: :desc).map { |acr|
            {
              id: acr.id,
              user_id: acr.user_id,
              created_at: acr.created_at.iso8601,
              updated_at: acr.updated_at.iso8601,
              kind: acr.kind,
              new_email: acr.new_email,
              new_username: acr.new_username,
              new_password_digest: acr.new_password_digest,
              expires_at: acr.expires_at.iso8601,
              used_at: acr.used_at&.iso8601
            }
          },
          patreon_connection: PatreonConnection.where(user_id: @user.id).map { |pc|
            {
              user_id: pc.user_id,
              patreon_user_id: pc.patreon_user_id,
              patreon_username: pc.patreon_username,
              last_synced_at: pc.last_synced_at&.iso8601,
              created_at: pc.created_at.iso8601,
              updated_at: pc.updated_at.iso8601
            }
          }
        }

        json_filename = "#{@user.username}-data.json"
        json_path = File.join(export_root, json_filename)
        File.write(json_path, JSON.pretty_generate(data))

        # 3) Zip: <username>-data.json + /pastes/*
        Zip::File.open(tmp_zip.path, create: true) do |zip|
          zip.add(json_filename, json_path)

          Dir.glob(File.join(pastes_dir, "*")).each do |file|
            zip.add(File.join("pastes", File.basename(file)), file)
          end
        end
      end

      [ tmp_zip.path, zip_filename ]
    end

    private

    # Keep filenames safe + portable
    def sanitize_filename(name)
      base = name.to_s.strip
      base = base.gsub(/[\/\\:\*\?"<>\|\x00-\x1F]/, "_") # windows + control chars
      base = base.gsub(/\s+/, " ").strip
      base = base[0, 80] # keep it sane
      base.presence || "untitled"
    end
  end
end
