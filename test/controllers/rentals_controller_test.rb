require "test_helper"

class RentalsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインなら貸出処理はログイン画面へリダイレクトされる" do
    book = books(:one)
    assert_no_difference("Rental.count") do
      post book_rentals_url(book)
    end
    assert_redirected_to new_session_url
  end

  test "ログイン済みなら空いているコピーが自動で割り当てられて借りられる" do
    sign_in_as users(:one)
    book = books(:one)
    assert_difference("Rental.count", 1) do
      post book_rentals_url(book)
    end
    assert_redirected_to book_url(book)
    assert_equal users(:one), book.reload.active_rental_for(users(:one)).user
  end

  test "他のユーザーが貸出中でも在庫が残っていれば借りられる" do
    sign_in_as users(:one)
    book = books(:two) # コピーAは users(:two) が貸出中、コピーBが空き
    assert_difference("Rental.count", 1) do
      post book_rentals_url(book)
    end
    assert_redirected_to book_url(book)
    assert_equal book_copies(:two_copy_b), book.reload.active_rental_for(users(:one)).book_copy
  end

  test "全コピーが貸出中の本は借りられない" do
    third = User.create!(name: "三人目", email_address: "third@example.com", password: "password123")
    Rental.create!(user: third, book_copy: book_copies(:two_copy_b))

    sign_in_as users(:one)
    assert_no_difference("Rental.count") do
      post book_rentals_url(books(:two))
    end
    assert_redirected_to book_url(books(:two))
  end

  test "すでに同じ本を借りているユーザーは別のコピーを借りられない" do
    sign_in_as users(:two) # books(:two) のコピーAを貸出中
    assert_no_difference("Rental.count") do
      post book_rentals_url(books(:two))
    end
    assert_redirected_to book_url(books(:two))
  end

  test "本人は自分の貸出を返却できる" do
    sign_in_as users(:two)
    rental = rentals(:one)
    patch rental_url(rental)
    assert_redirected_to book_url(rental.book)
    assert_not_nil rental.reload.returned_at
  end

  test "他人の貸出は返却できない" do
    sign_in_as users(:one)
    rental = rentals(:one)
    patch rental_url(rental)
    assert_response :not_found
    assert_nil rental.reload.returned_at
  end

  test "未ログインなら返却しようとするとログイン画面へリダイレクトされる" do
    rental = rentals(:one)
    patch rental_url(rental)
    assert_redirected_to new_session_url
    assert_nil rental.reload.returned_at
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
