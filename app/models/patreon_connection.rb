class PatreonConnection < ApplicationRecord
  belongs_to :user

  validates :patreon_user_id, presence: true, uniqueness: true

  def active_patron?
    patron_status == "active_patron"
  end

  def sync_patron_status!(status)
    transaction do
      update!(patron_status: status.presence, last_synced_at: Time.current)
      user.update!(is_supporter: active_patron?)
    end
  end
end
