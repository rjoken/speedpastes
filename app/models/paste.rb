class Paste < ApplicationRecord
  belongs_to :user

  has_many :user_pins, dependent: :destroy

  enum :visibility, { open: 0, unlisted: 1 }

  validates :shortcode, presence: true, uniqueness: true
  validates :body, presence: true
  validates :title, length: { maximum: 255, message: "is too long" }
  validates :body, length: { maximum: 500_000, message: "is too long" }

  before_validation :ensure_shortcode, on: :create

  before_update :stamp_edited_at, if: :content_changed?

  def content_changed?
    will_save_change_to_body? || will_save_change_to_title? || will_save_change_to_tags?
  end

  def stamp_edited_at
    self.edited_at = Time.current
  end

  private

  def ensure_shortcode
    return if shortcode.present?

    loop do
      self.shortcode = SecureRandom.urlsafe_base64(6)[0, 8]
      break unless Paste.exists?(shortcode:)
    end
  end
end
