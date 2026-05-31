class PatreonConnection < ApplicationRecord
  belongs_to :user

  validates :patreon_user_id, presence: true, uniqueness: true
end
