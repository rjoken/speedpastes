require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should render 400" do
    get "/400"
    assert_response :bad_request
  end

  test "should render 404" do
    get "/404"
    assert_response :not_found
  end

  test "should render 406" do
    get "/406"
    assert_response :not_acceptable
  end

  test "should render 422" do
    get "/422"
    assert_response :unprocessable_entity
  end

  test "should render 500" do
    get "/500"
    assert_response :internal_server_error
  end
end
