require "test_helper"

class SettingsControllerPatreonStatusTest < ActiveSupport::TestCase
  CAMPAIGN_ID = "12345"

  setup do
    @previous_campaign = ENV["PATREON_CAMPAIGN_ID"]
    ENV["PATREON_CAMPAIGN_ID"] = CAMPAIGN_ID
  end

  teardown do
    ENV["PATREON_CAMPAIGN_ID"] = @previous_campaign
  end

  test "finds the status for our campaign among several memberships" do
    payload = identity_with(
      member("m1", campaign: "other", status: "active_patron"),
      member("m2", campaign: CAMPAIGN_ID, status: "former_patron")
    )

    assert_equal "former_patron", patron_status(payload)
  end

  test "returns active for a current patron of our campaign" do
    assert_equal "active_patron", patron_status(identity_with(member("m1", campaign: CAMPAIGN_ID, status: "active_patron")))
  end

  test "returns nil when the user has no membership to our campaign" do
    assert_nil patron_status(identity_with(member("m1", campaign: "other", status: "active_patron")))
  end

  test "returns nil when there are no memberships at all" do
    assert_nil patron_status({ "data" => { "id" => "1" } })
  end

  private

  def patron_status(payload)
    SettingsController.new.send(:get_patron_status, payload)
  end

  def identity_with(*members)
    { "data" => { "id" => "1" }, "included" => members + [ { "type" => "campaign", "id" => CAMPAIGN_ID } ] }
  end

  def member(id, campaign:, status:)
    {
      "type" => "member",
      "id" => id,
      "attributes" => { "patron_status" => status },
      "relationships" => { "campaign" => { "data" => { "id" => campaign, "type" => "campaign" } } }
    }
  end
end
