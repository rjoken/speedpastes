class Scratchpad < ApplicationRecord
  belongs_to :user

  validates :body, length: { maximum: 500_000, message: "Body is too long" }
end
