require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
        @user = users(:regular)
        @admin = users(:admin)
        @other = users(:other)
    end

    test "non-admin cannot access invite_codes" do
        sign_in @user
        get profile_path(@other.username)
        assert_redirected_to root_path
        assert_equal "Not authorized", flash[:alert]
    end
end
