require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "should get new" do
    get login_path
    assert_response :success
  end

  test "should create session with valid credentials" do
    assert_difference "UserSession.active.count", 1 do
      post login_path, params: { email: @user.email, password: "password" }
    end

    assert_redirected_to root_path
  end

  test "should reject invalid credentials" do
    assert_no_difference "UserSession.active.count" do
      post login_path, params: { email: @user.email, password: "wrong-password" }
    end

    assert_response :unprocessable_entity
  end

  test "should logout and redirect" do
    sign_in_as @user
    assert_redirected_to root_path

    assert_difference "UserSession.active.count", -1 do
      delete logout_path
    end

    assert_redirected_to root_path
  end
end
