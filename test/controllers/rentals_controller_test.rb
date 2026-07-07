require "test_helper"

class RentalsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインなら貸出履歴一覧はログイン画面へリダイレクトされる" do
    get rentals_url
    assert_redirected_to new_session_url
  end

  test "一般ユーザーは自分の貸出履歴のみ閲覧できる" do
    sign_in_as users(:two) # rentals(:one) の借主
    get rentals_url
    assert_response :success
    assert_match "rental_#{rentals(:one).id}", response.body
    assert_no_match(/rental_#{rentals(:two).id}"/, response.body)
  end

  test "管理者は全ユーザーの貸出履歴を閲覧できる" do
    sign_in_as users(:one) # 管理者。rentals(:two) の借主でもある
    get rentals_url
    assert_response :success
    assert_match "rental_#{rentals(:one).id}", response.body
    assert_match "rental_#{rentals(:two).id}", response.body
  end

  test "管理者向けの一覧には借主のユーザー名が表示される" do
    sign_in_as users(:one)
    get rentals_url
    assert_match users(:two).name, response.body
  end

  test "ステータスで絞り込める" do
    sign_in_as users(:one) # 管理者として全件を対象に確認する

    get rentals_url(status: "active")
    assert_match "rental_#{rentals(:one).id}", response.body
    assert_no_match(/rental_#{rentals(:two).id}"/, response.body)

    get rentals_url(status: "returned")
    assert_no_match(/rental_#{rentals(:one).id}"/, response.body)
    assert_match "rental_#{rentals(:two).id}", response.body
  end

  test "未ログインなら貸出処理はログイン画面へリダイレクトされる" do
    book = books(:one)
    assert_no_difference("Rental.count") do
      post book_rentals_url(book)
    end
    assert_redirected_to new_session_url
  end

  test "一般ユーザーでも借りられる" do
    sign_in_as users(:two)
    book = books(:one)
    assert_difference("Rental.count", 1) do
      post book_rentals_url(book)
    end
    assert_redirected_to book_url(book)
    assert_equal users(:two), book.reload.active_rental_for(users(:two)).user
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
