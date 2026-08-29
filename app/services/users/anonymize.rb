module Users
    class Anonymize
        def self.call(user:)
            new(user).call
        end

        def initialize(user)
            @user = user
        end

        def call
            User.transaction do
                paste_ids = Paste.where(user_id: @user.id).pluck(:id)

                # Anyone may pin or feature this user's pastes, so clear those
                # references before the pastes they point at go away
                UserPin.where(paste_id: paste_ids).delete_all
                UserPin.where(user_id: @user.id).delete_all
                Userpage.where(paste_id: paste_ids).update_all(paste_id: nil)

                # Delete pastes
                Paste.where(id: paste_ids).delete_all

                # Delete invitations
                User.where(invited_by_id: @user.id).update_all(invited_by_id: nil)

                PatreonConnection.where(user_id: @user.id).delete_all

                UserSession.where(user_id: @user.id).delete_all

                AccountChangeRequest.where(user_id: @user.id).delete_all

                # Purge avatar
                @user.avatar.purge_later if @user.respond_to?(:avatar)

                # Purge background image
                @user.background_image.purge_later if @user.respond_to?(:background_image)

                @user.paste_images.purge_later if @user.respond_to?(:paste_images)

                # Anonymize user data
                anon_username = generate_unique_username
                anon_email = "#{anon_username}@speedpastes.org"

                random_pw = SecureRandom.base64(32)

                @user.update!(
                    email: anon_email,
                    username: anon_username,
                    bio: nil,
                    link: nil,
                    invited_by_id: nil,
                    anonymized_at: Time.current,
                    password: random_pw,
                    password_confirmation: random_pw
                )

                @user.scratchpad&.destroy!
            end
        end

        def generate_unique_username
            loop do
                suffix = SecureRandom.base58(10)
                candidate = "deleted_#{suffix}"
                next if User.where("lower(username) = ?", candidate.downcase).exists?
                return candidate
            end
        end
    end
end
