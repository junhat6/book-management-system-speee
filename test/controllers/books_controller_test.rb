require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get books_url
    assert_response :success
  end

  test "should get index with q param" do
    matched = Book.create!(title: "こころ", isbn: "5555555555555", published_year: 1914, publisher: "岩波書店", author_ids: [ authors(:one).id ])
    unmatched = Book.create!(title: "人間失格", isbn: "6666666666666", published_year: 1948, publisher: "筑摩書房", author_ids: [ authors(:two).id ])

    get books_url(q: "こころ")

    assert_response :success
    assert_match matched.title, response.body
    assert_no_match(/#{Regexp.escape(unmatched.title)}/, response.body)
  end

  test "should show no results message when search has no matches" do
    get books_url(q: "存在しない検索語")

    assert_response :success
    assert_match "該当する本が見つかりませんでした", response.body
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

  # --- 発展要件1: ユーザー権限（書籍の登録・編集・削除は管理者のみ） ---

  test "一般ユーザーは書籍登録画面にアクセスできない" do
    sign_in_as users(:two)
    get new_book_url
    assert_redirected_to root_url
  end

  test "一般ユーザーは書籍を登録できない" do
    sign_in_as users(:two)
    assert_no_difference("Book.count") do
      post books_url, params: { book: { title: "New Book", isbn: "111111111111", published_year: 2020, publisher: "New Publisher", author_ids: [ authors(:one).id ] } }
    end
    assert_redirected_to root_url
  end

  test "一般ユーザーは書籍編集画面にアクセスできない" do
    sign_in_as users(:two)
    get edit_book_url(books(:one))
    assert_redirected_to root_url
  end

  test "一般ユーザーは書籍を更新できない" do
    sign_in_as users(:two)
    book = books(:one)
    patch book_url(book), params: { book: { title: "改ざんされたタイトル" } }
    assert_redirected_to root_url
    assert_not_equal "改ざんされたタイトル", book.reload.title
  end

  test "一般ユーザーは書籍を削除できない" do
    sign_in_as users(:two)
    assert_no_difference("Book.count") do
      delete book_url(books(:one))
    end
    assert_redirected_to root_url
  end

  test "管理者の一覧には登録・編集・削除ボタンが表示される" do
    sign_in_as users(:one)
    get books_url
    assert_select "a", text: "本を登録"
    assert_select "a", text: "編集"
    assert_select "button", text: "削除"
  end

  test "一般ユーザーの一覧には登録・編集・削除ボタンが表示されない" do
    sign_in_as users(:two)
    get books_url
    assert_select "a", text: "本を登録", count: 0
    assert_select "a", text: "編集", count: 0
    assert_select "button", text: "削除", count: 0
  end

  test "一般ユーザーの詳細画面には編集・削除ボタンが表示されない" do
    sign_in_as users(:two)
    get book_url(books(:one))
    assert_select "a", text: "編集", count: 0
    assert_select "button", text: "削除", count: 0
  end

  # --- 発展要件3: タグ・ジャンル管理（多対多） ---

  test "既存タグと新規タグを付けて書籍を登録できる" do
    sign_in_as users(:one)
    tag = Tag.create!(name: "技術書")

    post books_url, params: { book: { title: "New Book", isbn: "111111111111", published_year: 2020, publisher: "New Publisher", author_ids: [ authors(:one).id ], tag_ids: [ tag.id ], new_tag_names: "Ruby、入門" } }

    book = Book.find_by!(title: "New Book")
    assert_redirected_to book_url(book)
    assert_equal [ "Ruby", "入門", "技術書" ], book.tags.map(&:name).sort
  end

  test "更新でタグを付け替えられる" do
    sign_in_as users(:one)
    book = books(:one)
    old_tag = Tag.create!(name: "小説")
    new_tag = Tag.create!(name: "技術書")
    book.tags << old_tag

    patch book_url(book), params: { book: { tag_ids: [ new_tag.id ] } }

    assert_redirected_to book_url(book)
    assert_equal [ "技術書" ], book.reload.tags.map(&:name)
  end

  test "一覧をタグで絞り込みできる" do
    tag = Tag.create!(name: "技術書")
    tagged = Book.create!(title: "リーダブルコード", isbn: "7777777777777", published_year: 2012, publisher: "オライリー", author_ids: [ authors(:one).id ], tag_ids: [ tag.id ])
    other = Book.create!(title: "人間失格", isbn: "8888888888888", published_year: 1948, publisher: "筑摩書房", author_ids: [ authors(:two).id ])

    get books_url(tag_id: tag.id)

    assert_response :success
    assert_match tagged.title, response.body
    assert_no_match(/#{Regexp.escape(other.title)}/, response.body)
  end

  test "詳細画面にタグが表示される" do
    book = books(:one)
    book.tags << Tag.create!(name: "技術書")

    get book_url(book)

    assert_response :success
    assert_match "技術書", response.body
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
