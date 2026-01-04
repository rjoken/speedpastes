class Paste < ApplicationRecord
  belongs_to :user

  enum :visibility, { open: 0, unlisted: 1 }

  validates :shortcode, presence: true, uniqueness: true
  validates :body, presence: true

  before_validation :ensure_shortcode, on: :create

  private

  def ensure_shortcode
    return if shortcode.present?

    loop do
      self.shortcode = SecureRandom.urlsafe_base64(6)[0, 8]
      break unless Paste.exists?(shortcode:)
    end
  end
end
