require "test_helper"

class Webhooks::PatreonControllerTest < ActionDispatch::IntegrationTest
  SECRET = "test-webhook-secret"

  setup do
    @previous_secret = ENV["PATREON_WEBHOOK_SECRET"]
    ENV["PATREON_WEBHOOK_SECRET"] = SECRET

    @user = users(:regular)
    @connection = PatreonConnection.create!(user: @user, patreon_user_id: "987654321")
  end

  teardown do
    ENV["PATREON_WEBHOOK_SECRET"] = @previous_secret
  end

  test "connected user becomes a supporter on a new pledge" do
    deliver "members:pledge:create", patron_status: "active_patron"

    assert_response :ok
    assert @user.reload.is_supporter?
    assert_equal "active_patron", @connection.reload.patron_status
  end

  test "supporter is removed when the member becomes a former patron" do
    @connection.sync_patron_status!("active_patron")

    deliver "members:update", patron_status: "former_patron"

    assert_not @user.reload.is_supporter?
    assert_equal "former_patron", @connection.reload.patron_status
  end

  test "supporter is removed when a declined payment is reported" do
    @connection.sync_patron_status!("active_patron")

    deliver "members:update", patron_status: "declined_patron"

    assert_not @user.reload.is_supporter?
  end

  test "supporter is removed when the pledge is deleted, even with a stale status" do
    @connection.sync_patron_status!("active_patron")

    deliver "members:pledge:delete", patron_status: "active_patron"

    assert_not @user.reload.is_supporter?
    assert_equal "former_patron", @connection.reload.patron_status
  end

  test "supporter is removed when the membership is deleted" do
    @connection.sync_patron_status!("active_patron")

    deliver "members:delete", patron_status: nil

    assert_not @user.reload.is_supporter?
    assert_nil @connection.reload.patron_status
  end

  test "a null status does not revoke an active supporter" do
    @connection.sync_patron_status!("active_patron")

    deliver "members:create", patron_status: nil

    assert @user.reload.is_supporter?
  end

  test "events for unconnected patreon users are ignored" do
    deliver "members:pledge:create", patron_status: "active_patron", patreon_user_id: "unknown"

    assert_response :ok
    assert_not @user.reload.is_supporter?
  end

  test "rejects an invalid signature" do
    post patreon_webhook_path, params: payload_for("active_patron", "987654321"),
      headers: { "X-Patreon-Event" => "members:pledge:create", "X-Patreon-Signature" => "nope", "CONTENT_TYPE" => "application/json" }

    assert_response :unauthorized
    assert_not @user.reload.is_supporter?
  end

  private

  def deliver(event, patron_status:, patreon_user_id: "987654321")
    body = payload_for(patron_status, patreon_user_id)
    post patreon_webhook_path, params: body, headers: {
      "X-Patreon-Event" => event,
      "X-Patreon-Signature" => OpenSSL::HMAC.hexdigest("MD5", SECRET, body),
      "CONTENT_TYPE" => "application/json"
    }
  end

  def payload_for(patron_status, patreon_user_id)
    {
      data: {
        id: "d485d5ac-6c82-42c6-9c08-c50cf01b73d7",
        type: "member",
        attributes: { patron_status: patron_status },
        relationships: { user: { data: { id: patreon_user_id, type: "user" } } }
      }
    }.to_json
  end
end
