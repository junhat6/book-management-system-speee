ENV["RAILS_ENV"] ||= "test"
require "simplecov"
SimpleCov.start
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"
Minitest::Reporters.use! # Minitest::Reporters::SpecReporter.new

require "webmock/minitest"
# テストから実ネットワークへのアクセスを禁止する（外部 API はスタブ必須にする）。
# localhost は Capybara/Selenium がブラウザと通信するために許可が必要
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # ローカルの .env に GOOGLE_BOOKS_API_KEY を設定していると（本番クォータ回避のため
    # 推奨されている運用）、dotenv-rails が development/test 両方でそれを読み込んでしまい、
    # key パラメータを想定していない既存のスタブが軒並み WebMock::NetConnectNotAllowedError
    # で落ちる。CIには .env が無いため気づけない環境依存のテスト脆弱性なので、
    # テスト中は常に未設定として扱い、環境に依存せず再現性を保つ
    setup { @original_google_books_api_key = ENV.delete("GOOGLE_BOOKS_API_KEY") }
    teardown { ENV["GOOGLE_BOOKS_API_KEY"] = @original_google_books_api_key }

    # Add more helper methods to be used by all tests here...
  end
end
