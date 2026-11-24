require "test_helper"

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = api_headers(users(:regular), "users:read")
    @user = users(:other)
  end

  test "returns the user's public profile" do
    @user.update!(link: "https://example.com")

    get api_user_path(@user.username), headers: @headers

    assert_response :success
    assert_equal(
      {
        "username" => "other",
        "joined_at" => @user.created_at.iso8601,
        "total_views" => 0,
        "total_pastes" => 0,
        "bio" => "I am another regular user.",
        "website" => "https://example.com",
        "is_supporter" => false
      },
      response.parsed_body
    )
  end

  test "looks up by id" do
    get api_user_path(@user.id), headers: @headers

    assert_equal "other", response.parsed_body["username"]
  end

  test "looks up usernames case-insensitively" do
    get api_user_path("OTHER"), headers: @headers

    assert_equal "other", response.parsed_body["username"]
  end

  test "a username starting with digits is not mistaken for an id" do
    User.create!(email: "digits@speedpastes.org", username: "#{@user.id}abc", password: "password")

    get api_user_path("#{@user.id}abc"), headers: @headers

    assert_equal "#{@user.id}abc", response.parsed_body["username"]
  end

  test "totals only count open pastes" do
    @user.pastes.create!(body: "open", views: 5)
    @user.pastes.create!(body: "unlisted", visibility: :unlisted, views: 7)

    get api_user_path(@user.username), headers: @headers

    assert_equal 5, response.parsed_body["total_views"]
    assert_equal 1, response.parsed_body["total_pastes"]
  end

  test "total views is 0 when the user hides view counts" do
    @user.pastes.create!(body: "open", views: 5)
    @user.update!(show_view_count: false)

    get api_user_path(@user.username), headers: @headers

    assert_equal 0, response.parsed_body["total_views"]
  end

  test "supporter status respects show_supporter" do
    @user.update!(is_supporter: true, show_supporter: true)
    get api_user_path(@user.username), headers: @headers
    assert_equal true, response.parsed_body["is_supporter"]

    @user.update!(show_supporter: false)
    get api_user_path(@user.username), headers: @headers
    assert_equal false, response.parsed_body["is_supporter"]
  end

  test "website is null for a stored non-http link" do
    @user.update_column(:link, "javascript:alert(1)")

    get api_user_path(@user.username), headers: @headers

    assert_nil response.parsed_body["website"]
  end

  test "unknown user is 404" do
    get api_user_path("nobody"), headers: @headers

    assert_response :not_found
  end

  test "anonymized user is 404" do
    @user.update!(anonymized_at: Time.current)

    get api_user_path(@user.username), headers: @headers

    assert_response :not_found
  end

  test "deactivated user is 404, even for admins" do
    get api_user_path("deactivated"), headers: api_headers(users(:admin), "users:read")

    assert_response :not_found
  end

  test "requires users:read" do
    get api_user_path(@user.username), headers: api_headers(users(:regular), "pastes:read")

    assert_response :forbidden
  end
end
