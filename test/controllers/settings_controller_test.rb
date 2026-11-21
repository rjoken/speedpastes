require "test_helper"
require "json"
require "tempfile"
require "zip"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "data export downloads zip with scratchpad and pastes" do
    sign_in_as @user

    post data_export_settings_path

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_includes response.headers["Content-Disposition"], "attachment"

    entries, data = zip_entries_and_data
    assert_includes entries, "#{@user.username}-data.json"
    assert entries.any? { |name| name.start_with?("pastes/") }
    assert data["scratchpad"].present?
    assert data["pastes"].any?
  end

  test "data export downloads zip with scratchpad and no pastes" do
    @user.pastes.destroy_all
    sign_in_as @user

    post data_export_settings_path

    assert_response :success

    entries, data = zip_entries_and_data
    assert_equal [], entries.select { |name| name.start_with?("pastes/") }
    assert_equal [], data["pastes"]
    assert data["scratchpad"].present?
  end

  test "data export downloads zip with no scratchpad and pastes" do
    @user.scratchpad&.destroy!
    sign_in_as @user

    post data_export_settings_path

    assert_response :success

    entries, data = zip_entries_and_data
    assert entries.any? { |name| name.start_with?("pastes/") }
    assert data["pastes"].any?
    assert_nil data["scratchpad"]
  end

  test "data export downloads zip with no scratchpad and no pastes" do
    @user.scratchpad&.destroy!
    @user.pastes.destroy_all
    sign_in_as @user

    post data_export_settings_path

    assert_response :success

    entries, data = zip_entries_and_data
    assert_equal [], entries.select { |name| name.start_with?("pastes/") }
    assert_equal [], data["pastes"]
    assert_nil data["scratchpad"]
  end

  test "data export redirects guests to login" do
    post data_export_settings_path

    assert_redirected_to login_path
  end

  test "add api token shows the raw token once and stores only its digest" do
    sign_in_as @user

    assert_difference -> { @user.api_tokens.count }, 1 do
      post add_api_token_settings_path, params: { name: "CLI", scopes: [ "pastes:read", "scratchpad:write" ], expires_in: "never" }
    end

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]

    token = @user.api_tokens.order(:created_at).last
    raw_token = css_select("#raw_api_token").first["value"]
    assert_equal ApiToken.digest(raw_token), token.token_digest
    assert_equal [ "pastes:read", "scratchpad:write" ], token.scopes
    assert_nil token.expires_at
  end

  test "add api token without scopes is rejected" do
    sign_in_as @user

    assert_no_difference -> { ApiToken.count } do
      post add_api_token_settings_path, params: { name: "CLI", expires_in: "30_days" }
    end

    assert_redirected_to settings_path
  end

  test "add api token with an invalid expiry is rejected" do
    sign_in_as @user

    assert_no_difference -> { ApiToken.count } do
      post add_api_token_settings_path, params: { name: "CLI", scopes: [ "pastes:read" ], expires_in: "forever" }
    end

    assert_redirected_to settings_path
  end

  test "revoke api token revokes own token" do
    sign_in_as @user
    token = api_tokens(:active)

    patch revoke_api_token_settings_path(token)

    assert_redirected_to settings_path
    assert_not token.reload.active?
  end

  test "revoke api token cannot revoke another user's token" do
    sign_in_as @user
    token = api_tokens(:other_user)

    patch revoke_api_token_settings_path(token)

    assert_redirected_to settings_path
    assert token.reload.active?
  end

  private

  def zip_entries_and_data
    Tempfile.create([ "user-export", ".zip" ]) do |file|
      file.binmode
      file.write(response.body)
      file.flush

      entries = []
      data = nil

      Zip::File.open(file.path) do |zip|
        entries = zip.entries.map(&:name)
        json_entry = zip.find_entry("#{@user.username}-data.json")
        assert json_entry, "expected #{@user.username}-data.json in export zip"
        data = JSON.parse(json_entry.get_input_stream.read)
      end

      [ entries, data ]
    end
  end
end
