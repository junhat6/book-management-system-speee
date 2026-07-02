require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get books_url
    assert_response :success
  end

  test "should get show" do
    book = books(:one)
    get book_url(book)
    assert_response :success
  end

  test "should redirect to login when accessing new without authentication" do
    get new_book_url
    assert_redirected_to new_session_url
  end

  test "should get new" do
    sign_in_as users(:one)
    get new_book_url
    assert_response :success
  end

  test "should create book" do
    sign_in_as users(:one)
    assert_difference("Book.count") do
      post books_url, params: { book: { title: "New Book", isbn: "111111111111", published_year: 2020, publisher: "New Publisher", author_ids: [ authors(:one).id ] } }
    end
    assert_redirected_to book_url(Book.last)
  end

  test "should not create book with invalid data" do
    sign_in_as users(:one)
    assert_no_difference("Book.count") do
      post books_url, params: { book: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    sign_in_as users(:one)
    book = books(:one)
    get edit_book_url(book)
    assert_response :success
  end

  test "should update book" do
    sign_in_as users(:one)
    book = books(:one)
    patch book_url(book), params: { book: { title: "Updated Title", isbn: "222222222222", published_year: 2021, publisher: "Updated Publisher", author_ids: [ authors(:two).id ] } }
    assert_redirected_to book_url(book)
    book.reload
    assert_equal "Updated Title", book.title
    assert_equal "222222222222", book.isbn
    assert_equal 2021, book.published_year
    assert_equal "Updated Publisher", book.publisher
    assert_equal [ "太宰治" ], book.authors.map(&:name)
  end

  test "should not update book with invalid data" do
    sign_in_as users(:one)
    book = books(:one)
    patch book_url(book), params: { book: { title: "" } }
    assert_response :unprocessable_entity
    book.reload
    assert_not_equal "", book.title
  end

  test "should destroy book" do
    sign_in_as users(:one)
    book = books(:one)
    assert_difference("Book.count", -1) do
      delete book_url(book)
    end
    assert_redirected_to books_url
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
