module InviteCodes
    class Generate
        def self.call(user:, count:)
            count.times do
                InviteCode.create!(created_by: user, code: SecureRandom.base58(10), max_uses: 1, uses_count: 0)
            rescue ActiveRecord::RecordNotUnique
                retry
            end
        end
    end
end
