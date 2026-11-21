require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "generate! stores a digest and returns the raw token" do
    api_token, raw_token = ApiToken.generate!(user: users(:regular), name: "CLI", scopes: [ "pastes:read" ], expires_in: 30.days)

    assert raw_token.start_with?(ApiToken::TOKEN_PREFIX)
    assert_equal ApiToken.digest(raw_token), api_token.token_digest
    assert_equal raw_token.first(api_token.token_prefix.length), api_token.token_prefix
    assert_in_delta 30.days.from_now, api_token.expires_at, 5.seconds
  end

  test "generate! with no expiry leaves expires_at nil" do
    api_token, _ = ApiToken.generate!(user: users(:regular), name: "CLI", scopes: [ "pastes:read" ], expires_in: nil)

    assert_nil api_token.expires_at
    assert api_token.active?
  end

  test "requires at least one scope" do
    token = ApiToken.new(user: users(:regular), name: "CLI", token_digest: "x", token_prefix: "sp_x", scopes: [])

    assert_not token.valid?
    assert_includes token.errors[:scopes], "must include at least one scope"
  end

  test "rejects unknown scopes" do
    token = ApiToken.new(user: users(:regular), name: "CLI", token_digest: "x", token_prefix: "sp_x", scopes: [ "admin:write" ])

    assert_not token.valid?
  end

  test "write scope implies read scope" do
    token = api_tokens(:active)

    assert token.allows?("pastes:write")
    assert token.allows?("pastes:read")
    assert token.allows?("users:read")
    assert_not token.allows?("scratchpad:read")
  end

  test "read scope does not imply write scope" do
    assert_not api_tokens(:revoked).allows?("pastes:write")
  end

  test "active scope excludes revoked and expired tokens" do
    api_tokens(:other_user).update!(expires_at: 1.minute.ago)

    assert_equal [ api_tokens(:active) ], ApiToken.active.to_a
  end
end
