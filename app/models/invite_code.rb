class InviteCode < ApplicationRecord
    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :used_by, class_name: "User", optional: true
    
    validates :code, presence: true, uniqueness: true

    def usable?
        uses_count < max_uses
    end
end
