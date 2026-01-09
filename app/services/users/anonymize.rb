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
                # Delete pastes
                Paste.where(user_id: @user.id).delete_all

                # Delete invitations
                User.where(invited_by_id: @user.id).update_all(invited_by_id: nil)

                # Purge avatar
                @user.avatar.purge_later if @user.respond_to?(:avatar)

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
