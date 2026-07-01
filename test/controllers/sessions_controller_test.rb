require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_url
    assert_response :success
  end

  test "should login with valid credentials" do
    post login_url, params: {
      session: {
        email: users(:one).email,
        password: "password123"
      }
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-end", text: /管理者/
  end

  test "should not login with invalid credentials" do
    post login_url, params: {
      session: {
        email: users(:one).email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-error", text: /メールアドレスまたはパスワードが正しくありません/
  end

  test "should logout" do
    post login_url, params: {
      session: {
        email: users(:one).email,
        password: "password123"
      }
    }

    delete logout_url

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-end", text: /ログイン/
  end
end
