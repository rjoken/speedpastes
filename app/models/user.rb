class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar 
  has_many :pastes, dependent: :destroy

  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: "invited_by_id", dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
    format: { with: /\A([a-zA-Z0-9_]+\z)/, length: {in: 3..20 }, message: "May only contain letters, numbers, and underscores and must be between 3 and 20 characters long." }
end
