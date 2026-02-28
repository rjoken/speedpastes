require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
        @user = users(:regular)
        @admin = users(:admin)
        @other = users(:other)
    end
end
