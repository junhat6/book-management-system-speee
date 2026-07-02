require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "should get new" do
    get new_password_url
    assert_response :success
  end

  test "should send reset email for existing user" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ users(:one) ] do
      post passwords_url, params: { email_address: users(:one).email_address }
    end

    assert_redirected_to new_session_url
  end

  test "should not reveal whether email exists" do
    assert_no_enqueued_emails do
      post passwords_url, params: { email_address: "nonexistent@example.com" }
    end

    assert_redirected_to new_session_url
  end

  test "should get edit with valid token" do
    token = users(:one).password_reset_token
    get edit_password_url(token)
    assert_response :success
  end

  test "should redirect edit with invalid token" do
    get edit_password_url("invalid-token")
    assert_redirected_to new_password_url
  end

  test "should update password with valid token and matching confirmation" do
    token = users(:one).password_reset_token

    patch password_url(token), params: {
      password: "new-password123",
      password_confirmation: "new-password123"
    }

    assert_redirected_to new_session_url
    assert users(:one).reload.authenticate("new-password123")
  end

  test "should destroy all sessions after password reset" do
    users(:one).sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
    token = users(:one).password_reset_token

    assert_difference -> { users(:one).sessions.count }, -1 do
      patch password_url(token), params: {
        password: "new-password123",
        password_confirmation: "new-password123"
      }
    end
  end

  test "should not update password with mismatched confirmation" do
    token = users(:one).password_reset_token

    patch password_url(token), params: {
      password: "new-password123",
      password_confirmation: "different"
    }

    assert_redirected_to edit_password_url(token)
  end
end
