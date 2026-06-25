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

  test "should get new" do
    get new_book_url
    assert_response :success
  end

  test "should create book" do
    assert_difference("Book.count") do
      post books_url, params: { book: { title: "New Book", isbn: "111111111111", published_year: 2020, publisher: "New Publisher" } }
    end

    assert_redirected_to book_url(Book.last)
  end
end
