require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @creator = users(:regular)
  end

  test "should get new" do
    get signup_path
    assert_response :success
  end

  test "should reject signup with invalid invite code" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        invite_code: "invalid",
        email: "new@example.com",
        username: "newuser",
        password: "password",
        password_confirmation: "password"
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create user with usable invite code" do
    invite = InviteCode.create!(
      code: "TESTINVITE123",
      created_by: @creator,
      max_uses: 2,
      uses_count: 0
    )

    assert_difference "User.count", 1 do
      post signup_path, params: {
        invite_code: invite.code,
        email: "new_signup@example.com",
        username: "newsignup",
        password: "password",
        password_confirmation: "password"
      }
    end

    assert_redirected_to root_path
  end
end
