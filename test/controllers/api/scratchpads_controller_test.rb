require "test_helper"

class Api::ScratchpadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @read = api_headers(@user, "scratchpad:read")
    @write = json_headers(api_headers(@user, "scratchpad:write"))
  end

  test "returns the token owner's scratchpad" do
    get api_scratchpad_path, headers: @read

    assert_response :success
    assert_equal "MyText", response.parsed_body["body"]
  end

  test "creates an empty scratchpad if the user has none" do
    get api_scratchpad_path, headers: api_headers(users(:other), "scratchpad:read")

    assert_response :success
    assert_equal "", response.parsed_body["body"]
  end

  test "write scope can read" do
    get api_scratchpad_path, headers: api_headers(@user, "scratchpad:write")

    assert_response :success
  end

  test "read scope cannot write" do
    patch api_scratchpad_path, params: { body: "x" }.to_json, headers: json_headers(@read)

    assert_response :forbidden
  end

  test "PATCH replaces the body" do
    patch api_scratchpad_path, params: { body: "replaced" }.to_json, headers: @write

    assert_response :success
    assert_equal "replaced", response.parsed_body["body"]
    assert_equal "replaced", @user.scratchpad.reload.body
  end

  test "PATCH with an empty body clears it" do
    patch api_scratchpad_path, params: { body: "" }.to_json, headers: @write

    assert_response :success
    assert_equal "", @user.scratchpad.reload.body
  end

  test "POST appends on a new line" do
    post api_scratchpad_path, params: { body: "more" }.to_json, headers: @write

    assert_response :success
    assert_equal "MyText\nmore", @user.scratchpad.reload.body
  end

  test "POST does not double up an existing trailing newline" do
    @user.scratchpad.update!(body: "line\n")

    post api_scratchpad_path, params: { body: "more" }.to_json, headers: @write

    assert_equal "line\nmore", @user.scratchpad.reload.body
  end

  test "POST to an empty scratchpad has no leading newline" do
    @user.scratchpad.update!(body: "")

    post api_scratchpad_path, params: { body: "first" }.to_json, headers: @write

    assert_equal "first", @user.scratchpad.reload.body
  end

  test "POST with an empty body is 400" do
    post api_scratchpad_path, params: { body: "" }.to_json, headers: @write

    assert_response :bad_request
  end

  test "extra fields are 400" do
    patch api_scratchpad_path, params: { body: "x", title: "y" }.to_json, headers: @write

    assert_response :bad_request
  end

  test "non-string body is 400" do
    patch api_scratchpad_path, params: { body: 5 }.to_json, headers: @write

    assert_response :bad_request
  end

  test "body over the length limit is 422" do
    patch api_scratchpad_path, params: { body: "a" * 500_001 }.to_json, headers: @write

    assert_response :unprocessable_entity
    assert response.parsed_body["details"]["body"].present?
  end
end
