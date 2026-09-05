require "test_helper"

class PastesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @paste = pastes(:open)
  end

  test "should get index when unauthenticated" do
    get pastes_path
    assert_response :success
  end

  test "should get index when authenticated" do
    sign_in_as @user
    assert_redirected_to root_path

    get pastes_path
    assert_response :success
  end

  test "should show paste by shortcode" do
    get short_paste_path(@paste.shortcode)
    assert_response :success
  end

  test "should render raw paste" do
    get raw_paste_path(@paste.shortcode)
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, @paste.body
  end

  test "should redirect new when unauthenticated" do
    get new_paste_path
    assert_redirected_to login_path
  end

  test "should get new when authenticated" do
    sign_in_as @user
    get new_paste_path
    assert_response :success
  end

  test "should redirect edit when unauthenticated" do
    get edit_paste_path(@paste)
    assert_redirected_to login_path
  end

  test "should get edit for owner when authenticated" do
    sign_in_as @user
    get edit_paste_path(@paste)
    assert_response :success
  end

  test "should create paste when authenticated" do
    sign_in_as @user

    assert_difference "Paste.count", 1 do
      post pastes_path, params: {
        paste: {
          body: "Created from test",
          visibility: "open"
        }
      }
    end

    paste = Paste.order(:id).last
    assert_redirected_to short_paste_path(paste.shortcode)
  end

  test "should redirect create when unauthenticated" do
    assert_no_difference "Paste.count" do
      post pastes_path, params: {
        paste: {
          body: "Blocked create",
          visibility: "open"
        }
      }
    end

    assert_redirected_to login_path
  end
end
