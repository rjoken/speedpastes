class ApiToken < ApplicationRecord
  include TokenDigest

  SCOPES = %w[users:read pastes:read pastes:write scratchpad:read scratchpad:write].freeze

  EXPIRY_OPTIONS = {
    "30_days" => 30.days,
    "90_days" => 90.days,
    "1_year" => 1.year,
    "never" => nil
  }.freeze

  TOKEN_PREFIX = "sp_".freeze

  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :scopes, presence: { message: "must include at least one scope" }
  validate :scopes_are_known

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  # Returns [api_token, raw_token]. The raw token is never stored, so this is the only chance to show it.
  def self.generate!(user:, name:, scopes:, expires_in:)
    raw_token = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"

    api_token = user.api_tokens.create!(
      name: name,
      scopes: scopes,
      expires_at: expires_in&.from_now,
      token_digest: digest(raw_token),
      token_prefix: raw_token.first(TOKEN_PREFIX.length + 6)
    )

    [ api_token, raw_token ]
  end

  # Write access implies read access for the same resource
  def allows?(scope)
    resource, action = scope.split(":")
    scopes.include?(scope) || (action == "read" && scopes.include?("#{resource}:write"))
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def scopes_are_known
    unknown = scopes - SCOPES
    errors.add(:scopes, "contains unknown scope: #{unknown.join(', ')}") if unknown.any?
  end
end
