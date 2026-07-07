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

  # --- 発展要件5: UI/UX 改善（ページネーション・ソート・レスポンシブ） ---

  test "一覧は1ページ10冊でページ分割される" do
    # fixtures の2冊と合わせて13冊にする（2ページ目に3冊）
    11.times do |i|
      create_book_for_listing(title: "ページ分割確認#{format('%02d', i)}", isbn: "97800000003#{format('%02d', i)}")
    end

    get books_url
    assert_response :success
    assert_select "tbody tr", count: 10
    assert_select ".book-card", count: 10

    get books_url(page: 2)
    assert_response :success
    assert_select "tbody tr", count: 3
  end

  test "2ページ以上あるときページ移動リンクが表示される" do
    11.times do |i|
      create_book_for_listing(title: "ページ分割確認#{format('%02d', i)}", isbn: "97800000003#{format('%02d', i)}")
    end

    get books_url

    assert_select "nav.pagination" do
      assert_select "a[href*='page=2']"
    end
  end

  test "検索結果もページ分割され件数バッジは総数を示す" do
    12.times do |i|
      create_book_for_listing(title: "検索ページ確認#{format('%02d', i)}", isbn: "97800000004#{format('%02d', i)}")
    end

    get books_url(q: "検索ページ確認", page: 2)

    assert_response :success
    assert_select "tbody tr", count: 2
    assert_match "12 冊", response.body
  end

  test "範囲外のページ番号では未登録メッセージではなく案内を表示する" do
    get books_url(page: 999)

    assert_response :success
    assert_no_match "本はまだ登録されていません", response.body
    assert_match "このページには本がありません", response.body
  end

  test "一覧をタイトルで昇順・降順にソートできる" do
    first = create_book_for_listing(title: "AAA ソート確認", isbn: "9780000000501")
    last = create_book_for_listing(title: "zzz ソート確認", isbn: "9780000000502")

    get books_url(sort: "title", direction: "asc")
    assert_response :success
    assert_operator response.body.index(first.title), :<, response.body.index(last.title)

    get books_url(sort: "title", direction: "desc")
    assert_response :success
    assert_operator response.body.index(last.title), :<, response.body.index(first.title)
  end

  test "一覧を出版年でソートできる" do
    oldest = create_book_for_listing(title: "出版年ソート確認（古）", isbn: "9780000000503", published_year: 1900)
    newest = create_book_for_listing(title: "出版年ソート確認（新）", isbn: "9780000000504", published_year: 2100)

    get books_url(sort: "published_year", direction: "asc")
    assert_response :success
    assert_operator response.body.index(oldest.title), :<, response.body.index(newest.title)

    get books_url(sort: "published_year", direction: "desc")
    assert_response :success
    assert_operator response.body.index(newest.title), :<, response.body.index(oldest.title)
  end

  test "テーブルヘッダにソートリンクが表示される" do
    get books_url

    assert_select "th a[href*='sort=title']"
    assert_select "th a[href*='sort=published_year']"
  end

  test "ソートリンクは検索条件を引き継ぐ" do
    # 検索結果が0件だとテーブルごと描画されないため、ヒットする本を用意する
    create_book_for_listing(title: "ruby の本", isbn: "9780000000505")

    get books_url(q: "ruby")

    assert_select "th a[href*='sort=title'][href*='q=ruby']"
  end

  # --- 発展要件6: 外部 API 連携（ISBN から Google Books で書誌情報を自動取得） ---

  test "登録画面に ISBN 自動取得フォームが表示される" do
    sign_in_as users(:one)

    get new_book_url

    assert_select "form[action=?][method=?]", new_book_path, "get" do
      assert_select "input[name='lookup_isbn']"
    end
  end

  test "ISBN 検索がヒットすると登録フォームに書誌情報が反映される" do
    sign_in_as users(:one)
    stub_google_books_hit("9784873115658")

    get new_book_url(lookup_isbn: "978-4-87311-565-8")

    assert_response :success
    assert_select "input[name='book[isbn]'][value='9784873115658']"
    assert_select "input[name='book[title]'][value='リーダブルコード']"
    assert_select "input[name='book[publisher]'][value='オライリージャパン']"
    assert_select "input[name='book[published_year]'][value='2012']"
    assert_select "input[name='book[new_author_names]'][value='Dustin Boswell、Trevor Foucher']"
    assert_match "書籍情報を取得しました", response.body
  end

  test "ヒットしない ISBN は手入力を促すメッセージを表示し ISBN 入力値は保持される" do
    sign_in_as users(:one)
    stub_request(:get, "https://www.googleapis.com/books/v1/volumes")
      .with(query: { q: "isbn:9999999999999" })
      .to_return(status: 200, body: { totalItems: 0 }.to_json)

    get new_book_url(lookup_isbn: "9999999999999")

    assert_response :success
    assert_match "見つかりませんでした", response.body
    assert_select "input[name='book[isbn]'][value='9999999999999']"
    assert_select "input[name='book[title]']:not([value])"
  end

  test "API 障害時は失敗メッセージを表示して手入力にフォールバックできる" do
    sign_in_as users(:one)
    stub_request(:get, "https://www.googleapis.com/books/v1/volumes")
      .with(query: { q: "isbn:9784873115658" })
      .to_return(status: 500, body: "Internal Server Error")

    get new_book_url(lookup_isbn: "9784873115658")

    assert_response :success
    assert_match "取得に失敗しました", response.body
    assert_select "input[name='book[isbn]'][value='9784873115658']"
  end

  test "lookup_isbn なしの登録画面では API に問い合わせない" do
    sign_in_as users(:one)

    get new_book_url

    assert_not_requested :get, /googleapis/
  end

  private

  def stub_google_books_hit(isbn)
    stub_request(:get, "https://www.googleapis.com/books/v1/volumes")
      .with(query: { q: "isbn:#{isbn}" })
      .to_return(
        status: 200,
        body: {
          totalItems: 1,
          items: [
            {
              volumeInfo: {
                title: "リーダブルコード",
                authors: [ "Dustin Boswell", "Trevor Foucher" ],
                publisher: "オライリージャパン",
                publishedDate: "2012-06"
              }
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end

  def create_book_for_listing(title:, isbn:, published_year: 2000)
    Book.create!(title: title, isbn: isbn, published_year: published_year, publisher: "テスト社", author_ids: [ authors(:one).id ])
  end
end
