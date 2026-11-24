class Scratchpad < ApplicationRecord
  belongs_to :user

  validates :body, length: { maximum: 500_000, message: "is too long" }
  validates :body, safe_text: true
end
