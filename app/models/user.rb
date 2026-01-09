class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar
  has_many :pastes, dependent: :destroy
  has_one :scratchpad, dependent: :destroy

  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: "invited_by_id", dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { in: 3..20 },
    format: { with: /\A(?!\d+\z)[a-zA-Z0-9_]+\z/, message: "May only contain letters (at least one), numbers, and underscores and must be between 3 and 20 characters long." }

  enum :role, { user: 0, pro: 1, admin: 999 }, default: :user

  def build_scratchpad
    scratchpad || create_scratchpad
  end
end
