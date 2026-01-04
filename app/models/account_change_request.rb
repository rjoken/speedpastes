class AccountChangeRequest < ApplicationRecord
  belongs_to :user

  enum :kind, { email: 0, username: 1, password: 2 }

  validates :expires_at, presence: true

  def usable?
    used_at.nil? && expires_at.future?
  end
end
