require "test_helper"

class BookItemsControllerTest < ActionDispatch::IntegrationTest
  test "未ログインなら在庫追加はログイン画面へリダイレクトされる" do
    assert_no_difference("BookItem.count") do
      post book_items_url(books(:one))
    end
    assert_redirected_to new_session_url
  end

  test "管理者は在庫を1冊追加できる" do
    sign_in_as users(:one)
    assert_difference("BookItem.count", 1) do
      post book_items_url(books(:one))
    end
    assert_redirected_to book_url(books(:one))
  end

  test "一般ユーザーは在庫を追加できない" do
    sign_in_as users(:two)
    assert_no_difference("BookItem.count") do
      post book_items_url(books(:one))
    end
    assert_redirected_to root_url
  end

  test "一般ユーザーは在庫を削除できない" do
    sign_in_as users(:two)
    assert_no_difference("BookItem.count") do
      delete book_item_url(books(:two), book_items(:two_item_b))
    end
    assert_redirected_to root_url
  end

  test "貸出履歴のない現物は削除できる" do
    sign_in_as users(:one)
    assert_difference("BookItem.count", -1) do
      delete book_item_url(books(:two), book_items(:two_item_b))
    end
    assert_redirected_to book_url(books(:two))
  end

  test "貸出履歴のある現物は削除できない" do
    sign_in_as users(:one)
    assert_no_difference("BookItem.count") do
      delete book_item_url(books(:two), book_items(:two_item_a))
    end
    assert_redirected_to book_url(books(:two))
  end

  test "未ログインなら在庫削除はログイン画面へリダイレクトされる" do
    assert_no_difference("BookItem.count") do
      delete book_item_url(books(:one), book_items(:one_item_a))
    end
    assert_redirected_to new_session_url
  end

  test "別の本の現物は削除できない" do
    sign_in_as users(:one)
    assert_no_difference("BookItem.count") do
      delete book_item_url(books(:one), book_items(:two_item_b))
    end
    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
