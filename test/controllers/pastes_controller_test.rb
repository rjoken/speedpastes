require "test_helper"

class PastesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get pastes_new_url
    assert_response :success
  end

  test "should get create" do
    get pastes_create_url
    assert_response :success
  end

  test "should get show" do
    get pastes_show_url
    assert_response :success
  end

  test "should get edit" do
    get pastes_edit_url
    assert_response :success
  end

  test "should get update" do
    get pastes_update_url
    assert_response :success
  end

  test "should get destroy" do
    get pastes_destroy_url
    assert_response :success
  end
end
