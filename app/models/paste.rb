class Paste < ApplicationRecord
  belongs_to :user

  has_many :user_pins, dependent: :destroy
  has_one :userpage, dependent: :destroy

  enum :visibility, { open: 0, unlisted: 1 }

  enum :render_type, { plain: 0, markdown: 1 }

  validates :shortcode, presence: true, uniqueness: true
  validates :body, presence: true
  validates :title, length: { maximum: 255, message: "is too long" }
  validates :body, length: { maximum: 500_000, message: "is too long" }

  before_validation :ensure_shortcode, on: :create

  before_update :stamp_edited_at, if: :content_changed?

  # Wanna try and have actual words as part of the title,
  # but don't need to be too serious about it.
  # Definitely strip markdown image formatting, though.
  IMAGE_SYNTAX = /!\[[^\]]*\]\s*(?:\([^)]*\)|\[[^\]]*\])/
  TITLE_ALLOWED = /[^[:alnum:]\s.,-_]/

  def default_title
    text = body.to_s.gsub(IMAGE_SYNTAX, " ").gsub(TITLE_ALLOWED, " ")
    words = text.split.select { |word| word.match?(/[[:alnum:]]/) }.first(5)

    words.join(" ").presence&.truncate(255) || "Untitled paste"
  end

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
