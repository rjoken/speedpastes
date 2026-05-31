class Userpage < ApplicationRecord
  belongs_to :user
  belongs_to :paste

  validates :user_id, uniqueness: true

  validate :paste_belongs_to_user

  private

  def paste_belongs_to_user
    return if paste.nil?
    errors.add(:paste, "must belong to the user") if paste.user_id != user_id
  end
end
