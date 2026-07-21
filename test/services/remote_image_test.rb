require "test_helper"

class RemoteImageTest < ActiveSupport::TestCase
  ALLOWED_URL = "https://books.google.com/books/content?id=abc123&printsec=frontcover&img=1"

  def sample_jpeg
    file_fixture("cover_sample.jpg").read
  end

  test "許可されたホスト・httpsからの画像を取得できる" do
    stub_request(:get, ALLOWED_URL)
      .to_return(status: 200, body: sample_jpeg, headers: { "Content-Type" => "image/jpeg" })

    fetched = RemoteImage.fetch(ALLOWED_URL)

    assert_equal "image/jpeg", fetched.content_type
    assert_equal "cover.jpeg", fetched.filename
    assert_equal sample_jpeg, fetched.io.read
  end

  test "許可されていないホストは問い合わせずにエラーになる" do
    url = "https://evil.example.com/cover.jpg"

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(url) }
    assert_not_requested :get, url
  end

  test "httpスキームは問い合わせずにエラーになる" do
    url = "http://books.google.com/books/content?id=abc123"

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(url) }
    assert_not_requested :get, url
  end

  test "画像以外のContent-Type（SVG）はエラーになる" do
    stub_request(:get, ALLOWED_URL)
      .to_return(status: 200, body: "<svg onload=\"alert(1)\"></svg>", headers: { "Content-Type" => "image/svg+xml" })

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end

  test "画像以外のContent-Type（HTML）はエラーになる" do
    stub_request(:get, ALLOWED_URL)
      .to_return(status: 200, body: "<html></html>", headers: { "Content-Type" => "text/html" })

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end

  test "サイズ上限を超える画像はエラーになる" do
    oversized_body = "a" * (RemoteImage::MAX_BYTES + 1)
    stub_request(:get, ALLOWED_URL)
      .to_return(status: 200, body: oversized_body, headers: { "Content-Type" => "image/jpeg" })

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end

  test "サーバーエラーはエラーになる" do
    stub_request(:get, ALLOWED_URL).to_return(status: 500, body: "error")

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end

  test "存在しないURL（404）はエラーになる" do
    stub_request(:get, ALLOWED_URL).to_return(status: 404, body: "not found")

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end

  test "タイムアウトはエラーになる" do
    stub_request(:get, ALLOWED_URL).to_timeout

    assert_raises(RemoteImage::Error) { RemoteImage.fetch(ALLOWED_URL) }
  end
end
