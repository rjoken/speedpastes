require "test_helper"

# Cross-cutting API behaviour, exercised through real endpoints
class Api::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "ping returns pong with any read scope" do
    get api_ping_path, headers: api_headers(@user, "users:read")

    assert_response :success
    assert_equal({ "message" => "pong" }, response.parsed_body)
  end

  test "write scope implies read scope" do
    get api_ping_path, headers: api_headers(@user, "pastes:write")

    assert_response :success
  end

  test "missing token is 401 with a WWW-Authenticate header" do
    get api_ping_path

    assert_response :unauthorized
    assert_equal 'Bearer realm="speedpastes"', response.headers["WWW-Authenticate"]
    assert response.parsed_body["error"].present?
  end

  test "unknown token is 401" do
    get api_ping_path, headers: { "Authorization" => "Bearer sp_notarealtoken" }

    assert_response :unauthorized
  end

  test "revoked token is 401" do
    headers = api_headers(@user, "pastes:read")
    @user.api_tokens.last.revoke!

    get api_ping_path, headers: headers

    assert_response :unauthorized
  end

  test "expired token is 401" do
    headers = api_headers(@user, "pastes:read")
    @user.api_tokens.last.update!(expires_at: 1.minute.ago)

    get api_ping_path, headers: headers

    assert_response :unauthorized
  end

  test "token belonging to a deactivated user is 403" do
    get api_ping_path, headers: api_headers(users(:deactivated), "pastes:read")

    assert_response :forbidden
  end

  test "using a token stamps last_used_at" do
    headers = api_headers(@user, "pastes:read")

    get api_ping_path, headers: headers

    assert_not_nil @user.api_tokens.last.last_used_at
  end

  test "changing password revokes api tokens" do
    headers = api_headers(@user, "pastes:read")

    @user.update!(password: "newpassword", password_confirmation: "newpassword")
    get api_ping_path, headers: headers

    assert_response :unauthorized
  end

  test "body without a JSON content type is 415" do
    patch api_scratchpad_path, params: { body: "x" }.to_json,
      headers: api_headers(@user, "scratchpad:write").merge("Content-Type" => "text/plain")

    assert_response :unsupported_media_type
  end

  test "JSON content type with a charset is accepted" do
    patch api_scratchpad_path, params: { body: "x" }.to_json,
      headers: api_headers(@user, "scratchpad:write").merge("Content-Type" => "application/json; charset=utf-8")

    assert_response :success
  end

  test "malformed JSON is 400" do
    patch api_scratchpad_path, params: "{not json", headers: json_headers(api_headers(@user, "scratchpad:write"))

    assert_response :bad_request
    assert_equal "Request body must be valid JSON", response.parsed_body["error"]
  end

  test "null byte in JSON body is 400" do
    patch api_scratchpad_path, params: { body: "a\u0000b" }.to_json, headers: json_headers(api_headers(@user, "scratchpad:write"))

    assert_response :bad_request
    assert_equal "Request body must not contain null bytes", response.parsed_body["error"]
  end

  test "invalid UTF-8 in JSON body is 400" do
    patch api_scratchpad_path, params: "{\"body\":\"a\xFFb\"}".b, headers: json_headers(api_headers(@user, "scratchpad:write"))

    assert_response :bad_request
  end

  test "null byte in a query param is 400" do
    get api_pastes_path, params: { user: "\u0000" }, headers: api_headers(@user, "pastes:read")

    assert_response :bad_request
    assert_equal "Query parameters must not contain null bytes", response.parsed_body["error"]
  end

  test "null byte in a path param is 400" do
    get "/api/pastes/%00", headers: api_headers(@user, "pastes:read")

    assert_response :bad_request
    assert_equal "URL must not contain null bytes", response.parsed_body["error"]
  end

  # Rails raises this before rescue_from is in scope, so it is the HTML error page, not JSON
  test "invalid percent-encoding in a query param is 400" do
    get "/api/pastes?user=%FF", headers: api_headers(@user, "pastes:read")

    assert_response :bad_request
  end

  test "reads are limited to 120 per minute" do
    headers = api_headers(@user, "pastes:read")

    with_memory_cache do
      120.times { get api_ping_path, headers: headers }
      assert_response :success

      get api_ping_path, headers: headers
      assert_response :too_many_requests
      assert_equal "Rate limit exceeded", response.parsed_body["error"]
    end
  end

  test "rate limit is per user, not per token" do
    first = api_headers(@user, "pastes:read")
    second = api_headers(@user, "pastes:read")

    with_memory_cache do
      120.times { get api_ping_path, headers: first }

      get api_ping_path, headers: second
      assert_response :too_many_requests
    end
  end

  test "batch creates count once per paste against the write limit" do
    headers = json_headers(api_headers(@user, "pastes:write"))

    with_memory_cache do
      post api_pastes_path, params: paste_batch(25), headers: headers
      assert_response :created

      post api_pastes_path, params: paste_batch(5), headers: headers
      assert_response :created

      assert_no_difference -> { Paste.count } do
        post api_pastes_path, params: paste_batch(1), headers: headers
      end
      assert_response :too_many_requests
    end
  end

  test "a batch rejected by the rate limit does not block smaller writes" do
    headers = json_headers(api_headers(@user, "pastes:write"))

    with_memory_cache do
      6.times { post api_pastes_path, params: paste_batch(1), headers: headers }

      post api_pastes_path, params: paste_batch(25), headers: headers
      assert_response :too_many_requests

      # 6 writes plus 1 for the rejected request leaves exactly 23
      post api_pastes_path, params: paste_batch(23), headers: headers
      assert_response :created

      post api_pastes_path, params: paste_batch(1), headers: headers
      assert_response :too_many_requests
    end
  end

  test "rejected writes still count against the write limit" do
    no_scope = json_headers(api_headers(@user, "pastes:read"))
    write = api_headers(@user, "pastes:write")

    with_memory_cache do
      10.times { post api_pastes_path, params: paste_batch(1), headers: no_scope }
      assert_response :forbidden

      10.times { post api_pastes_path, params: "[]", headers: json_headers(write) }
      assert_response :bad_request

      10.times { post api_pastes_path, params: paste_batch(1), headers: write.merge("Content-Type" => "text/plain") }
      assert_response :unsupported_media_type

      post api_pastes_path, params: paste_batch(1), headers: json_headers(write)
      assert_response :too_many_requests
    end
  end

  private

  def paste_batch(size)
    Array.new(size) { |i| { body: "paste #{i}" } }.to_json
  end
end
