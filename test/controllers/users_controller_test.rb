require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "新規ユーザー",
          email_address: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-end", text: /新規ユーザー/
  end

  test "should not create user with invalid data" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "",
          email_address: "",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-error"
  end
end
