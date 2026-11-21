class Paste < ApplicationRecord
  belongs_to :user

  has_many :user_pins, dependent: :destroy
  has_one :userpage, dependent: :destroy

  # validate: true turns invalid values into validation errors instead of raising ArgumentError
  enum :visibility, { open: 0, unlisted: 1 }, validate: true

  enum :render_type, { plain: 0, markdown: 1 }, validate: true

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

  def self.collaborator_ids_for(raw_ids, owner:)
    collaborator_ids = Array(raw_ids).map(&:to_i).uniq
    return [] if collaborator_ids.empty?

    User.activated.where(id: collaborator_ids).where.not(id: owner.id).pluck(:id)
  end

  def owned_by?(user)
    user.present? && user_id == user.id
  end

  def collaborator?(user)
    user.present? && collaborators.include?(user.id)
  end

  def editable_by?(user)
    owned_by?(user) || collaborator?(user) || user&.admin? || false
  end

  def deletable_by?(user)
    owned_by?(user) || user&.admin? || false
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
