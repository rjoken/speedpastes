require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "should get index" do
    get profiles_path
    assert_response :success
  end

  test "should show by id" do
    get profile_path(@user.id)
    assert_response :success
  end

  test "should show by username" do
    get profile_path(@user.username)
    assert_response :success
  end

  test "should hide inactive profile from guest" do
    get profile_path(users(:deactivated).id)
    assert_response :not_found
  end

  test "should allow inactive user to view their own profile" do
    user = users(:deactivated)
    sign_in_as user
    assert_redirected_to root_path

    get profile_path(user.id)
    assert_response :success
  end
end
