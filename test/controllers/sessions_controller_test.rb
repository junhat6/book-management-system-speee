require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should login with valid credentials" do
    post session_url, params: {
      email_address: users(:one).email_address,
      password: "password123"
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-end", text: /管理者/
  end

  test "should create a new session record on each login" do
    assert_difference("Session.count", 1) do
      post session_url, params: {
        email_address: users(:one).email_address,
        password: "password123"
      }
    end
  end

  test "should not login with invalid credentials" do
    post session_url, params: {
      email_address: users(:one).email_address,
      password: "wrong-password"
    }

    assert_redirected_to new_session_url
    follow_redirect!
    assert_select ".alert-error", text: /メールアドレスまたはパスワードが正しくありません/
  end

  test "should login even if email has surrounding whitespace" do
    post session_url, params: {
      email_address: "  #{users(:one).email_address}  ",
      password: "password123"
    }

    assert_redirected_to root_url
  end

  test "should logout" do
    post session_url, params: {
      email_address: users(:one).email_address,
      password: "password123"
    }

    delete session_url

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-end", text: /ログイン/
  end
end
