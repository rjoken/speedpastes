class User < ApplicationRecord
  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: "invited_by_id", dependent: :nullify
end
