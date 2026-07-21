require "test_helper"

class GoogleBooksTest < ActiveSupport::TestCase
  API_URL = "https://www.googleapis.com/books/v1/volumes"

  def stub_google_books(isbn:, body:, status: 200)
    stub_request(:get, API_URL)
      .with(query: { q: "isbn:#{isbn}" })
      .to_return(status: status, body: body.is_a?(String) ? body : body.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  # 本番の匿名クォータ枯渇（HTTP 429）を避けるため API キーを付与する仕様のテスト用に ENV を一時的に切り替える
  def with_google_books_api_key(key)
    original = ENV["GOOGLE_BOOKS_API_KEY"]
    ENV["GOOGLE_BOOKS_API_KEY"] = key
    yield
  ensure
    ENV["GOOGLE_BOOKS_API_KEY"] = original
  end

  def full_response_body
    {
      totalItems: 1,
      items: [
        {
          volumeInfo: {
            title: "リーダブルコード",
            authors: [ "Dustin Boswell", "Trevor Foucher" ],
            publisher: "オライリージャパン",
            publishedDate: "2012-06",
            imageLinks: {
              smallThumbnail: "http://books.google.com/books/content?id=abc&img=1&zoom=5",
              thumbnail: "http://books.google.com/books/content?id=abc&img=1&zoom=1"
            }
          }
        }
      ]
    }
  end

  test "ISBN がヒットしたら書誌情報（タイトル・著者・出版社・出版年）を返す" do
    stub_google_books(isbn: "9784873115658", body: full_response_body)

    volume = GoogleBooks.lookup("9784873115658")

    assert_equal "リーダブルコード", volume.title
    assert_equal [ "Dustin Boswell", "Trevor Foucher" ], volume.authors
    assert_equal "オライリージャパン", volume.publisher
    assert_equal 2012, volume.published_year
  end

  test "imageLinks.thumbnail があれば https に強制した image_url を返す" do
    stub_google_books(isbn: "9784873115658", body: full_response_body)

    volume = GoogleBooks.lookup("9784873115658")

    assert_equal "https://books.google.com/books/content?id=abc&img=1&zoom=1", volume.image_url
  end

  test "thumbnail が無く smallThumbnail のみの場合はそちらを image_url として使う" do
    body = full_response_body
    body[:items][0][:volumeInfo][:imageLinks] = {
      smallThumbnail: "http://books.google.com/books/content?id=abc&img=1&zoom=5"
    }
    stub_google_books(isbn: "9784873115658", body: body)

    volume = GoogleBooks.lookup("9784873115658")

    assert_equal "https://books.google.com/books/content?id=abc&img=1&zoom=5", volume.image_url
  end

  test "imageLinks が無ければ image_url は nil" do
    body = full_response_body
    body[:items][0][:volumeInfo].delete(:imageLinks)
    stub_google_books(isbn: "9784873115658", body: body)

    assert_nil GoogleBooks.lookup("9784873115658").image_url
  end

  test "ハイフンや空白付きの ISBN は正規化して問い合わせる" do
    stub = stub_google_books(isbn: "9784873115658", body: full_response_body)

    volume = GoogleBooks.lookup(" 978-4-87311-565-8 ")

    assert_requested stub
    assert_equal "リーダブルコード", volume.title
  end

  test "publishedDate が年のみの形式でも出版年を取り出せる" do
    body = full_response_body
    body[:items][0][:volumeInfo][:publishedDate] = "1914"
    stub_google_books(isbn: "9784873115658", body: body)

    assert_equal 1914, GoogleBooks.lookup("9784873115658").published_year
  end

  test "任意項目（著者・出版社・出版日）が欠けていてもタイトルだけで取得できる" do
    body = { totalItems: 1, items: [ { volumeInfo: { title: "タイトルのみの本" } } ] }
    stub_google_books(isbn: "9784873115658", body: body)

    volume = GoogleBooks.lookup("9784873115658")

    assert_equal "タイトルのみの本", volume.title
    assert_equal [], volume.authors
    assert_nil volume.publisher
    assert_nil volume.published_year
    assert_nil volume.image_url
  end

  test "ヒットしない ISBN は nil を返す" do
    stub_google_books(isbn: "9999999999999", body: { totalItems: 0 })

    assert_nil GoogleBooks.lookup("9999999999999")
  end

  test "GOOGLE_BOOKS_API_KEY が設定されていればリクエストに key パラメータを付与する" do
    with_google_books_api_key("test-api-key") do
      stub = stub_request(:get, API_URL)
        .with(query: { q: "isbn:9784873115658", key: "test-api-key" })
        .to_return(status: 200, body: full_response_body.to_json, headers: { "Content-Type" => "application/json" })

      GoogleBooks.lookup("9784873115658")

      assert_requested stub
    end
  end

  test "GOOGLE_BOOKS_API_KEY が未設定なら key パラメータを付与しない" do
    with_google_books_api_key(nil) do
      stub = stub_google_books(isbn: "9784873115658", body: full_response_body)

      GoogleBooks.lookup("9784873115658")

      assert_requested stub
    end
  end

  test "空の ISBN は API に問い合わせず nil を返す" do
    assert_nil GoogleBooks.lookup("")
    assert_nil GoogleBooks.lookup(nil)
    assert_not_requested :get, /googleapis/
  end

  test "API がサーバーエラーを返したら GoogleBooks::Error を投げる" do
    stub_google_books(isbn: "9784873115658", body: "error", status: 500)

    assert_raises(GoogleBooks::Error) { GoogleBooks.lookup("9784873115658") }
  end

  test "接続がタイムアウトしたら GoogleBooks::Error を投げる" do
    stub_request(:get, API_URL).with(query: { q: "isbn:9784873115658" }).to_timeout

    assert_raises(GoogleBooks::Error) { GoogleBooks.lookup("9784873115658") }
  end

  test "応答が JSON として壊れていたら GoogleBooks::Error を投げる" do
    stub_google_books(isbn: "9784873115658", body: "<html>not json</html>")

    assert_raises(GoogleBooks::Error) { GoogleBooks.lookup("9784873115658") }
  end
end
