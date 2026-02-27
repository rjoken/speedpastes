class UserPin < ApplicationRecord
  belongs_to :user
  belongs_to :paste

  # I'll care about ordering another time
  # validates :position, inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :paste_id, uniqueness: { scope: :user_id }
  validates :position, uniqueness: { scope: :user_id }
  validate :max_pins_per_user, on: :create

  validate :paste_belongs_to_user

  private

  def paste_belongs_to_user
    return if paste.nil?
    errors.add(:paste, "must belong to the user") if paste.user_id != user_id
  end

  def max_pins_per_user
    if user.user_pins.count >= 5
      errors.add(:base, "You can only have up to 5 pinned pastes.")
    end
  end
end
