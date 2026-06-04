class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar
  has_one_attached :background_image
  has_many :pastes, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :account_change_requests, dependent: :destroy
  has_many :user_pins, -> { order(:position) }, dependent: :destroy
  has_many :user_pin_records, through: :user_pins, source: :paste
  has_one :scratchpad, dependent: :destroy
  has_one :patreon_connection, dependent: :destroy
  has_one :userpage, dependent: :destroy

  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invitees, class_name: "User", foreign_key: "invited_by_id", dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { in: 3..20 },
    format: { with: /\A(?!\d+\z)[a-zA-Z0-9_]+\z/, message: "May only contain letters (at least one), numbers, and underscores and must be between 3 and 20 characters long." }

  enum :role, { user: 0, pro: 1, deactivated: 2, banned: 3, admin: 999 }, default: :user
  # Pro is deprecated as a role in favour of using the is_supporter column

  ACTIVATED_ROLES = %w[user pro admin].freeze
  INACTIVE_ROLES = %w[deactivated banned].freeze

  scope :activated, -> { where(role: ACTIVATED_ROLES) }
  scope :inactive, -> { where(role: INACTIVE_ROLES) }

  PROFILE_STYLE_SCHEMA = {
    "--bg" => { type: :color, label: "Page background" },
    "--surface" => { type: :color, label: "Primary surface" },
    "--surface2" => { type: :color, label: "Secondary surface" },
    "--border" => { type: :color, label: "Border" },
    "--text" => { type: :color, label: "Text" },
    "--button-border" => { type: :color, label: "Button border" },
    "--button-bg" => { type: :color, label: "Button background" },
    "--button-bg-hover" => { type: :color, label: "Button hover background" },
    "--border-danger" => { type: :color, label: "Danger border" },
    "--bg-danger" => { type: :color, label: "Danger background" },
    "--text-danger" => { type: :color, label: "Danger text" },
    "--button-bg-danger" => { type: :color, label: "Danger button background" },
    "--button-bg-danger-hover" => { type: :color, label: "Danger button hover background" },
    "--border-muted" => { type: :color, label: "Muted border" },
    "--muted" => { type: :color, label: "Muted text" },
    "--external-link" => { type: :color, label: "External link" },
    "--bg-display" => { type: :choice, label: "Background display mode", choices: [ "tile", "stretch", "center" ] }
  }.freeze

  PROFILE_STYLE_KEYS = PROFILE_STYLE_SCHEMA.keys.freeze

  HEX_COLOR_REGEX = /\A(?:#[0-9a-fA-F]{3}|#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8})\z/.freeze

  before_validation :normalize_profile_style

  validate :profile_style_overrides_are_allowed
  validate :profile_style_overrides_are_valid

  def show_view_count?
    show_view_count
  end

  def activated?
    user? || pro? || admin?
  end

  def inactive?
    deactivated? || banned?
  end

  def build_scratchpad
    scratchpad || create_scratchpad
  end

  private

  def normalize_profile_style
    self.profile_style = profile_style
      .to_h
      .transform_values { |value| value.is_a?(String) ? value.strip : value }
      .compact_blank
      .slice(*PROFILE_STYLE_KEYS)
  end

  def profile_style_overrides_are_allowed
    unknown_keys = profile_style.to_h.keys - PROFILE_STYLE_KEYS

    return if unknown_keys.empty?

    errors.add(:profile_style, "contains unknown keys: #{unknown_keys.join(', ')}")
  end

  def profile_style_overrides_are_valid
    profile_style.to_h.each do |key, value|
      case PROFILE_STYLE_SCHEMA.dig(key, :type)
      when :color
        next if value.is_a?(String) && value.match?(HEX_COLOR_REGEX)

        errors.add(:profile_style, "#{key} must be a valid hex color")
      when :choice
        choices = PROFILE_STYLE_SCHEMA.dig(key, :choices)
        next if choices.include?(value)

        errors.add(:profile_style, "#{key} must be one of: #{choices.join(', ')}")
      else
        errors.add(:profile_style, "#{key} has an unsupported type")
      end
    end
  end
end
