require "test_helper"

class PatreonConnectionTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
    @connection = PatreonConnection.create!(user: @user, patreon_user_id: "1")
  end

  test "an active status grants supporter" do
    @connection.sync_patron_status!("active_patron")

    assert @user.reload.is_supporter?
  end

  test "any other status removes supporter" do
    @user.update!(is_supporter: true)

    [ "former_patron", "declined_patron", nil ].each do |status|
      @connection.sync_patron_status!(status)
      assert_not @user.reload.is_supporter?, "expected #{status.inspect} to remove supporter"
    end
  end
end
