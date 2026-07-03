require "test_helper"

class RentalsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインなら貸出処理はログイン画面へリダイレクトされる" do
    book = books(:one)
    assert_no_difference("Rental.count") do
      post book_rentals_url(book)
    end
    assert_redirected_to new_session_url
  end

  test "ログイン済みなら借りられる" do
    sign_in_as users(:one)
    book = books(:one)
    assert_difference("Rental.count", 1) do
      post book_rentals_url(book)
    end
    assert_redirected_to book_url(book)
    assert_equal users(:one), book.reload.active_rental.user
  end

  test "貸出中の本は借りられない" do
    sign_in_as users(:one)
    book = books(:two)
    assert_no_difference("Rental.count") do
      post book_rentals_url(book)
    end
    assert_redirected_to book_url(book)
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
