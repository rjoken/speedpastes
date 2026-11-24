require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular)
  end

  test "link accepts http and https URLs or blank" do
    [ "https://example.com", "http://example.com/path?q=1", "HTTPS://EXAMPLE.COM", "", nil ].each do |link|
      @user.link = link

      assert @user.valid?, "#{link.inspect} should be valid"
    end
  end

  test "link rejects other schemes and scheme-less values" do
    [ "javascript:alert(1)", " javascript:alert(1)", "JaVaScRiPt:alert(1)", "data:text/html,hi", "example.com", "//example.com", " https://example.com", "https://", "https://exa mple.com", "https://example.com\njavascript:alert(1)" ].each do |link|
      @user.link = link

      assert_not @user.valid?, "#{link.inspect} should be invalid"
      assert_includes @user.errors[:link], "must start with http:// or https://"
    end
  end

  test "safe_link hides links saved before validation existed" do
    @user.update_column(:link, "javascript:alert(1)")
    assert_nil @user.safe_link

    @user.update_column(:link, "https://example.com")
    assert_equal "https://example.com", @user.safe_link
  end
end
