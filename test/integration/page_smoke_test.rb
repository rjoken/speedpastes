require "test_helper"

class PageSmokeTest < ActionDispatch::IntegrationTest
  KNOWN_PASTE_ID = 424_242

  setup do
    @user = users(:regular)
    @paste = Paste.create!(
      id: KNOWN_PASTE_ID,
      user: @user,
      title: "Smoke test paste",
      body: "Known content",
      visibility: :open,
      shortcode: "smoke42"
    )
  end

  test "public pages load when unauthenticated" do
    assert_public_pages_load
  end

  test "public pages load when authenticated" do
    sign_in_as @user
    assert_redirected_to root_path

    assert_public_pages_load
  end

  test "authenticated pages redirect guests to login" do
    authenticated_paths.each do |path|
      get path
      assert_redirected_to login_path, "#{path} did not redirect to login"
    end
  end

  test "authenticated pages load after login" do
    sign_in_as @user
    assert_redirected_to root_path

    authenticated_paths.each do |path|
      get path
      assert_response :success, "#{path} did not return 200"
    end
  end

  test "known paste loads in both authentication states" do
    assert_equal KNOWN_PASTE_ID, @paste.id

    get short_paste_path(@paste.shortcode)
    assert_response :success
    assert_select "h1", @paste.title

    sign_in_as @user
    assert_redirected_to root_path

    get short_paste_path(@paste.shortcode)
    assert_response :success
    assert_select "h1", @paste.title
  end

  private

  def assert_public_pages_load
    public_paths.each do |path|
      get path
      assert_response :success, "#{path} did not return 200"
    end
  end

  def public_paths
    [
      root_path,
      signup_path,
      login_path,
      new_password_reset_path,
      profile_path(@user),
      profiles_path,
      pastes_path,
      privacy_path,
      terms_path,
      friends_path,
      support_path,
      new_report_path(shortcode: @paste.shortcode),
      short_paste_path(@paste.shortcode),
      raw_paste_path(@paste.shortcode)
    ]
  end

  def authenticated_paths
    [
      new_paste_path,
      edit_paste_path(@paste),
      settings_path,
      scratchpad_path
    ]
  end
end
